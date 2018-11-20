FROM kaz29/php-apache:7.2.8

ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars
ENV COMPOSER_HOME /usr/local

# ARG HOST_NAME
# ARG HOST_PORT

#ENV HOST_PORT "$HOST_PORT"
ENV HOST_PORT "80"
ENV DOCUMENT_ROOT "/srv/app/webroot"

COPY config/001-app.conf /etc/apache2/sites-available/000-default.conf
COPY config/ports.conf /etc/apache2/ports.conf
COPY config/apc.ini /usr/local/etc/php/conf.d/

RUN set -ex \
# append apache envver
	&& echo "export HOST_PORT=$HOST_PORT" >> "$APACHE_ENVVARS" \
	&& echo "export DOCUMENT_ROOT=$DOCUMENT_ROOT" >> "$APACHE_ENVVARS" \
# setup apache envvers
	&& sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS" \
	&& . "$APACHE_ENVVARS" \
# install php modules
	&& pecl install redis \
	&& pecl install apcu \
	&& docker-php-ext-enable redis \
	&& docker-php-ext-enable apcu \
# link application logfile to stdio
	&& ln -sfT /dev/stderr "$APACHE_LOG_DIR/app-error.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/app-access.log" \
# enable module/site
	&& a2enmod rewrite \
#	&& a2ensite 001-app \
# install composer
	&& { \
		curl -sS https://getcomposer.org/installer; \
	} | php \
	&& mv composer.phar /usr/local/bin/composer

COPY app/composer.json app/composer.lock /srv/app/

RUN composer install --working-dir=/srv/app --no-dev

COPY app /srv/app/

WORKDIR /srv/app
