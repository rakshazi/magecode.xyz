---
layout: post
title: "Using local repositories to easily install private Magento extensions with Composer"
categories:
    - extensions
tags:
    - composer
author:
    name: "Barry vd. Heuvel"
    url: "https://medium.com/@barryvdh"
use:
    - posts_categories
---
There are a few ways to handle Magento extensions, for example:

* Magento Connect
* Copying files in the Magento directory
* Use Composer (with composer-installer)

I’m a fan of using Composer (in- and outside Magento), so I like to use that option.
This works great for free packages listed on Magento connect or [Firegento Packages](http://packages.firegento.com),
because you can just require the packages and run composer update. A few advantages over the other 2 options:

* Easier to update packages (run ‘composer update’)
* Keep your Magento dir clean
* Easy to install (‘composer remove’ and the files are really gone)
<!-- break -->

Magento Connect packages are listed in the connect20 namespace,
so your composer.json file could like something like this:

~~~json
{
    "require": {
        "magento-hackathon/magento-composer-installer": "3.0.*",
        "connect20/aschroder_smtppro": "~2.0.6",
        "yireo/yireo_newrelic": "~1.2.3"
    },
    "repositories": [
        {
            "type": "composer",
            "url": "http://packages.firegento.com"
        }
    ]
}
~~~

If you want te learn more about this,
checkout the [readme of the composer-installer project](https://github.com/Cotya/magento-composer-installer#further-information).
If you want to know about my specific setup, let me know and I might write a blogpost about it :)

## Private packages

This is all great for public packages, which are download through the Firegento repository.
But what about private packages? Ideally we could also use Composer for the packages we purchase.
But there are 2 common problems:

* They aren’t prepared for composer (or modman) usage.
* They aren’t listed on a public repository.

In this blog I’d like to explain how to tackle these 2 problems, so you can keep using the Composer workflow.

### Making the module installable by composer

There are 2 things required to make a module installable by the Composer installer:

* It needs a mapping between the source + destination files (either package.xml or modman file)
* It needs a composer.json file

A package.xml file is usually present for the Magento Connect packages and a modman is used for Github/Firegento modules.
Private packages usually lack both, so we’re going to create a modman file.
There are multiple ways to do this, but I favor a [Magerun](https://github.com/netz98/n98-magerun) command that I’ve written myself: https://github.com/fruitcakestudio/magerun-modman

After installing the Magerun Modman module,
you can type ‘n98-magerun.phar modman:generate’ to scan a directory and generate the modman output.
Just save the output to a file called ‘modman’ and you are done. See this [blog](http://ceckoslab.com/magento/magento-generate-modman-files/) for other methods.

Now we just need to create a composer.json file.
This is just like any other composer.json, except that the type is ‘magento-module’.
Just run `composer init — type=”magento-module”` and answer the interactive questions.

### Setting a repository for the module

Traditionally, there were 2 common options to create a repository:

* Use Satis to setup a private repository
* Link to a private Git repository

Both options work, but I found them to be a bit cumbersome.
You have to manage the access to those (satis and git) repositories, through passwords and/or public keys.
So each server (development, staging, production) would need to be added.
And on every change of server, multiple repos need changing.

Luckily, a week ago a new feature was added to Composer: Path repositories (so remember to run `composer self-update`).
This means that you can use a local path to define a repository.
Eg. we can just create an ’extensions’ directory, put our private extensions there and point our composer.json to it.
We can include these packages in our Git repository for our shop and they will be symlinked upon install.
You can use a wildcards for your folder, so ‘extensions/namespace/module’ could simply be ‘extensions/*/*’.

Example:

~~~json
{
    "require": {
        "magento-hackathon/magento-composer-installer": "3.0.*",
        "amasty/customer-attributes": "*@dev",
        "connect20/aschroder_smtppro": "~2.0.6",
        "yireo/yireo_newrelic": "~1.2.3"
    },
    "repositories": [
        {
            "type": "composer",
            "url": "http://packages.firegento.com"
        },
        {
            "type": "path",
            "url": "extensions/*/*"
        }
    ]
}
~~~

Note that we store the Amasty Customer Attributes directory in a path ‘extensions/amasty/customer-attributes’,
relative from our root composer.json file.
When creating the composer.json for this package (see above), we named it ‘amasty/customer-attributes’.
You can pick any name you want, as long as you remember to use the same one in both composer files..

