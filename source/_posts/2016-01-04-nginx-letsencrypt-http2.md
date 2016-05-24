---
layout: post
title: "Web server with Nginx, Letsencrypt SSL, and HTTP/2"
categories:
    - enviroment
tags:
    - linux
    - nginx
    - ssl
    - http2
use:
    - posts_categories
---

HTTP/2 and Let's Encrypt free SSL certificates are ready for production now.

Here I want to describe you, how to use Nginx with Let's Encrypt certificate (with A+ rank on SSLLabs) and HTTP/2 on Ubuntu 14.04.xx

<!--break-->

> All actions in console must be under **root** user (call _sudo su_ before start)

## Nginx

You need to add nginx deb repositories, because in ubuntu repos nginx is outdated (no HTTP/2 support):

~~~bash
touch /etc/apt/sources.list.d/nginx.list
echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list.d/nginx.list
wget -q -O- http://nginx.org/keys/nginx_signing.key | apt-key add -
apt-get -qq update
apt-get install nginx
~~~

> If you already have nginx installed, remove it, because new version (1.99 for now) will conflict with nginx-common package.

Ok, you have latest stable nginx with HTTP/2 suppport, but you need to enable it.

Open your site config (default is `/etc/nginx/sites-enabled/default`) and replace `listen` lines with following ( **before any other config** ):

> Change **YOURDOMAIN** in `servername`, `ssl_certificate` and `ssl_certificate_key` to your site address, eg: magecode.xyz\

> SSL will be configured later.

~~~
#upstream php-handler {
#  server unix:/var/run/php5-fpm.sock;
#}

#server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2; # This line needed only if you use IPv6
    servername YOURDOMAIN; # Change it to your domain name
    ssl_certificate /etc/letsencrypt/live/YOURDOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/YOURDOMAIN/privkey.pem;
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    ssl_dhparam /etc/nginx/ssl/dhparams.pem;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    # Add headers to serve security related headers
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;

    # ...

#}
~~~

Here is my "base" config for any project:

~~~
upstream php-handler {
  server unix:/var/run/php5-fpm.sock;
}

server {
  listen 80;
  server_name YOURDOMAIN;
  # enforce https
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name YOURDOMAIN;

  ssl_certificate /etc/letsencrypt/live/YOURDOMAIN/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/YOURDOMAIN/privkey.pem;
  ssl_stapling on;
  ssl_stapling_verify on;
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+A
ESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256
-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA2
56:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
  ssl_dhparam /etc/nginx/ssl/dhparams.pem;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;

  # Add headers to serve security related headers
  add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
  add_header X-Content-Type-Options nosniff;
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  add_header X-Robots-Tag none;

  # Path to the root of your installation
  root /var/www/YOURDOMAIN/;
  # set max upload size
  client_max_body_size 10G;
  fastcgi_buffers 64 4K;

  # Disable gzip to avoid the removal of the ETag header
  gzip off;

  # Uncomment if your server is build with the ngx_pagespeed module
  # This module is currently not supported.
  #pagespeed off;

  index index.php;

  location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
  }

  location ~ ^/(build|tests)/ {
    deny all;
  }

  location ~ ^/(?:\.|autotest|console) {
    deny all;
  }

  location / {
    try_files $uri $uri/ /index.php;
  }

  location ~ \.php(?:$|/) {
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param HTTPS on;
    fastcgi_param modHeadersAvailable true; #Avoid sending the security headers twice
    fastcgi_pass php-handler;
    fastcgi_intercept_errors on;
  }

  # Adding the cache control header for js and css files
  # Make sure it is BELOW the location ~ \.php(?:$|/) { block
  location ~* \.(?:css|js)$ {
    add_header Cache-Control "public, max-age=7200";
    # Add headers to serve security related headers
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    # Optional: Don't log access to assets
    access_log off;
  }

  # Optional: Don't log access to other assets
  location ~* \.(?:jpg|jpeg|gif|bmp|ico|png|swf)$ {
    access_log off;
  }
}

~~~

Add this line to the end of `http` section of `/etc/nginx/nginx.conf` (new nginx version removed this line from `nginx.conf`):

~~~
include /etc/nginx/sites-enabled/*;
~~~

And create `/etc/nginx/ssl/dhparams.pem` (needed to enable Forward Secrecy):

~~~bash
mkdir /etc/nginx/ssl
openssl dhparam -out /etc/pki/nginx/dhparams.pem 4096
~~~

> Test your nginx configuration with `nginx -t` command before next steps

Congratulation! Nginx now can handle requests via HTTP/2

## Let's Encrypt free SSL certificate

You need to install special client to get Let's Encrypt SSL certificate:

~~~bash
git clone https://github.com/letsencrypt/letsencrypt
cd letsencrypt
./letsencrypt-auto --server https://acme-v01.api.letsencrypt.org/directory -v --help
~~~

If all ok, now you can generate ssl ceritificate for your domain (you must stop any webserver on 80 and 443 port):

> Follow the prompts and change **YOURDOMAIN** to your site address, eg: magecode.xyz

~~~bash
service nginx stop
./letsencrypt-auto certonly -a standalone -d YOURDOMAIN -d www.YOURDOMAIN --server https://acme-v01.api.letsencrypt.org/directory --agree-dev-preview -v
~~~

If all ok, you will have SSL certificate for your domain (www. domain will be added as alias).
All cert files placed in `/etc/letsencrypt/live/YOURDOMAIN/` dir, you can do `ls` on it to see them.

Now you can start your nginx server:

~~~bash
service nginx start
~~~

Congratulation! Now your site will work on HTTP/2 protocol with Let's Encrypt SSL certificate and **A+** rank on SSLLabs.

> If you not yet tested your site, go to [SSL Labs](https://www.ssllabs.com/ssltest/analyze.html) and test it.

I hope, this article will help to build fast and protected web.
