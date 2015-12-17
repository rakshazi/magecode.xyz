---
layout: post
title: "Compatibility extension for Magento 1 and PHP 7"
categories:
    - extensions
tags:
    - php7
author:
    name: "Ivan Curdinjakovic"
    url: "http://inchoo.net/author/ivan-curdinjakovic/profile/"
---
As promised,  we prepared something that will spice up your holidays better than Christmas decorations and mulled wine.
In this article you can find **our open-source compatibility extension for Magento and PHP 7** (yes, you read that right!)
as well as some of the experiences and performance tests.

We, at Inchoo, already have a few Magento 1 projects running fine on development servers with PHP 7. _It’s alive_, we say!

#### And quite lively, actually.

Despite the official status, Magento 1 loves working on a server with PHP 7. And we love PHP 7.
<!-- break -->

## Show us the code!

So, how hard is it to patch Magento 1 to work on PHP 7? Very easy. Just install the Inchoo_PHP7 extension, and enjoy!

 > <i class="fa fa-github"></i> [Inchoo/Inchoo_PHP7](https://github.com/Inchoo/Inchoo_PHP7)

"_Yeah, you’ve patched the core, but the night is long and community and local folders are full of horrors!_", you say,
with a sneer of someone who has seen many winters. Yes, sure, but here is something more for your pains:

~~~
->\$.+\[.+\]\(.*\)
~~~

This beautiful, readable piece of regex, ran against community and local folders will find a class of problematic code,
which no longer works in PHP 7. If none found, your project is (probably) PHP 7 ready! Hooray!

## Obligatory number crunching

Values in all tables are milliseconds to first byte.
Cache, when turned on, was default core M CE cache.
All other items in software stack (MySQL, Apache) were same.

#### Big (>70 extensions, thousands of products) M CE 1.9.1.0 project, with all patches applied

| cached  | category, filtered | home page |
|---------|--------------------|-----------|
| PHP 5.6 | 800                | 320       |
| PHP 7.0 | 420                | 120       |


| uncached | category, filtered | home page |
|----------|--------------------|-----------|
| PHP 5.6  | 6200               | 7300      |
| PHP 7.0  | 3450               | 3400      |

#### Small (~10 extensions, tens of products) M CE 1.9.2.2 project

| cached  | category, filtered | checkout/cart |
|---------|--------------------|---------------|
| PHP 5.6 | 165                | 180           |
| PHP 7.0 | 80                 | 105           |

| uncached | category, filtered | checkout/cart |
|----------|--------------------|---------------|
| PHP 5.6  | 310                | 360           |
| PHP 7.0  | 100                | 200           |



Thanks to Marin Grizelj for crunching the numbers, which speak for themselves.
Speedup was 2-3 times just from switching to PHP 7.
And, we were comparing it with PHP 5.6, while many projects in the wild are still on 5.5 or even 5.4.
(Mind you, compatibility fixes you need to do on older Magento 1 versions to make it work with 5.6,
will also bring you a good deal closer to compatibility with 7.0).

Enough technobabble. It is alive and lively! Let it run into the wild, and scare the village folk!
