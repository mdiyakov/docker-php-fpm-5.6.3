FROM php:5.6.3-fpm
MAINTAINER bolverk <m.djakov@gmail.com>

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

#install nodejs
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 6.9.1

RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash \
    && source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

#install grunt
RUN apt-get update && apt-get -y install npm \
    && cd / && npm install grunt-cli@0.1.13

#install yarn
RUN apt-get update && apt-get -y install apt-transport-https
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get -y install yarn


#install php related stuff
RUN apt-get update
RUN apt-get -y install php-pear
RUN pecl -C /usr/local/etc/pear.conf update-channels
RUN pecl -C /usr/local/etc/pear.conf install channel://pecl.php.net/apcu-4.0.6
RUN apt-get -y install php5-pgsql \
    && apt-get -y install php5-mysql \
    && apt-get -y install php5-gd
RUN apt-get install -y -q --no-install-recommends \
		ssmtp \
	&& apt-get clean \
	&& rm -r /var/lib/apt/lists/*

RUN touch /usr/local/etc/php/conf.d/apcu.ini \
    && echo "extension=/usr/local/lib/php/extensions/no-debug-non-zts-20131226/apcu.so" >>  /usr/local/etc/php/conf.d/apcu.ini \
    && echo "apc.enabled=0" >> /usr/local/etc/php/conf.d/apcu.ini \
    && echo "apc.shm_size=128M" >> /usr/local/etc/php/conf.d/apcu.ini \
    && echo "apc.ttl=0" >> /usr/local/etc/php/conf.d/apcu.ini

RUN touch /usr/local/etc/php/conf.d/date.ini \
    && echo "date.timezone = Europe/London" >>  /usr/local/etc/php/conf.d/date.ini

RUN echo "extension=/usr/lib/php5/20131226/pdo_pgsql.so" >>  /usr/local/etc/php/conf.d/pdo_pgsql.ini \
    && echo "extension=/usr/lib/php5/20131226/pdo_mysql.so" >> /usr/local/etc/php/conf.d/pdo_mysql.ini \
    && echo "extension=/usr/lib/php5/20131226/gd.so" >> /usr/local/etc/php/conf.d/gd.ini

RUN touch /usr/local/etc/php/conf.d/pgsql.ini \
    && echo "extension=/usr/lib/php5/20131226/pgsql.so" >>  /usr/local/etc/php/conf.d/pgsql.ini

RUN echo "memory_limit = -1" >>  /usr/local/etc/php/conf.d/php_settings.ini \
    && echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

RUN ln -s /node_modules/grunt-cli/bin/grunt /usr/bin/grunt

ENV PATH "$PATH:/usr/local/nvm/versions/node/v6.9.1/bin"

COPY conf/ /usr/local/etc/php-fpm.d/
COPY ssmtp/ /etc/ssmtp/

#install xdebug
COPY xdebug/xdebug-2.5.4.tgz /tmp/
COPY xdebug/xdebug.ini /usr/local/etc/php/conf.d/
RUN cd /tmp/ && tar -xvzf /tmp/xdebug-2.5.4.tgz && cd xdebug-2.5.4 \
       && phpize \
       && ./configure \
       && make \
       && cp /tmp/xdebug-2.5.4/modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20131226 \
       && echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20131226/xdebug.so" >> /usr/local/etc/php/conf.d/xdebug.ini

#install git
RUN apt-get update && apt-get -y install git

CMD ["php-fpm"]