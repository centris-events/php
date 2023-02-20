FROM php:7.3.33-apache

ARG USER_ID=1000
ARG GROUP_ID=1000
ENV DOCKERIZE_VERSION v0.6.1

RUN apt-get update \
	&& apt-get install -y \
	libssl-dev \
	libicu-dev \
	libapache2-mod-rpaf \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	libpng-dev \
	libxml2-dev \
	libzip-dev \
	cron \
	sudo \
	acl \
	git \
	gnupg \
	pkg-config \
	libpcre3-dev \
	wget \
	&& docker-php-ext-install \
	iconv \
	intl \
	mbstring \
	pdo_mysql \
	zip \
	opcache \
	bcmath \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install gd \
	&& pecl install xdebug-3.1.5 \
	&& docker-php-ext-enable xdebug \
	&& wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& rm /tmp/* -rf \
	&& rm -r /var/lib/apt/lists/* \
	&& wget -O - https://download.newrelic.com/548C16BF.gpg | sudo apt-key add - \
	&& sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list' \
	&& apt-get update \
	&& apt-get install -y newrelic-php5 \
	&& NR_INSTALL_SILENT=1 newrelic-install install

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	&& php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
	&& php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
	&& php -r "unlink('composer-setup.php');"

RUN usermod -u $USER_ID www-data \
	&& groupmod -g $GROUP_ID www-data \
	&& mkdir -p /var/www/.composer \
	&& chown -R www-data:www-data /var/www/.composer

RUN sudo -u www-data composer global require phing/phing ~2.0

RUN a2enmod rewrite \
	&& a2enmod proxy \
	&& a2enmod proxy_http \
	&& a2enmod proxy_ajp \
	&& a2enmod rewrite \
	&& a2enmod deflate \
	&& a2enmod headers \
	&& a2enmod proxy_balancer \
	&& a2enmod proxy_connect \
	&& a2enmod proxy_html

CMD ["dockerize", "apache2-foreground"]