---
layout: post
title: "Change order status to 'Complete'"
categories:
    - orders
tags:
    - snippet
use:
    - posts_categories
---

You can easily change order status programmaticaly in Magento,
but you can't do it freely with "Complete" status
because you need create invoice and shipment for this.

Here is code snippet to change order status to "Complete".
<!-- break -->

Here is snippet for status changing:
```php
<?php
$orderId = "your order id";
//Set state
$order = Mage::getModel('sales/order')->load($orderId);
$order->setState(Mage_Sales_Model_Order::STATE_PROCESSING, true);
$order->save();
//Create invoice
$invoice = $order->prepareInvoice()
                 ->setTransactionId($order->getId())
                 ->addComment($comment)
                 ->register()
                 ->pay();

$transaction_save = Mage::getModel('core/resource_transaction')
                 ->addObject($invoice)
                 ->addObject($invoice->getOrder());
$transaction_save->save();
//Create shipment
$itemQty =  $order->getItemsCollection()->count();
$shipment = Mage::getModel('sales/service_order', $order)->prepareShipment($itemQty);
$shipment = new Mage_Sales_Model_Order_Shipment_Api();
$shipmentId = $shipment->create($orderId);
```

That's all.
