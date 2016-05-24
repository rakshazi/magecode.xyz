---
layout: post
title: "Webshopapps/Matrixrate free shipping based on price incl. tax"
categories:
    - extensions
tags:
    - snippet
use:
    - posts_categories
---

### What is it?
Magento module Webshopapps/Matrixrate allows you to give customer free shipping option if order totals will cost more than some money.

### Problem
This module calculates only products price without included tax.

Imagine:

You have a store. You have product with base (real) price $8, but with tax (eg: $3) it will cost $11. You set in store settings that on the frontend part for customers must be displayed only price with included tax ($11). And you set in Webshopapps/Matrixrate config that free shipping option must be shown for order amount > $100.

Customer buys 10 products by $11 each, but module will calculate only base (real) price - $8 for each product. In that way, customer will see order total amount as $110 but he will have no free shipping option.
<!-- break -->

## Solution
Open your store root dir and then go to the Webshopapps/Matrixrate dir (usually, `app/code/community/Webshopapps/Matrixrate`). Now open file `Model/Carrier/Matrixrate.php` and find function `collectRates` in it (_public function collectRates(Mage_Shipping_Model_Rate_Request $request)_).

Add following code before `//Free shipping by qty`:
```php
foreach ($request->getAllItems() as $item) {
	$request->setPackageValue($request->getPackageValue() + $item->getTaxAmount());
}
```

That's all!
