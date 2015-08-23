## Summary
php7dev is a Debian 8 [Vagrant image](https://atlas.hashicorp.com/rasmus/boxes/php7dev) which is preconfigured for testing PHP apps and developing extensions across many versions of PHP.

## Changes in 0.0.9
- Upgraded the base image OS from Debian 7.8 to 8.0 and recompiled all 20 PHP builds
- Added PosgreSQL support to all builds
- newphp will now switch the Apache module between PHP 5 and PHP 7 (default is still nginx)
- Added ack
- Updated virtualbox guest-additions

## Changes in 0.0.8
- Fix double-entry in /etc/network/interfaces

## Changes in 0.0.7
- Try to fix vagrant ssh issue by adding new insecure vagrant key

## Changes in 0.0.6
- Default PHP version is 7 again
- Use -j2 in makephp since the vm is configured for 2 CPUs
- Updated composer
- Put image version in /etc/motd

## Changes in 0.0.5
- dist-upgraded all Debian packages
- Updated newphp script - no longer need to sudo
- Added makephp script
- Added src/mysql checkout from pecl
- Rebuilt all PHP versions
- Added phpdbg to PHP 7.0 builds
- Updated Valgrind .suppressions file
- Re-installed headers as per https://github.com/rlerdorf/php7dev/issues/4
- Installed strace

## Installation

Download and install [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

Download and install [Vagrant](https://www.vagrantup.com/downloads.html)

Make sure you are at least at Vagrant version 1.5 or the steps below may not work for you.

If you are on Windows use the [Manual Install](#manual-install) instructions.

Otherwise for UNIX and UNIX-like users just clone and go. Like this: 

```
$ git clone https://github.com/rlerdorf/php7dev.git
...
$ cd php7dev
...
$ vagrant up
...
$ vagrant ssh
```

Add this to your hosts file:

```
192.168.7.7 php7dev
```

There are also various vagrant plugins that can help you update your dns. See [local-domain-resolution](https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Plugins#local-domain-resolution).  

At this point you should be able to point your  browser at:

```
http://php7dev/
```

and it should show the PHP7 phpinfo() page.

The box will also fetch an ip via DHCP so it will be on your local network like any other machine.
This also means you don't need to use **vagrant ssh** anymore. 

## Manual Install

You don't really need the helpers in the Github repo. I doubt they work well on Windows. You can get up and running using just Vagrant.

```
$ vagrant box add rasmus/php7dev
...
$ vagrant init rasmus/php7dev
...
$ vagrant up
...
$ vagrant ssh
```

If you have vagrant version < 1.5, you may run into "command was not invoked properly" error with `vagrant box add rasmus/php7dev`, then you can run it with the following explicit url:

```
$ vagrant box add "rasmus/php7dev" https://vagrantcloud.com/rasmus/boxes/php7dev/versions/0.0.7/providers/virtualbox.box
```

For DHCP add:

```
config.vm.network "public_network", type: "dhcp"
```

To your Vagrantfile. For a static IP, add:

```
config.vm.network "private_network", ip: "192.168.7.7"
```

Full docs on this is at [https://docs.vagrantup.com/v2/networking/private_network.html](https://docs.vagrantup.com/v2/networking/private_network.html).

## Updating your php7dev image

```
$ vagrant box outdated
Checking if box 'rasmus/php7dev' is up to date...
A newer version of the box 'rasmus/php7dev' is available! You currently
have version '0.0.3'. The latest is version '0.0.4'. Run
`vagrant box update` to update.

$ vagrant box update
...

$ vagrant box list
rasmus/php7dev (virtualbox, 0.0.3)
rasmus/php7dev (virtualbox, 0.0.4)
```

At this point you have two versions of the box. It won't automatically destroy your current one since you could have added some important data to it.
To use this new version, make sure anything you need from your current one is saved elsewhere and do:

```
$ vagrant destroy
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...

$ vagrant up
...
```
If virtualbox complains about an unsupported provider, make sure to have a working virtualbox and prefix the command with ``VAGRANT_DEFAULT_PROVIDER=virtualbox``:

```
$ VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
...
```

## Compiling the latest PHP 7

There is a script called *makephp* which does unattended builds.
To build and install the latest PHP 7.0 and PHP 7.0-debug just do:

```
$ makephp 7
```

Or you can build it manually like this:

```bash
$ cd php-src
$ git pull -r
$ make distclean
$ ./buildconf -f
$ ./cn
$ make
$ sudo make install
$ newphp 7 debug
```

Note the **./cn** script. The **--prefix** setting specifies where to install to. Make sure the path matches your debug/zts setting. You can change that script to build the non-debug version by changing **--enable-debug** to **--disable-debug** and removing **-debug** from the *--prefix**. In that case you would just do: **newphp 7**

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

## Adding Shared Folders

Add shared folders by adding them to the folders section in the php7dev.yaml configuration file.

## Toggle Public Network

By default the vagrant machine will use DHCP to be accessible over the local network. This can be disabled in the php7dev.yaml configuration file. 

## Add MySQL databases

Add the name of the database you want to be created in the databases section of the php7dev.yaml configuration file.

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
If you reload **http://php7dev/** you will see the PHP 5.5 info page, but much more importanly, if you run **phpize** in an extension directory it will now build the extension for PHP 5.5-debug-zts and install it in the correct place. You can quickly switch between versions like this and build your extension for 20 different combinations of PHP versions (this was requested by @auroraeosrose so if it is useful to you, she is partly to blame - if it isn't, blame me).

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

You will also find a .gdbinit symlink in *~vagrant* which provides a number of useful gdb macros. The symlink into php-src should ensure you have the right set for the current checked out version of the code.

## APT

And a tiny apt primer:
* update pkg list: **sudo apt-get update**
* search for stuff: **apt-cache search stuff**
* install stuff: **sudo apt-get install stuff**
* list installed: **dpkg -l**
* upgrade installed: **apt-get upgrade**

If something isn't working or you have suggestions, please let me know here.
