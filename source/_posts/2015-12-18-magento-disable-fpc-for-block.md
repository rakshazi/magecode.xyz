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
            <name>block_name_in_layout_xmls</name> <!--eg: header -->
            <template>path/to/your/template/file.phtml</template> <!--eg: page/html/header.phtml -->
            <placeholder>any_random_generated_string_as_unique_id</placeholder> <!--eg: magecode_html_page_header -->
            <container>Module_Name_Model_Caching_Container_Blockname</container> <!--eg: Magecode_Html_Model_Caching_Container_Header -->
            <cache_lifetime>86400</cache_lifetime> <!-- lifetime in seconds, to disable cache just comment this line -->
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
        return 'MAGECODE_HTML_HEADER' . $this->_getIdentifier();
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
        'store_language',
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

        return $block->toHtml();
    }

    /**
     * Save data to cache storage
     *
     * @param string $data
     * @param string $id
     * @param array $tags
     * @param null|int $lifetime
     * @return bool
     */
    protected function _saveCache($data, $id, $tags = array(), $lifetime = null)
    {
        return false;
    }
}
~~~

> **Important**: don't forget to change `$childBlocks` array to your block childs or them will not be rendered!

After that your block will be rendered every time without caching it.

> Idea for this article was got from [Atwix article](http://www.atwix.com/magento/exclude-block-from-full-page-cache/),
but they wrote too many words and with bug in container model.