> Note: Since this [PR](https://github.com/composer/composer/pull/4422) is merged,
> it’s possible to use wildcards in the path name possible, so the above example is updated to reflect this.

## A complete example

Let’s pick the Amasty module as a complete step-by-step example.

### My setup

You can configure your setup just how you like it, but mine is roughly something like this:

```
.git/            # Our git repo
extensions/      # Were we place our modules
extensions/<namespace>/<package>/composer.json # Example package
htdocs/          # The public root or 'magento folder'
vendor/          # The vendor dir for Composer
composer.json    # The composer.json file with our packages
composer.lock    # The exact versions of our packages
```
> The vendor dir is excluded from Git, but composer.lock included.
> So upon deployment, we run `composer install` to get exactly the same packages.

### The Private Package

As said, we’ll pick [Amasty Customer Attributes](https://amasty.com/customer-attributes.html) as example here,
but most private packages are similar.
Most have an installation guide, manual, license and a bunch of actual module files.
In this case, split up in ‘Step 1’ and ‘Step 2’ (No idea why)

![Files - before](/media/posts/2015-12-14-using-local-repositories-to-easily-install-private-magento-extensions-with-composer/files-before.jpeg)

We need the app/js/lib/skin files to be copied/symlinked in our magento folder, but we don’t need the pdf/txt files.
I usually like to make a ‘src’ dir for the actual module files and keep the rest in the root.
So we copy Step1 and Step2 to a new ‘src’ dir.

![Files - after](/media/posts/2015-12-14-using-local-repositories-to-easily-install-private-magento-extensions-with-composer/files-after.jpeg)

Now we need to create a modman files, to map all our src/* files to to correct path.
Using my [Modman Magerun](https://github.com/fruitcakestudio/magerun-modman) module,
run: `n98-magerun.phar modman:generate -d src > modman` in that directory.
That creates a file `modman`, something similar to below:

```
src/app/code/local/Amasty/Base                            app/code/local/Amasty/Base                           
src/app/code/local/Amasty/Customerattr                    app/code/local/Amasty/Customerattr                   
src/app/code/local/Mage/Customer/Block/Form/Register.php  app/code/local/Mage/Customer/Block/Form/Register.php
src/app/design/adminhtml/default/default/layout/amasty    app/design/adminhtml/default/default/layout/amasty   
src/app/design/adminhtml/default/default/template/amasty  app/design/adminhtml/default/default/template/amasty
src/app/design/frontend/base/default/layout/amasty        app/design/frontend/base/default/layout/amasty       
src/app/design/frontend/base/default/template/amasty      app/design/frontend/base/default/template/amasty     
src/app/etc/modules/Amasty_Base.xml                       app/etc/modules/Amasty_Base.xml                      
src/app/etc/modules/Amasty_Customerattr.xml               app/etc/modules/Amasty_Customerattr.xml              
src/app/locale/en_US/Amasty_Customerattr.csv              app/locale/en_US/Amasty_Customerattr.csv             
src/js/amasty/ambase                                      js/amasty/ambase                                     
src/lib/Varien/Data/Form/Element/Boolean.php              lib/Varien/Data/Form/Element/Boolean.php             
src/lib/Varien/Data/Form/Element/Multiselectimg.php       lib/Varien/Data/Form/Element/Multiselectimg.php      
src/lib/Varien/Data/Form/Element/Selectimg.php            lib/Varien/Data/Form/Element/Selectimg.php           
src/skin/adminhtml/default/default/css/amasty             skin/adminhtml/default/default/css/amasty            
src/skin/adminhtml/default/default/images/ambase          skin/adminhtml/default/default/images/ambase         
src/skin/frontend/base/default/images/fam_bullet_disk.gif skin/frontend/base/default/images/fam_bullet_disk.gif
```

> Note: I use a ‘src’ dir, hence the ‘-d src’ flag and the src/app/code/.. → app/code/.. mapping.
> You can just leave everything in the root if you want.
> 2 templates paths were left out the gist, because of the long length.

As you may have noticed, this module overwrites files in lib/Varien and app/code/local/Mage.
This isn’t very nice and you have to look out for this in your modman file!
Don’t symlink those folder to strict, you can edit the modman file manually if you need to.

**Magento Package Developers: Please save us the trouble and supply your modules with a package.xml or modman files. Thank you!**

Once we’re happy with the modman file, generate the composer.json by running `composer init` and answer the questions.
Make sure the type is magento-module.

![Running composer init](/media/posts/2015-12-14-using-local-repositories-to-easily-install-private-magento-extensions-with-composer/composer-init.jpeg)

Now we just save the module folder in `extensions/amasty/customer-attributes`,
add this path as local repository and require the `*@dev` version.
Run `composer update` and it will symlink the extension directory + install the module!

~~~json
{
    "require": {
        "magento-hackathon/magento-composer-installer": "3.0.*",
        "amasty/customer-attributes": "*@dev"
    },
    "repositories": [
        {
            "type": "path",
            "url": "extensions/*/*"
        }
    ]
}
~~~

That should about wrap this up!
Don’t forget to `composer self-update` before trying (on all your servers), otherwise it will fail.
Using this method has a few advantages:

* Keep your modules in sync with your Magento
* No extra private repositories to manage
* Faster than cloning many repos
* Keep your installation clean (1 dir with all module files)
* Easy to uninstall (no leftover files)

And to be fair, here are some downsides to consider:

* 3rd party code in your repository
* No central place to update your modules

## And Magento 2?

Just to take a quick look ahead to the Magento 2 ecosystem: it would seem that most of this isn’t needed for Magento2,
because Magento will use Composer by default and provide their own repository for both paid and free modules.
However, it is possible that not everyone will be using this (perhaps because of the pricing?), so this method could still apply..
