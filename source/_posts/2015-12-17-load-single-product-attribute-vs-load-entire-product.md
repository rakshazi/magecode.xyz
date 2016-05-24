---
layout: post
title: "Load single product attribute vs. load entire product"
categories:
    - perfomance
tags:
    - EAV
    - attributes
    - collections
    - database
    - ORM
author:
    name: "Tsvetan Stoychev"
    url: "http://ceckoslab.com/"
use:
    - posts_categories
---

Let’s assume that as developer you are in following situation:
You know a product id and you have to fetch single attribute value of a product which id you already know.
For example let’s try to get color attribute of Magento product.

**Question**: How would you do it?
Are you going to load the product or you would look for more efficient solutions in order to fetch only the attribute you are looking for?

Magento allows us to fetch product attribute in many ways and depending on the context we could choose one.
I am definitely against loading entire product in case there are much more efficient solutions and the goal is to fetch single product attribute
(not all product attributes).



I think that people choose the easy way because:

* People read the first answer (which sometimes is not the most efficient) in StackOverflow but don’t check other answers.
* There is a lack of Magento documentation.
* Missing out of the box way how to accomplish the task.
* There are many examples in Internet but they are not descriptive enough to explain what happens on background and how efficient they are.

As first example,
I would like to start with one of the efficient ways because I know many people would copy / paste this solution in their project,
stop reading and continue with their daily work.
<!-- break -->

#### Load single product attribute

Me and my colleague Attila Fabrik work on a legacy project and we noticed
that in many places a product is loaded because a single attribute should be displayed.
We registered this as serious problem because for example this code was used in block that was displayed on all pages.
Each page refresh was leading to many product loads.
This was serious red flag because we had high traffic Magento shop and every millisecond mattered.

We developed helper function that was wrapping all needed abstraction in order to fetch single product attribute value:

~~~php
/**
 * @param int $productId
 * @param string $attributeCode
 * @param int|null $storeId
 * @return mixed
 */
public function fetchProductAttributeBy_ProductId_AttributeCode_StoreId($productId, $attributeCode, $storeId = null) {
    if (null === $storeId) {
        $storeId = Mage::app()->getStore()->getId();
    }

    $attribute = Mage::getModel('catalog/product')->getResource()->getAttribute($attributeCode);

    $attributeValue = Mage::getModel('catalog/product')
        ->getResource()
        ->getAttributeRawValue($productId, $attributeCode, $storeId);

    if ($attribute->usesSource()) {
        $attributeValue = $attribute->getSource()->getOptionText($attributeValue);
    }

    return $attributeValue;
}
~~~

The Store Id is optional parameter because we usually want to fetch product attribute from current store.

I gave this long function name (fetchProductAttributeBy_ProductId_AttributeCode_StoreId) just to make it more descriptive.
Feel free to give more suitable name in your projects.
In some cases I would prefer to wrap this function in more meaningful named function
because I would like to make my code more readable for teammates and fronted developers.



Generated SQL queries during fetching single attribute value:

~~~sql
SQL: SELECT `eav_entity_type`.* FROM `eav_entity_type` WHERE (`eav_entity_type`.`entity_type_code`='catalog_product')
AFF: 1
TIME: 0.0003

SQL: SELECT `eav_attribute`.* FROM `eav_attribute` WHERE (`eav_attribute`.`attribute_code`='color') AND (entity_type_id = :entity_type_id)
BIND: array (
  ':entity_type_id' => '4',
)
AFF: 1
TIME: 0.0003

SQL: SELECT `eav_entity_type`.`additional_attribute_table` FROM `eav_entity_type` WHERE (entity_type_id = :entity_type_id)
BIND: array (
  ':entity_type_id' => '4',
)
AFF: 1
TIME: 0.0003

SQL: SELECT `catalog_eav_attribute`.* FROM `catalog_eav_attribute` WHERE (attribute_id = :attribute_id)
BIND: array (
  ':attribute_id' => '92',
)
AFF: 1
TIME: 0.0002

SQL: SELECT `default_value`.`attribute_id`, IF(store_value.value IS NULL, default_value.value, store_value.value) AS `attr_value` FROM `catalog_product_entity_int` AS `default_value`
 LEFT JOIN `catalog_product_entity_int` AS `store_value` ON store_value.attribute_id IN (92) AND store_value.entity_type_id = :entity_type_id AND store_value.entity_id = :entity_id AND store_value.store_id = :store_id WHERE (default_value.attribute_id IN (92)) AND (default_value.entity_type_id = :entity_type_id) AND (default_value.entity_id = :entity_id) AND (default_value.store_id = 0)
BIND: array (
  ':entity_type_id' => 4,
  ':entity_id' => 880,
  ':store_id' => 1,
)
AFF: 1
TIME: 0.0005

