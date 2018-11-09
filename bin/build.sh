#!/bin/sh

. ./bin/build_env 

if [ ! -f auth.json ] || [ ! -f  id_rsa ]; then
    echo "ERROR. Cant build without credentials. Copy composer auth.json and id_rsa to root folder. These will not be stored in the image"
    exit 1
fi

docker build  \
    --build-arg MAGENTO_URL=$MAGENTO_URL\
    --build-arg MAGENTO_ADMIN_EMAIL=$MAGENTO_ADMIN_EMAIL \
    --build-arg MAGENTO_ADMIN_USERNAME=$MAGENTO_ADMIN_USERNAME \
    --build-arg MAGENTO_ADMIN_PASSWORD=$MAGENTO_ADMIN_PASSWORD  \
    --build-arg MAGENTO_NODEUSER_FIRSTNAME=$MAGENTO_NODEUSER_FIRSTNAME \
    --build-arg MAGENTO_NODEUSER_LASTNAME=$MAGENTO_NODEUSER_LASTNAME \
    --build-arg MAGENTO_NODEUSER_EMAIL=$MAGENTO_NODEUSER_EMAIL \
    --build-arg MAGENTO_NODEUSER_USERNAME=$MAGENTO_NODEUSER_USERNAME \
    --build-arg MAGENTO_NODEUSER_PASSWORD=$MAGENTO_NODEUSER_PASSWORD \
    --no-cache -t deity-magento2-ci .

 echo "WARNING : you should remove auth.json and id_rsa for security reasons"
 
 
