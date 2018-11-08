#!/bin/sh
docker run -p 80:80 -p 3306:3306  -it  --name="deity-magento2-ci" deity-magento2-ci
