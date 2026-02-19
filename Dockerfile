FROM php:8.1-apache

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

# Install PHP extensions
RUN docker-php-ext-install \
	iconv \
	intl \
	mbstring \
	pdo_mysql \
	zip \
	opcache \
	bcmath \
	simplexml

# Install GD extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
	&& docker-php-ext-install gd

# Install Xdebug
RUN pecl install xdebug-3.3.0 \
	&& docker-php-ext-enable xdebug

# Install dockerize
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
	&& rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install New Relic
RUN wget -O- https://download.newrelic.com/NEWRELIC_APT_2DAD550E.public | gpg --dearmor -o /usr/share/keyrings/download.newrelic.com-newrelic.gpg \
	&& echo 'deb [signed-by=/usr/share/keyrings/download.newrelic.com-newrelic.gpg] http://apt.newrelic.com/debian/ newrelic non-free' > /etc/apt/sources.list.d/newrelic.list \
	&& apt-get update \
	&& apt-get install -y newrelic-php5 \
	&& NR_INSTALL_SILENT=1 newrelic-install install \
	&& rm -r /var/lib/apt/lists/*

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