FROM alexcheng/apache2-php7:latest

ENV INSTALL_DIR /var/www/html
ENV COMPOSER_HOME /var/www/.composer/

RUN curl -sS https://getcomposer.org/installer | php \
&& mv composer.phar /usr/local/bin/composer \
&& mkdir /var/www/.ssh \
&& touch /var/www/.ssh/config \
&& echo "StrictHostKeyChecking no " >> /var/www/.ssh/config \
&& echo "StrictHostKeyChecking no " >> /root/.ssh/config 

RUN requirements="libpng12-dev libmcrypt-dev libmcrypt4 libcurl3-dev libfreetype6 libjpeg-turbo8 libjpeg-turbo8-dev libpng12-dev libfreetype6-dev libicu-dev libxslt1-dev git" \
    && apt-get update \
    && apt-get install -y $requirements \
    && apt-get install -y sudo \
    && apt-get install -y mysql-client \
    && apt-get install -y unzip \
    && apt-get install -y ssmtp \
    && apt-get install -y mailutils \
    && apt-get install -y mariadb-server \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-install intl \
    && docker-php-ext-install xsl \
    && docker-php-ext-install soap \
    && docker-php-ext-install bcmath \
    && a2enmod rewrite \
    && echo "memory_limit=2048M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && requirementsToRemove="libpng12-dev libmcrypt-dev libcurl3-dev libpng12-dev libfreetype6-dev libjpeg-turbo8-dev" \
    && apt-get purge --auto-remove -y $requirementsToRemove \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PECL install but not enable xdebug
# Symlink xdebug.so so that it is at a known path
#RUN pecl install xdebug \
#    && PHP_EXT_PATH=$(php -r 'echo ini_get("extension_dir");') \
#    && ln -s "${PHP_EXT_PATH}/xdebug.so" /opt/xdebug.so
#COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/

#RUN chsh -s /bin/bash www-data \
#&& chown -R www-data:www-data /var/www \

WORKDIR $INSTALL_DIR

# Add cron job
ADD crontab /etc/cron.d/magento2-cron
RUN chmod 0644 /etc/cron.d/magento2-cron \
    && crontab -u www-data /etc/cron.d/magento2-cron
    
USER www-data
    
COPY ./install-magento /usr/local/bin/install-magento
COPY ./add-node-user.sh /usr/local/bin/add-node-user.sh
COPY ./create_user.sql /usr/local/create_user.sql
COPY ./auth.json $COMPOSER_HOME
COPY --chown=www-data:www-data  ./id_rsa /var/www/.ssh/id_rsa

RUN sudo chmod 600 /var/www/.ssh/id_rsa \
&& sudo chmod +x /usr/local/bin/install-magento \
&& sudo chmod +x /usr/local/bin//add-node-user.sh \
&& sudo chown -R www-data:www-data $COMPOSER_HOME  \
&& composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html \
&&  find /var/www/html/ -type f -exec chmod 666 {} \; \
&& find /var/www/html/ -type d -exec chmod 777 {} \;  \
&& chmod ugo+x /var/www/html/bin/magento

ARG MYSQL_HOST=127.0.0.1
ARG MYSQL_ROOT_PASSWORD=deity_magento2
ARG MYSQL_USER=magento2
ARG MYSQL_PASSWORD=magento2pass
ARG MYSQL_DATABASE=magento

ARG MAGENTO_VERSION_BRANCH_NAME=2.2

ARG MAGENTO_LANGUAGE=en_US
ARG MAGENTO_TIMEZONE=Europe/Amsterdam
ARG MAGENTO_DEFAULT_CURRENCY=USD

ARG MAGENTO_URL=http://127.0.0.1

ARG MAGENTO_BACKEND_FRONTNAME=admin
ARG MAGENTO_USE_SECURE=0
ARG MAGENTO_BASE_URL_SECURE=0
ARG MAGENTO_USE_SECURE_ADMIN=0

ARG MAGENTO_ADMIN_FIRSTNAME=Admin
ARG MAGENTO_ADMIN_LASTNAME=MyStore
ARG MAGENTO_ADMIN_EMAIL=admin@deity.local
ARG MAGENTO_ADMIN_USERNAME=admin
ARG MAGENTO_ADMIN_PASSWORD=m@g3nt0

ARG MAGENTO_NODEUSER_FIRSTNAME=node
ARG MAGENTO_NODEUSER_LASTNAME=api
ARG MAGENTO_NODEUSER_EMAIL=node@deity.local
ARG MAGENTO_NODEUSER_USERNAME=node-api
ARG MAGENTO_NODEUSER_PASSWORD=3de3f3a262

## Need to start required services for each run command 
RUN sudo service mysql start \
&& sudo mysqladmin -u root password "${MYSQL_ROOT_PASSWORD}"  \
&& sudo mysql -u root < /usr/local/create_user.sql  \
&&  /usr/local/bin/install-magento 

## Adding cache entry after magento install 
## Here we can rebuild our custom config 
RUN sudo service mysql start \
&& /usr/local/bin/add-node-user.sh \
&& cp $COMPOSER_HOME/auth.json  /var/www/html/var/composer_home/auth.json \
&& echo "Adding custom repo " \
&& composer config repositories.deity-api '{"type": "vcs", "url": "git@github.com:deity-io/falcon-magento2-module.git"}' \
&& composer require --no-update deity/falcon-magento:dev-master \ 
&& /var/www/html/bin/magento sampledata:deploy  \
&& /var/www/html/bin/magento setup:upgrade 

## Not needed. running everything as www-data 
## && echo "OWNING   /var/www/html/" \
## && sudo chown www-data:www-data -R -c /var/www/html

## Remove authentication files from image
RUN sudo rm -f  /var/www/html/var/composer_home/auth.json \
&& sudo rm -f  $COMPOSER_HOME/auth.json \
&& sudo rm -f   /var/www/.ssh/id_rsa 

COPY ./entrypoint.sh /usr/bin/entrypoint.sh
RUN sudo chmod +x  /usr/bin/entrypoint.sh
ENTRYPOINT ["sudo","/usr/bin/entrypoint.sh"]

# mysql
EXPOSE 3306 

# http
EXPOSE 80

# https
# EXPOSE 443
