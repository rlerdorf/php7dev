## Summary
php7dev is a Debian 7.8 [Vagrant image](https://atlas.hashicorp.com/rasmus/boxes/php7dev) which is preconfigured for testing PHP apps and developing extensions across many versions of PHP.

## Installation

Download and install [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

Download and install [Vagrant](https://www.vagrantup.com/downloads.html)

Make sure you are at least at Vagrant version 1.5 or the steps below may not work for you.

Then from a terminal, do:

```
$ vagrant box add rasmus/php7dev
...
$ vagrant init rasmus/php7dev
...
$ vagrant up
...
$ vagrant ssh
```

If everything went well you should now be ssh'ed into your php7dev environment.

However, if you check **/sbin/ifconfig** you will see that your network interface is a private NAT'ed ip. You can get out from it, but you can't get in. Log back out and edit your *~/Vagrantfile*.
Most of it is commented out. Add these two lines:

```
config.vm.hostname = "php7dev"
config.vm.network "public_network", type: "dhcp"
```

There are also various vagrant plugins that can help you update your dns. See [local-domain-resolution](https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Plugins#local-domain-resolution).  

The [landrush](https://github.com/phinze/landrush) one looks interesting since it could be used to create a local **php7dev** domain and you could then just make all your vhosts **myvhost.php7dev** and you wouldn't need to edit your */etc/hosts* file every time you added a new vhost.

```
$ vagrant reload
```

It will ask you which interface to bridge to. Select your current active network interface and it should just work. If you have configured one of the domain resolution plugins you should be set to go now, otherwise, **vagrant ssh** in and check the ip manually (**ip addr show**) and add it to your */etc/hosts* file on the machine you are running your browser on. Then try it: 

```
http://php7dev/
```

It should show the PHP7 phpinfo() page.

This also means you don't need to use **vagrant ssh** anymore. You can just ssh directly into the machine like any other machine on your network at this point.

## Installing phpBB

Now you can install something. The sites live in */var/www*.

For example, to install phpBB:

```
$ cd /var/www
$ wget https://www.phpbb.com/files/release/phpBB-3.1.2.zip
...
$ unzip phpBB-3.1.2.zip
...
$ sudo chown -R www-data phpBB3
```

Create */etc/nginx/conf.d/phpbb.conf* with this config:

```nginx
server {
    listen 80;
    server_name  phpbb;
    root   /var/www/phpBB3;
    index  index.php index.html index.htm;
    access_log /var/log/nginx/phpbb-access.log;
    error_log /var/log/nginx/phpbb-error.log;

    location ~ /(config\.php|common\.php|cache|files|images/avatars/upload|includes|store) {
        deny all;
        return 403;
    }

    location ~* \.(gif|jpe?g|png|css)$ {
        expires   30d;
    }

    include php.conf;
}
```
You will need to sudo to do it. It shouldn't ask you for a password, but every password, sudo, root, mysql is set to: **vagrant** in case you need it.

Then do:

```
$ sudo service nginx reload
```

On the machine where you are running your web browser, add an entry to your */etc/hosts* file with:

```
192.168.x.x phpbb
```

Substitute your ip there, of course.

Now you can go to **http://phpbb/** and you should be redirected to the phpBB installer.

Before you start, you need to create the database:

```
$ mysqladmin create phpbb
```

Now go through the steps. Your Database host is **localhost** and the user is **vagrant**, password **vagrant**. Database name is **phpbb**. You can leave the port empty. Click through the rest and you should be done. Then remove the install directory to get rid of the annoying warning:

```
$ sudo rm -rf /var/www/phpBB3/install/
```

## Installing other apps

For the most part installing almost anything follows the same pattern. Download the tarball or zip file to */var/www*. Extract, make it owned by **www-data** and find the nginx server config. Usually a quick Google search will turn it up. If it doesn't, something like:

```nginx
    server {
       listen 80;
       server_name mysite;
       root /var/www/mysite;
       access_log /var/log/nginx/mysite-access.log;
       error_log /var/log/nginx/mysite-error.log;

       index index.php index.html;

       location / {
           try_files $uri $uri/ @rewrite;
        }
        location @rewrite {
            rewrite ^(.*)$ /index.php;
        }

        include php.conf;
    }
```

Usually does the trick. You will also find [composer](https://getcomposer.org/) already installed in */usr/local/bin*.

## Switching PHP versions

New in version 0.0.3 of the image is the ability to switch the entire PHP environment quickly. Every version of PHP since 5.3 is precompiled and installed in /usr/local/php*. There are actually 4 builds for each version. debug, zts, debug-zts and the standard non-debug, non-zts. To switch versions do:

```
$ newphp 55 debug zts
Activating PHP 5.5.22-dev and restarting php-fpm
```
If you reload ** http://php7dev/ ** you will see the PHP 5.5 info page, but much more importanly, if you run **phpize** in an extension directory it will now build the extension for PHP 5.5-debug-zts and install it in the correct place. You can quickly switch between versions like this and build your extension for 20 different combinations of PHP versions (this was requested by @auroraeosrose so if it is useful to you, she is partly to blame).

For quick testing there are symlinks in */usr/local/bin* to the various versions, so you can quickly check **php56 -a** without activating it. Similarly, you can do:

```
$ service php-fpm stop
$ service php56-fpm start
```

## Debugging Tools

For debugging, you have many options. Valgrind is installed and the suppressions file is up to date. I have included a helper script I use called *memcheck*. Try it:

```valgrind
$ memcheck php -v
==3788== Memcheck, a memory error detector
==3788== Copyright (C) 2002-2011, and GNU GPL'd, by Julian Seward et al.
==3788== Using Valgrind-3.7.0 and LibVEX; rerun with -h for copyright info
==3788== Command: php -v
==3788==
PHP 7.0.0-dev (cli) (built: Jan 28 2015 15:53:12) (DEBUG)
Copyright (c) 1997-2015 The PHP Group
Zend Engine v3.0.0-dev, Copyright (c) 1998-2015 Zend Technologies
    with Zend OPcache v7.0.4-dev, Copyright (c) 1999-2015, by Zend Technologies
==3788==
==3788== HEAP SUMMARY:
==3788==     in use at exit: 19,112 bytes in 17 blocks
==3788==   total heap usage: 29,459 allocs, 29,442 frees, 3,033,303 bytes allocated
==3788==
==3788== LEAK SUMMARY:
==3788==    definitely lost: 0 bytes in 0 blocks
==3788==    indirectly lost: 0 bytes in 0 blocks
==3788==      possibly lost: 0 bytes in 0 blocks
==3788==    still reachable: 0 bytes in 0 blocks
==3788==         suppressed: 19,112 bytes in 17 blocks
==3788==
==3788== For counts of detected and suppressed errors, rerun with: -v
==3788== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 28 from 6)
```

Also, sometimes it is easier to track down issues with a single standalone process instead of using php-fpm. You can do this like this:

```
$ sudo service php-fpm stop
$ sudo php-cgi -b /var/run/php-fpm.sock
```

The debug build will report memory leaks and you can of course run it
under gdb or valgrind as well. See the */usr/local/bin/memcheck* script
for how to run Valgrind.

To update php7 to the latest, do this:

```bash
$ cd php-src
$ git pull -r
$ make distclean
$ ./buildconf -f
$ ./cn
$ make
$ sudo make install
$ sudo service php-fpm restart
```

It should be quite fast because ccache is installed and the cache should be relatively recent. Note the **./cn** script. The **--prefix** setting specified where to install to. Make sure the path matches your debug/zts setting.

You will also find a .gdbinit symlink in *~vagrant* which provides a number of useful gdb macros. The symlink into php-src should ensure you have the right set for the current checked out version of the code.

## APT

And a tiny apt primer:
* update pkg list: **sudo apt-get update**
* search for stuff: **apt-cache search stuff**
* install stuff: **sudo apt-get install stuff**
* list installed: **dpkg -l**
* upgrade installed: **apt-get upgrade**

If something isn't working or you have suggestions, please let me know here.
