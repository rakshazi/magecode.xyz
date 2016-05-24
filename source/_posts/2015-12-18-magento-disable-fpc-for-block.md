---
layout: post
title: "Disable Magento Full Page Cache for block"
categories:
    - fixed
tags:
    - EE
    - FPC
    - cache
    - config
use:
    - posts_categories
---
Magento Enterprise Edition Full Page Cache is a great feature that significantly improves the frontend performance.
Nevertheless, it is causing the troubles with the customisations that require the dynamic content output.
As you may know, the customer and cart information custom outputs are the first “victims” there, especially,
if you migrated your Magento store from Community to Enterprise Edition.
Some of the custom solutions, as well as the Mage Store modules, may not be ready for such migration.
This brief article will not only show how to avoid a separate block caching in FPC, but also uncover the way how it works.
<!-- break -->

#### Step 1. Create cache.xml in 'etc' directory of your extension

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <placeholders>
        <any_random_generated_string_as_unique_id> <!--eg: magecode_html_page_header -->
            <block>module_name/block_name</block><!--eg: html/page_header -->
            <placeholder>any_random_generated_string_as_unique_id</placeholder> <!--eg: magecode_html_page_header -->
            <container>Module_Name_Model_Caching_Container_Blockname</container> <!--eg: Magecode_Html_Model_Caching_Container_Header -->
            <cache_lifetime><s>null</s></cache_lifetime> <!-- lifetime in seconds, <s>null</s> means disable cache for this placeholder -->
        </any_random_generated_string_as_unique_id>
    </placeholders>
</config>
~~~

#### Step 2. Create caching container model for your block

~~~php
<?php

class Magecode_Html_Model_Caching_Container_Header extends Enterprise_PageCache_Model_Container_Abstract
{
    /**
     * Get container individual cache id
     *
     * @return string
     */
    protected function _getCacheId()
    {
        return 'MAGECODE_HEADER_' . md5($this->_placeholder->getAttribute('cache_id'));
    }

    /**
     * Get unique identifier for cache id
     *
     * @return mixed
     */
    protected function _getIdentifier()
    {
        return microtime();
    }

    /**
     * Array of child block for selected block
     * @var array
     */
    public $childBlocks = array(
        'top.links',
        'top.menu',
        'catalog.topnav',
        'top.container'
    );

    /**
     * Render block content
     *
     * @return string
     */
    protected function _renderBlock()
    {
        $block = $this->_getPlaceHolderBlock();
        foreach ($this->childBlocks as $child) {
            $block->setChild($child, Mage::app()->getLayout()->getBlock($child));
        }

        Mage::dispatchEvent('render_block', array('block' => $block, 'placeholder' => $this->_placeholder));

        return $block->toHtml();
    }
}
~~~

> **Important**: don't forget to change `$childBlocks` array to your block childs or them will not be rendered!

After that your block will be rendered every time without caching it.

> Idea for this article was got from [Atwix article](http://www.atwix.com/magento/exclude-block-from-full-page-cache/),
but they wrote too many words and with bug in container model.
