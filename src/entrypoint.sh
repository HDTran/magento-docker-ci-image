#!/bin/sh
service mysql start

/usr/sbin/apache2ctl -D FOREGROUND
