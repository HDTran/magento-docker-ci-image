#!/bin/sh
service mysql start
service apache2 start
echo "going into wait mode"
tail -f /dev/null
