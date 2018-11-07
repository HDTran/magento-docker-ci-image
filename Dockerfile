FROM alexcheng/apache2-php7:latest

ENV INSTALL_DIR /var/www/html
ENV COMPOSER_HOME /var/www/.composer/

ARG MYSQL_HOST=localhost
ARG MYSQL_ROOT_PASSWORD=deity_magento2
ARG MYSQL_USER=magento2
ARG MYSQL_PASSWORD=magento2pass
ARG MYSQL_DATABASE=magento


ARG MAGENTO_VERSION_BRANCH_NAME=2.2

ARG MAGENTO_LANGUAGE=en_US
ARG MAGENTO_TIMEZONE=Europe/Amsterdam
ARG MAGENTO_DEFAULT_CURRENCY=USD

ARG MAGENTO_URL=http://127.0.0.1:8062

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



COPY ./composer/auth.json $COMPOSER_HOME
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

#COPY ./.ssh/id_rsa /var/www/.ssh/id_rsa

RUN mkdir /var/www/.ssh

RUN touch /var/www/.ssh/config

RUN echo "StrictHostKeyChecking no " >> /var/www/.ssh/config 
RUN echo "StrictHostKeyChecking no " >> /root/.ssh/config
RUN chown www-data:www-data $COMPOSER_HOME/auth.json
   
#   && chown www-data:www-data /var/www/.ssh/* \
#   && chmod 400 /var/www/.ssh/id_rsa \


RUN requirements="libpng12-dev libmcrypt-dev libmcrypt4 libcurl3-dev libfreetype6 libjpeg-turbo8 libjpeg-turbo8-dev libpng12-dev libfreetype6-dev libicu-dev libxslt1-dev git" \
    && apt-get update \
    && apt-get install -y $requirements \
    && apt-get install -y sudo \
    && apt-get install -y mysql-client \
    && apt-get install -y unzip \
    && apt-get install -y ssmtp \
    && apt-get install -y mailutils \
    && apt-get install -y mariadb-server \    
    && rm -rf /var/lib/apt/lists/* \
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
    && requirementsToRemove="libpng12-dev libmcrypt-dev libcurl3-dev libpng12-dev libfreetype6-dev libjpeg-turbo8-dev" \
    && apt-get purge --auto-remove -y $requirementsToRemove

# PECL install but not enable xdebug
# Symlink xdebug.so so that it is at a known path
RUN pecl install xdebug \
    && PHP_EXT_PATH=$(php -r 'echo ini_get("extension_dir");') \
    && ln -s "${PHP_EXT_PATH}/xdebug.so" /opt/xdebug.so

COPY ./config/xdebug.ini /usr/local/etc/php/conf.d/

RUN chsh -s /bin/bash www-data

RUN chown -R www-data:www-data /var/www

COPY ./install-magento /usr/local/bin/install-magento
RUN chmod +x /usr/local/bin/install-magento

COPY ./post-build.sh /usr/local/bin/post-build.sh
RUN chmod +x /usr/local/bin/post-build.sh

RUN a2enmod rewrite
RUN echo "memory_limit=2048M" > /usr/local/etc/php/conf.d/memory-limit.ini

RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#RUN echo "hostname=localhost.localdomain" >> /etc/ssmtp/ssmtp.conf
#RUN echo "root=root@deity.io" >> /etc/ssmtp/ssmtp.conf
#RUN echo "mailhub=deity_mailhog:1025" >> /etc/ssmtp/ssmtp.conf
#RUN echo "sendmail_path=/usr/sbin/ssmtp -t" >> /usr/local/etc/php/conf.d/php-sendmail.ini
#RUN echo "localhost localhost.localdomain" >> /etc/hosts

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR $INSTALL_DIR

# Add cron job
ADD crontab /etc/cron.d/magento2-cron
RUN chmod 0644 /etc/cron.d/magento2-cron \
    && crontab -u www-data /etc/cron.d/magento2-cron
    
RUN   composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html/

RUN  find /var/www/html/ -type f -exec chmod 666 {} \; \
&& find /var/www/html/ -type d -exec chmod 777 {} \;  \
&& chmod ugo+x /var/www/html/bin/magento

USER www-data

RUN /usr/local/bin/install-magento

RUN bin/magento  admin:user:create  --admin-user="${MAGENTO_NODEUSER_USERNAME}" --admin-password="${MAGENTO_NODEUSER_PASSWORD}" --admin-email="${MAGENTO_NODEUSER_EMAIL}" --admin-firstname="${MAGENTO_NODEUSER_FIRSTNAME}" --admin-lastname="${MAGENTO_NODEUSER_LASTNAME}"

RUN /var/www/html/bin/magento deploy:mode:set developer

#composer config repositories.deity-api '{"type": "path", "url": "../packages/api"}'
#composer require deity/falcon-magento:dev-master

RUN /var/www/html/bin/magento sampledata:deploy 
RUN /var/www/html/bin/magento setup:upgrade

RUN sudo chown www-data:www-data -R /var/www/html


############# POST BUILD 
    
    
EXPOSE 3306
EXPOSE 80
EXPOSE 443
