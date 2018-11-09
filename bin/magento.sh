#!/usr/bin/env bash
set -a
docker  exec -u www-data deity-magento2-ci /var/www/html/bin/magento $@