SQL: SELECT `main_table`.*, `tdv`.`value` AS `default_value`, `tsv`.`value` AS `store_default_value`, IF(tsv.value_id > 0, tsv.value, tdv.value) AS `value` FROM `eav_attribute_option` AS `main_table`
 INNER JOIN `eav_attribute_option_value` AS `tdv` ON tdv.option_id = main_table.option_id
 LEFT JOIN `eav_attribute_option_value` AS `tsv` ON tsv.option_id = main_table.option_id AND tsv.store_id = '1' WHERE (attribute_id = '92') AND (tdv.store_id = 0) ORDER BY main_table.sort_order ASC, value ASC
AFF: 19
TIME: 0.0003
~~~

#### Entire Product load

Basically it looks strange to load entire product because you need a product attribute but many people do it.

This is what loading entire product will cause to your system:

* a lot of not needed data could be loaded (other attributes, stock data, media gallery, prices and etc.)
* increased execution time
* more memory used compared to fetching single attribute approach
* complex SQL query with couple of JOINs
* not clean code (what was the exact purpose of loading the product if you pass it in a .phtml file and you just echo single attribute)
* many events (after load, bore load) fired but may not need them when you need just a single attribute

If you are fine for what is listed above then you could try the following code snippet:

~~~php
$_product = Mage::getModel('catalog/product')->load($id);
echo $_product->getAttributeText('color');
~~~



Generated SQL queries during product load:

~~~sql
SQL: SELECT `eav_entity_type`.* FROM `eav_entity_type` WHERE (`eav_entity_type`.`entity_type_code`='catalog_product')
AFF: 1
TIME: 0.0003

SQL: SELECT `catalog_product_entity`.* FROM `catalog_product_entity` WHERE (entity_id =880)
AFF: 1
TIME: 0.0003

SQL: DESCRIBE `eav_attribute`
AFF: 17
TIME: 0.0008

SQL: SELECT `main_table`.`entity_type_id`, `main_table`.`attribute_code`, `main_table`.`attribute_model`, `main_table`.`backend_model`, `main_table`.`backend_type`, `main_table`.`backend_table`, `main_table`.`frontend_model`, `main_table`.`frontend_input`, `main_table`.`frontend_label`, `main_table`.`frontend_class`, `main_table`.`source_model`, `main_table`.`is_required`, `main_table`.`is_user_defined`, `main_table`.`default_value`, `main_table`.`is_unique`, `main_table`.`note`, `additional_table`.*, `entity_attribute`.*, IFNULL(al.value, main_table.frontend_label) AS `store_label` FROM `eav_attribute` AS `main_table`
 INNER JOIN `catalog_eav_attribute` AS `additional_table` ON additional_table.attribute_id = main_table.attribute_id
 INNER JOIN `eav_entity_attribute` AS `entity_attribute` ON entity_attribute.attribute_id = main_table.attribute_id
 LEFT JOIN `eav_attribute_label` AS `al` ON al.attribute_id = main_table.attribute_id AND al.store_id = 1 WHERE (main_table.entity_type_id = 4) AND (entity_attribute.attribute_set_id = '13') ORDER BY sort_order ASC
AFF: 79
TIME: 0.0004

SQL: SELECT `attr_table`.* FROM `catalog_product_entity_varchar` AS `attr_table`
 INNER JOIN `eav_entity_attribute` AS `set_table` ON attr_table.attribute_id = set_table.attribute_id AND set_table.attribute_set_id = '13' WHERE (attr_table.entity_id = '880') AND (attr_table.store_id IN (0, 1)) UNION ALL SELECT `attr_table`.* FROM `catalog_product_entity_int` AS `attr_table`
 INNER JOIN `eav_entity_attribute` AS `set_table` ON attr_table.attribute_id = set_table.attribute_id AND set_table.attribute_set_id = '13' WHERE (attr_table.entity_id = '880') AND (attr_table.store_id IN (0, 1)) UNION ALL SELECT `attr_table`.* FROM `catalog_product_entity_text` AS `attr_table`
 INNER JOIN `eav_entity_attribute` AS `set_table` ON attr_table.attribute_id = set_table.attribute_id AND set_table.attribute_set_id = '13' WHERE (attr_table.entity_id = '880') AND (attr_table.store_id IN (0, 1)) UNION ALL SELECT `attr_table`.* FROM `catalog_product_entity_datetime` AS `attr_table`
 INNER JOIN `eav_entity_attribute` AS `set_table` ON attr_table.attribute_id = set_table.attribute_id AND set_table.attribute_set_id = '13' WHERE (attr_table.entity_id = '880') AND (attr_table.store_id IN (0, 1)) UNION ALL SELECT `attr_table`.* FROM `catalog_product_entity_decimal` AS `attr_table`
 INNER JOIN `eav_entity_attribute` AS `set_table` ON attr_table.attribute_id = set_table.attribute_id AND set_table.attribute_set_id = '13' WHERE (attr_table.entity_id = '880') AND (attr_table.store_id IN (0, 1)) ORDER BY `store_id` ASC
