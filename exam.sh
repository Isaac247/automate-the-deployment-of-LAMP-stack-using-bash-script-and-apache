#!/bin/bash

echo "Updating package repository"
sudo apt update && sudo apt upgrade -y
echo "package repository update completed"

echo "Installing Apache2 package"
sudo apt install apache2 -y
echo "Apache package Install completed"

echo "Installing php and it's dependencies"
sudo apt-add-repository ppa:ondrej/php --yes
sudo apt-get install php8 -y
sudo apt install php php-pear php-common php-dev php-zip php-curl php-xmlrpc php-gd php-mysql php-mbstring php-xml libapache2-mod-php -y
echo "php package installation  completed"

echo "Installing mysql-server"
sudo apt install mysql-server -y
sudo apt install mysql-client
echo "LAMB installation completed"

echo "Installing composer dependency manager for php"
sudo curl  -sS https://getcomposer.org/installer |  php -q
echo "setting up composer installation"
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer
echo "composer installation completed"

echo "cloning laravel repo from github"
cd /var/www/
sudo git clone https://github.com/laravel/laravel.git
cd /var/www/laravel/
sudo composer install --optimize-autoloader --no-dev --no-interaction
echo "laravel-repo successsfully cloned"


echo "changing the ownership of the laravel directory to webserver user"
sudo chown -R www-data /var/www/laravel/storage
sudo chown -R www-data /var/www/laravel/bootstrap

echo "Updating ENV file"
cd /var/www/laravel
sudo cp .env.example .env
echo "env file successfully updated"

echo "creating database"
sudo mysql -uroot -e "CREATE DATABASE demo;"
sudo mysql -uroot -e "CREATE USER 'demoAdmin'@'localhost' IDENTIFIED BY 'helloWorld12345-';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON demo.* TO 'demoAdmin'@'localhost';"
echo "mysql database created"

echo "editing env file"
cd /var/www/laravel
echo "commenting out configuration"
sudo sed -i '23,27 s/^#//' /var/www/laravel/.env

echo "inserting configuration"
sudo sed -i '22 s/=sqlite/=mysql/' /var/www/laravel/.env
sudo sed -i '23 s/=127.0.0.1/=localhost/' /var/www/laravel/.env
sudo sed -i '24 s/=3306/=3306/' /var/www/laravel/.env
sudo sed -i '25 s/=laravel/=demo/' /var/www/laravel/.env
sudo sed -i '26 s/=root/=demoAdmin/' /var/www/laravel/.env
sudo sed -i '27 s/=/=helloWorld12345-/' /var/www/laravel/.env


echo "configuring apache for laravel"
sudo touch /etc/apache2/sites-available/laravel.conf
sudo touch /tmp/tmp_file.config
filename="/etc/apache2/sites-available/laravel.conf"
tempfile="/tmp/temp_file.conf"
text="<VirtualHost *:80>
   ServerName localhost
   DocumentRoot /var/www/laravel/public

   <Directory /var/www/laravel>
      Options Indexes FollowSymLinks
      AllowOverride All
      Require all granted
   </Directory>

   ErrorLog \${APACHE_LOG_DIR}/error.log
   CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>"
echo "$text" > "$tempfile"
sudo mv "$tempfile" "$filename"
echo "configuration done"

echo "generating an encryption key"
cd /var/www/laravel
sudo php artisan key:generate
sudo php artisan storage:link
sudo php artisan migrate
sudo php artisan db:seed
sudo a2enmod rewrite
sudo a2dissite 000-default.conf
sudo a2ensite laravel.conf
sudo systemctl restart apache2

