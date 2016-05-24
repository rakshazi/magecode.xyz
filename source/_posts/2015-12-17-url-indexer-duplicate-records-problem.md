---
layout: post
title: "An error occurred while saving the URL rewrite"
categories:
    - fixed
tags:
    - database
    - index
    - url rewrite
author:
    name: "Tsvetan Stoychev"
    url: "http://ceckoslab.com/"
use:
    - posts_categories
---
Last few weeks I was fighting with problem that partially broke Magento url indexer.
Basically the url indexer was working but at certain point it was breaking.
At this point I was getting exception and not all url rewrites were written to core_url_rewrite table.
Everyday the problem was getting bigger and bigger because all new products contained “catalog/product/view/id”
(I call those urls – “ugly” urls) but the desired urls suppose to be human readable and end with “.html”.

This issue could be reproduced only on live environment and in order to reproduce it locally
I had to copy all catalog tables (`catalog_*`) and `core_url_rewrite` table from live to local environment.

When I run Magento url indexer from command line I got:

~~~
php shell/indexer.php --reindex catalog_url
An error occurred while saving the URL rewrite
~~~

In Magento exception log I had:

~~~
exception 'PDOException' with message 'SQLSTATE[23000]:
Integrity constraint violation: 1062 Duplicate entry 'product/2469/361-1-1'
for key 'UNQ_CORE_URL_REWRITE_ID_PATH_IS_SYSTEM_STORE_ID''
~~~
<!-- break -->

#### Debugging

This error message wasn’t enough in order to identify what is the real problem.
For me was clear that there was Integrity constraint violation.
I could sense that there is data inconsistency but I didn’t know for how many records in `core_url_rewrite` I would have this problem.
After couple of minutes studying how this indexer works I found good place from where I could get better error information
(I had to temporary hack the core because I don’t use debugger).
My idea was temporary to cover the exception and log data for all inserts that would fail for unique index `UNQ_CORE_URL_REWRITE_ID_PATH_IS_SYSTEM_STORE_ID`.

This index is Multiple-Column Index for 3 columns:

* core_url_rewrite.id_path
* core_url_rewrite.is_system
* core_url_rewrite.store_id

This is example exception that:

> integrity constraint violation: 1062 Duplicate entry 'product/2469/361-1-1' for key 'UNQ_CORE_URL_REWRITE_ID_PATH_IS_SYSTEM_STORE_ID''

This meant that we tried to insert data that was already duplicated and record in `core_url_rewrite` already existed with following data:

* core_url_rewrite.id_path = product/2469/361
* core_url_rewrite.is_system = 1
* core_url_rewrite.store_id = 1

The best place for debugging was `Mage_Catalog_Model_Resource_Url::saveRewrite()`

This is the original method definition in Magento CE 1.9.2.2:

~~~php
/**
 * Save rewrite URL
 *
 * @param array $rewriteData
 * @param int|Varien_Object $rewrite
 * @return Mage_Catalog_Model_Resource_Url
 */
public function saveRewrite($rewriteData, $rewrite)
{
    $adapter = $this->_getWriteAdapter();
    try {
        $adapter->insertOnDuplicate($this->getMainTable(), $rewriteData);
    } catch (Exception $e) {
        Mage::logException($e);
        Mage::throwException(Mage::helper('catalog')->__('An error occurred while saving the URL rewrite'));
    }
    if ($rewrite && $rewrite->getId()) {
        if ($rewriteData['request_path'] != $rewrite->getRequestPath()) {
            // Update existing rewrites history and avoid chain redirects
            $where = array('target_path = ?' => $rewrite->getRequestPath());
            if ($rewrite->getStoreId()) {
                $where['store_id = ?'] = (int)$rewrite->getStoreId();
            }
            $adapter->update(
                $this->getMainTable(),
                array('target_path' => $rewriteData['request_path']),
                $where
            );
        }
    }
    unset($rewriteData);
    return $this;
}
~~~

My idea was to comment the line where an exception was thrown and log which inserts would have `integrity constraint violation`.

Modified function looked like:

~~~php
/**
 * Save rewrite URL
 *
 * @param array $rewriteData
 * @param int|Varien_Object $rewrite
 * @return Mage_Catalog_Model_Resource_Url
 */
public function saveRewrite($rewriteData, $rewrite)
{
    $adapter = $this->_getWriteAdapter();
    try {
        $adapter->insertOnDuplicate($this->getMainTable(), $rewriteData);
    } catch (Exception $e) {
        Mage::logException($e);
        Mage::log($rewriteData);
        //Mage::throwException(Mage::helper('catalog')->__('An error occurred while saving the URL rewrite'));
    }

    if ($rewrite && $rewrite->getId()) {
        if ($rewriteData['request_path'] != $rewrite->getRequestPath()) {
            // Update existing rewrites history and avoid chain redirects
            $where = array('target_path = ?' => $rewrite->getRequestPath());
            if ($rewrite->getStoreId()) {
                $where['store_id = ?'] = (int)$rewrite->getStoreId();
            }
            $adapter->update(
                $this->getMainTable(),
                array('target_path' => $rewriteData['request_path']),
                $where
            );
        }
    }
    unset($rewriteData);

    return $this;
}
~~~

Final result in log file was:

~~~
DEBUG (7): Array
(
    [store_id] => 1
    [category_id] => 361
    [product_id] => 1868
    [id_path] => product/1868/361
    [request_path] => huhu/muhu.html
    [target_path] => catalog/product/view/id/1868/category/361
    [is_system] => 1
)

DEBUG (7): Array
(
    [store_id] => 1
    [category_id] => 361
    [product_id] => 2469
    [id_path] => product/2469/361
    [request_path] => fifi/mifi.html
    [target_path] => catalog/product/view/id/2469/category/361
    [is_system] => 1
)
~~~

This information was enough to identify for which records I had problem.
The easiest solution for me was to delete those records from `core_url_rewrite` table and reindex again.



**N.B.**

In my case I got lucky because I had problem only for 2 records.
If I had problem for hundreds / thousands records I would spend more time in order to study how this exactly happened and
what product data I have in this Magento setup.


Your thoughts?
