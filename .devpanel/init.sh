#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2021 DevPanel
#
# This program is free software: you can redistribute it and/or modify it
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# For GNU Affero General Public License see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------

if [[ ! -n "$APACHE_RUN_USER" ]]; then
  export APACHE_RUN_USER=www-data
fi
if [[ ! -n "$APACHE_RUN_GROUP" ]]; then
  export APACHE_RUN_GROUP=www-data
fi

#== If webRoot has not been defined, we will set appRoot to webRoot
if [[ ! -n "$WEB_ROOT" ]]; then
  export WEB_ROOT=$APP_ROOT
fi

cd $APP_ROOT
cp -r $APP_ROOT/.devpanel/.gitignore $APP_ROOT/.gitignore

#== Remove root-owned files.
echo Remove root-owned files.
sudo rm -rf lost+found/

echo "> Install Dependencies";
composer install --no-interaction --optimize-autoloader

echo "> Install Shopware Application";
bin/console system:install --basic-setup --force

echo "> allow-plugins";
composer config --no-plugins allow-plugins.php-http/discovery true
# composer require --dev shopware/dev-tools
# APP_ENV=prod bin/console framework:demodata
# bin/console dal:refresh:index

git clone https://github.com/shopware/SwagPlatformDemoData.git custom/plugins/SwagPlatformDemoData
bin/console plugin:refresh
bin/console plugin:install --activate SwagPlatformDemoData

echo "> Add Devpanel Admin User";
bin/console user:create devpanel --password=devpanel --email=developer@devpanel.com --firstName=DevPanel

echo "> Set completedAt for bypass admin config";
bin/console system:config:set core.frw.completedAt "$(date -Iseconds)"

# mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "UPDATE sales_channel_domain SET url='https://$DP_HOSTNAME' WHERE url='http://localhost' OR url='https://localhost';"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
  UPDATE sales_channel_domain
  SET url = REPLACE(url, 'http://', 'https://');"

bin/console cache:clear
bin/console cache:warmup
echo "> Successful, please refresh your web page.";
