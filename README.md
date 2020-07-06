# HiveWeb
The new Hive internal Web

## Needed Debian/Ubuntu Packages
* libbytes-random-secure-perl
* libcatalyst-action-renderview-perl
* libcatalyst-authentication-store-dbix-class-perl
* libcatalyst-plugin-authorization-acl-perl
* libcatalyst-plugin-configloader-perl
* libcatalyst-plugin-static-simple-perl
* libcatalyst-plugin-session-state-cookie-perl
* libcatalyst-plugin-session-store-dbic-perl
* libcatalyst-view-json-perl
* libcatalyst-view-tt-perl
* libdbix-class-uuidcolumns-perl
* libdbix-class-inflatecolumn-serializer-perl
* libdbix-class-deploymenthandler-perl
* libdbix-class-helpers-perl
* libcrypt-eksblowfish-perl
* libdatetime-format-dbi-perl
* libdatetime-format-iso8601-perl
* libdbd-pg-perl
* libjson-perl
* libmath-round-perl
* libtext-markdown-perl
* libpdf-api2-perl
* libimage-magick-perl
* libconvert-base32-perl
* libimager-qrcode-perl
* libauthen-oath-perl
* libemail-address-xs-perl
* cssmin
* node-less

### Note to installer
When installing this package, don't forget to initialize the Git submodules and go into the `less` folder and run make.

You need to put the following entries in a system-wide crontab:
```
*   * * * * root /path/to/HiveWeb/bin/queue_runner.pl -d -e >/dev/null 2>&1
*   * * * * root /path/to/HiveWeb/bin/paypal_refresh.pl -d -e >/dev/null 2>&1
0   3 * * * root /path/to/HiveWeb/bin/delete_orphaned_images.pl >/dev/null 2>&1
0   3 * * * root /path/to/HiveWeb/bin/expire_memberships.pl -r >/dev/null 2>&1
```

For pest performance, run with mod_perl on Apache 2 **with the prefork MPM enabled, not worker or event**. Inside your VirtualHost directive,
you need the following lines:

```
SetEnv DB_USER access
SetEnv DB_PASS access

DocumentRoot /path/to/HiveWeb/root

PerlSwitches -I/path/to/HiveWeb/lib
PerlModule HiveWeb

<Location />
    SetHandler              modperl
    PerlResponseHandler     HiveWeb
</Location>
<Location /static>
    SetHandler None
</Location>
<Directory /path/to/HiveWeb/root>
    Options FollowSymLinks
</Directory>
```

...along with your normal stuff like logging and (ideally) TLS certs from Let's Encrypt.