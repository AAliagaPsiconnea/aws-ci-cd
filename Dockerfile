FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
     libzip-dev \
     libpng-dev \
     libjpeg-dev \
     libwebp-dev \
     libfreetype6-dev \
     zlib1g-dev \
     libicu-dev \
     libxml2-dev \
     zip \
     unzip \
     curl

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
     && docker-php-ext-install -j$(nproc) gd \
     && docker-php-ext-configure intl \
     && docker-php-ext-install zip \
     && docker-php-ext-install -j$(nproc) intl pdo_mysql exif soap

RUN a2enmod rewrite

# # Install supervisor and composer
RUN apt-get install -y supervisor

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Clear cache and add user
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* \
#     && groupadd -g 1000 www \
#     && useradd -u 1000 -ms /bin/bash -g www www
# Set working directory
WORKDIR /var/www/html/

# # Copy code to /var/www
COPY ./000-default.conf /etc/apache2/sites-available
COPY --chown=www:www-data . .

# Copy configs
RUN cp docker/supervisor.conf /etc/supervisord.conf

RUN chmod -R ug+w /var/www/html/storage \
     && mkdir -p /var/www/html/storage/logs \
     && touch /var/www/html/storage/logs/laravel.log \
     && chown -R www-data:www-data /var/www/html/storage/logs/laravel.log \
     && mkdir /var/log/php \
     && touch /var/log/php/errors.log && chmod 777 /var/log/php/errors.log

# Deployment steps
RUN composer install --optimize-autoloader --no-dev

RUN php artisan config:clear \
    && php artisan route:clear \
    && php artisan view:clear

# Copy configs
RUN cp docker/supervisor.conf /etc/supervisord.conf

ENV TZ=Europe/Madrid
RUN echo "date.timezone=Europe/Madrid" > /usr/local/etc/php/conf.d/timezone.ini
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
