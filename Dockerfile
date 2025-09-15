# Usa una imagen base con PHP y FPM
FROM php:8.2-fpm-alpine

# Instala dependencias del sistema
RUN apk --no-cache add \
    nginx \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    oniguruma \
    libzip-dev \
    supervisor \
    && rm -rf /var/cache/apk/*

# Instala extensiones de PHP
RUN docker-php-ext-install pdo pdo_mysql opcache bcmath
RUN docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp \
    && docker-php-ext-install -j$(nproc) gd

# Configura Nginx
COPY ./nginx.conf /etc/nginx/nginx.conf

# Configura Supervisor
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Instala Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copia los archivos de la aplicación
WORKDIR /var/www/html
COPY . .

# Instala las dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Genera la clave de la aplicación
RUN php artisan key:generate

# Establece los permisos
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expone el puerto 80
EXPOSE 80

# Comando para iniciar Nginx y PHP-FPM con Supervisor
CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
