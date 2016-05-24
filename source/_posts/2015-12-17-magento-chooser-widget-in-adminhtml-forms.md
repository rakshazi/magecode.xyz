---
layout: post
title: "Magento chooser widget in adminhtml forms"
categories:
    - extensions
tags:
    - adminhtml
    - widget
    - form
author:
    name: "Tsvetan Stoychev"
    url: "http://ceckoslab.com/"
use:
    - posts_categories
---
![Product chooser](/media/posts/2015-12-17-magento-chooser-widget-in-adminhtml-forms/chooser.png)

Magento extension that gives the ability to create Product, Category, CMS Page and Static Block choosers in generic admin forms.
<!-- break -->

There are 4 important things you need to do to make the chooser work:

It's required to add in the layout update a handle called `editor`.
This handle includes the JS logic that is needed to render the chooser popups

```xml
<?xml version="1.0"?>
<layout>

    <adminhtml_my_module_item_edit>
        <reference name="content">
            <block type="my_module/adminhtml_item_edit" name="item_edit" />
        </reference>
        <update handle="editor"/>
    </adminhtml_my_module_item_edit>

</layout>
```

After that in method `_prepareForm()` of your admin form you need to have an instance of helper
`jarlssen_chooser_widget/chooser` and pass some parameters to the function creating the chooser.

Use any of the chooser create functions of `Jarlssen_ChooserWidget_Helper_Chooser`:

 * createProductChooser
 * createCategoryChooser
 * createCmsPageChooser
 * createCmsBlockChooser
 * createChooser

There is a required config value called `input_name` and must be passed to the chooser through a configuration array.

The function creating the chooser accepts the following parameters:

 * **$model** - instance of `Mage_Core_Model_Abstract` - the current entity
 * **$fieldset** - instance of `Varien_Data_Form_Element_Fieldset` - It’s required, because we create the chooser in this fieldset
 * **$config** - array of the widget configuration, the element `input_name` is required, because this is the name of the field name, that we save after form submit.
 * **$blockAlias** - this parameter is used only when we invoke `Jarlssen_ChooserWidget_Helper_Chooser::createChooser()` and it’s useful for creating our own custom chooser

The array $config also can contain more elements, but they are not mandatory:

 * **'input_label'** - The text of the input label
 * **'button_text'** - The text of the chooser button
 * **'required'** - If it’s true, then we will have frontend validation and to pass it we need to choose something from the chooser
 * **'input_id'** - If you don't specify this parameter the input id will be same as the input name. Thanks to [bmcg](https://github.com/bmcg) for his pull request. He found, that useful when he want's to have input name, that contains square brackets.

Example of config array:

~~~php
$productConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('Product'),
    'button_text' => $this->__('Select Product...'),
    'required'    => true,
    'input_id'    => 'my_custom_id'
);
~~~

#### Code Examples

Product Chooser:

~~~php
$chooserHelper = Mage::helper('jarlssen_chooser_widget/chooser');

$productConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('Product'),
    'button_text' => $this->__('Select Product...'),
    'required'    => true
);

$chooserHelper->createProductChooser($model, $fieldset, $productConfig);
~~~

Category Chooser:

~~~php
$chooserHelper = Mage::helper('jarlssen_chooser_widget/chooser');

$categoryConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('Category'),
    'button_text' => $this->__('Select Category...'),
    'required'    => true
);

$chooserHelper->createCategoryChooser($model, $fieldset, $categoryConfig);
~~~

Static Block Chooser:

~~~php
$chooserHelper = Mage::helper('jarlssen_chooser_widget/chooser');

$blockConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('Block'),
    'button_text' => $this->__('Select Block...'),
    'required'    => true
);

$chooserHelper->createCmsBlockChooser($model, $fieldset, $blockConfig);
~~~

CMS Page Chooser:

~~~php
$chooserHelper = Mage::helper('jarlssen_chooser_widget/chooser');

$cmsPageConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('CMS Page'),
    'button_text' => $this->__('Select CMS Page…'),
    'required'    => true
);

$chooserHelper->createCmsPageChooser($model, $fieldset, $cmsPageConfig);
~~~

Custom Chooser:

~~~php
$chooserHelper = Mage::helper('jarlssen_chooser_widget/chooser');

$customChooserConfig = array(
    'input_name'  => 'entity_link',
    'input_label' => $this->__('Custom entity'),
    'button_text' => $this->__('Select entity…'),
    'required'    => true
);

$chooserBlock = 'custom_module/chooser';

$chooserHelper->createChooser($model, $fieldset, $customChooserConfig, $chooserBlock);
~~~

**Data representation**

| Chooser      | Format                                                           | Example                          |
|--------------|------------------------------------------------------------------|----------------------------------|
| Product      | product/{product_id}/{category_id} / *{category_id} is optional* | product/14509 / product/14509/32 |
| Category     | category/{category_id}                                           | category/22                      |
| CMS Page     | {cms_page_id}                                                    | 7                                |
| Static Block | {static_block_id}                                                | 3                                |
| Custom       | N/A                                                              | N/A                              |

<a href="https://github.com/SessionDE/Jarlssen_ChooserWidget" class="btn btn-info btn-block">Extension on GitHub</a>
