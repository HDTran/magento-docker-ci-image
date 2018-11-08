#!/bin/sh

if [ ! -f auth.json ] && [ ! -f  id_rsa ]; then
    echo "ERROR. Cant build without credentials. Copy composer auth.json and id_rsa to root folder"
    exit 1
fi

docker build -t deity-magento2-ci .