AFF: 50
TIME: 0.0007

SQL: SELECT `eav_attribute`.* FROM `eav_attribute` WHERE (`eav_attribute`.`attribute_id`='121')
AFF: 0
TIME: 0.0003

SQL: SELECT `eav_entity_type`.`additional_attribute_table` FROM `eav_entity_type` WHERE (entity_type_id = :entity_type_id)
BIND: array (
  ':entity_type_id' => NULL,
)
AFF: 0
TIME: 0.0003

SQL: SELECT `main`.`value_id`, `main`.`value` AS `file`, `main`.`entity_id` AS `product_id`, `value`.`label`, `value`.`position`, `value`.`disabled`, `default_value`.`label` AS `label_default`, `default_value`.`position` AS `position_default`, `default_value`.`disabled` AS `disabled_default` FROM `catalog_product_entity_media_gallery` AS `main`
 LEFT JOIN `catalog_product_entity_media_gallery_value` AS `value` ON main.value_id = value.value_id AND value.store_id = 1
 LEFT JOIN `catalog_product_entity_media_gallery_value` AS `default_value` ON main.value_id = default_value.value_id AND default_value.store_id = 0 WHERE (main.attribute_id = '88') AND (main.entity_id in ('880')) ORDER BY IF(value.position IS NULL, default_value.position, value.position) ASC
AFF: 1
TIME: 0.0005

SQL: SELECT `catalog_product_entity_group_price`.`value_id` AS `price_id`, `catalog_product_entity_group_price`.`website_id`, `catalog_product_entity_group_price`.`all_groups`, `catalog_product_entity_group_price`.`customer_group_id` AS `cust_group`, `catalog_product_entity_group_price`.`value` AS `price` FROM `catalog_product_entity_group_price` WHERE (entity_id='880') AND (website_id = 0)
AFF: 0
TIME: 0.0003

SQL: SELECT `catalog_product_entity_tier_price`.`value_id` AS `price_id`, `catalog_product_entity_tier_price`.`website_id`, `catalog_product_entity_tier_price`.`all_groups`, `catalog_product_entity_tier_price`.`customer_group_id` AS `cust_group`, `catalog_product_entity_tier_price`.`value` AS `price`, `catalog_product_entity_tier_price`.`qty` AS `price_qty` FROM `catalog_product_entity_tier_price` WHERE (entity_id='880') AND (website_id = 0) ORDER BY `qty` ASC
AFF: 0
TIME: 0.0003

SQL: SELECT `cataloginventory_stock_item`.*, `p`.`type_id` FROM `cataloginventory_stock_item`
 INNER JOIN `catalog_product_entity` AS `p` ON product_id=p.entity_id WHERE (`cataloginventory_stock_item`.`product_id`='880') AND (stock_id = :stock_id)
BIND: array (
  ':stock_id' => 1,
)
AFF: 1
TIME: 0.0003

SQL: SELECT `cataloginventory_stock_status`.`product_id`, `cataloginventory_stock_status`.`stock_status` FROM `cataloginventory_stock_status` WHERE (product_id IN('880')) AND (stock_id=1) AND (website_id=1)
AFF: 1
TIME: 0.0002

SQL: SELECT `main_table`.*, `tdv`.`value` AS `default_value`, `tsv`.`value` AS `store_default_value`, IF(tsv.value_id > 0, tsv.value, tdv.value) AS `value` FROM `eav_attribute_option` AS `main_table`
 INNER JOIN `eav_attribute_option_value` AS `tdv` ON tdv.option_id = main_table.option_id
 LEFT JOIN `eav_attribute_option_value` AS `tsv` ON tsv.option_id = main_table.option_id AND tsv.store_id = '1' WHERE (attribute_id = '92') AND (tdv.store_id = 0) ORDER BY main_table.sort_order ASC, value ASC
AFF: 19
TIME: 0.0003
~~~

#### "Benchmark"

I wanted to see some numbers because I wanted check what is the difference between both methods described above.
I didn’t use big numbers because for me was enough to see the difference when I tested with 10 products.
For the tests I used Vagrant box with Magento CE 1.9.1.0 and sample product data.

| Test type                                     | Memory usage | Time in computations | Time in system calls |
|-----------------------------------------------|--------------|----------------------|----------------------|
| Fetch single attribute (color) of 10 products | 2.49 MB      | 42 ms                | 71 ms                |
| Load 10 products and getting color            | 9.01 MB      | 154 ms               | 342 ms               |

#### Conclusion

I think that developers should be aware what are implications of their code and if they know better way then do tasks in better way.
Of course everything is relative and it depends what is developer’s expertise in order to get nice and well performing code and successful project.
The best thing that could happen is developers to get interested in Magento good practices and be aware that performance and simplicity matter in long term.
