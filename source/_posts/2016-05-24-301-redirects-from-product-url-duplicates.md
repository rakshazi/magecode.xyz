---
layout: post
title: "301 redirect from product url duplicates"
categories:
    - fixed
tags:
    - SEO
    - Catalog
    - URL
use:
    - posts_categories
---

Magento allow you to create multiple urls for one product page, for example:

```
http://example.com/product.html
http://example.com/category1/product.html
http://example.com/great-sale-2016/product.html
```

Some SEO specialists say that it's very bad for SEO, thats why you need create 301 redirect from all product urls, except main url (`http://example.com/product.html`).

Here you can find solution in 5 strings of code which will redirect customers from any additional product url to main url.

<!-- break -->
> Don’t change the core files! But, because of simplicity I’ll show you the solution by modifying core files.

Open file `app/code/core/Mage/Catalog/controllers/ProductController.php` and replace `viewAction()` with the following content:

```php
public function viewAction()
{
    // Get initial data from request
    $categoryId = (int) $this->getRequest()->getParam('category', false);
    $productId  = (int) $this->getRequest()->getParam('id');
    $specifyOptions = $this->getRequest()->getParam('options');

    /////////////////////////////////////// START WITH 301 REDIRECT
    $product = Mage::getModel('catalog/product')->load($productId);
    $currentURL = Mage::helper('core/url')->getCurrentUrl(); //Because Mage::getUrl() will return base product url
    if($currentURL != $product->getProductUrl() . '?' . http_build_query($this->getRequest()->getParams())) { //eg: http://example.com/category1/product.html != http://example.com/product.html
        $this->getResponse()->setRedirect($product->getProductUrl() . '?' . http_build_query($this->getRequest()->getParams()), 301)->sendResponse(); //Redirect to http://example.com/product.html
    }
    /////////////////////////////////////// END WITH 301 REDIRECT

    // Prepare helper and params
    $viewHelper = Mage::helper('catalog/product_view');

    $params = new Varien_Object();
    $params->setCategoryId($categoryId);
    $params->setSpecifyOptions($specifyOptions);

    // Render page
    try {
        $viewHelper->prepareAndRender($productId, $this, $params);
    } catch (Exception $e) {
        if ($e->getCode() == $viewHelper->ERR_NO_PRODUCT_LOADED) {
            if (isset($_GET['store'])  && !$this->getResponse()->isRedirect()) {
                $this->_redirect('');
            } elseif (!$this->getResponse()->isRedirect()) {
                $this->_forward('noRoute');
            }
        } else {
            Mage::logException($e);
            $this->_forward('noRoute');
        }
    }
}
```

That's all. Hope, this will help you.

> Idea for this article was got from [Inchoo](http://inchoo.net/magento/301vscanonicals/),
but they wrote about another case.
