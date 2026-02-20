FROM php:8.5-apache

ARG USER_ID=1000
ARG GROUP_ID=1000
ENV DOCKERIZE_VERSION=v0.10.0

# Install system dependencies
RUN apt-get update \
	&& apt-get install -y \
	libssl-dev \
	libicu-dev \
	libapache2-mod-rpaf \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libpng-dev \
	libxml2-dev \
	libzip-dev \
	libonig-dev \
	cron \
	sudo \
	acl \
	git \
	gnupg \
	pkg-config \
	wget \
	&& rm -r /var/lib/apt/lists/*

# Install PHP extensions (opcache is included in php:8.5-apache, skip to avoid build failure)
RUN docker-php-ext-install \
	iconv \
	intl \
	mbstring \
	pdo_mysql \
	zip \
	bcmath \
	simplexml

# Install GD extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install gd

# Install Xdebug (3.5+ for PHP 8.5)
RUN pecl install xdebug \
	&& docker-php-ext-enable xdebug

# Install dockerize (use TARGETARCH so image runs natively on arm64 and amd64)
ARG TARGETARCH
RUN DOCKERIZE_ARCH=${TARGETARCH:-amd64} \
	&& wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-${DOCKERIZE_ARCH}-$DOCKERIZE_VERSION.tar.gz -O /tmp/dockerize.tar.gz \
	&& tar -C /usr/local/bin -xzvf /tmp/dockerize.tar.gz \
	&& rm /tmp/dockerize.tar.gz

# Install New Relic (tar method works on both amd64 and arm64; apt only has amd64)
ENV NEWRELIC_PHP_AGENT_VERSION=12.5.0.30
RUN wget -q https://download.newrelic.com/php_agent/release/newrelic-php5-${NEWRELIC_PHP_AGENT_VERSION}-linux.tar.gz -O /tmp/newrelic.tar.gz \
	&& gzip -dc /tmp/newrelic.tar.gz | tar xf - -C /tmp \
	&& cd /tmp/newrelic-php5-${NEWRELIC_PHP_AGENT_VERSION}-linux \
	&& NR_INSTALL_SILENT=1 ./newrelic-install install \
	&& rm -rf /tmp/newrelic.tar.gz /tmp/newrelic-php5-${NEWRELIC_PHP_AGENT_VERSION}-linux

# If New Relic did not install the .so (e.g. PHP 8.5 not yet supported), disable it so PHP does not warn
RUN EXT_DIR=$(php -r 'echo ini_get("extension_dir");') \
	&& if [ ! -f "$EXT_DIR/newrelic.so" ]; then find /usr/local/etc/php -name '*newrelic*' -delete; fi

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
	&& php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
	&& php -r "unlink('composer-setup.php');"

# Configure www-data user
RUN usermod -u $USER_ID www-data \
	&& groupmod -g $GROUP_ID www-data \
	&& mkdir -p /var/www/.composer \
	&& chown -R www-data:www-data /var/www/.composer

# Install Phing globally
RUN sudo -u www-data composer global require phing/phing ~2.0

# Enable Apache modules
RUN a2enmod rewrite \
	&& a2enmod proxy \
	&& a2enmod proxy_http \
	&& a2enmod proxy_ajp \
	&& a2enmod deflate \
	&& a2enmod headers \
	&& a2enmod proxy_balancer \
	&& a2enmod proxy_connect \
	&& a2enmod proxy_html

CMD ["dockerize", "apache2-foreground"]