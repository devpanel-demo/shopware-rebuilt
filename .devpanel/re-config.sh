#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2021 DevPanel
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation version 3 of the
# License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# For GNU Affero General Public License see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------

#== If webRoot has not been difined, we will set appRoot to webRoot

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
#== Composer install.
if [[ -f "composer.json" ]]; then
  echo "> Install Dependencies";
  composer install --no-interaction --optimize-autoloader
fi

echo "> Install Shopware Application";
bin/console system:install --basic-setup --force

echo "> allow-plugins";
composer config --no-plugins allow-plugins.php-http/discovery true

#== Extract static files
if [[ -f "$APP_ROOT/.devpanel/dumps/files.tgz" ]]; then
  echo  'Extract static files ...'
  sudo mkdir -p public
  sudo tar xzf "$APP_ROOT/.devpanel/dumps/files.tgz" -C public
  sudo rm -rf $APP_ROOT/.devpanel/dumps/files.tgz
fi

#== Import mysql files
if [[ -f "$APP_ROOT/.devpanel/dumps/db.sql.tgz" ]]; then
  echo 'Import mysql file ...'
  cd $APP_ROOT/.devpanel/dumps
  tar -xvzf db.sql.tgz

  mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME < db.sql
  mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD $DB_NAME -e "UPDATE sales_channel_domain SET url='https://$DP_HOSTNAME' WHERE url='http://localhost' OR url='https://localhost';"
  rm -rf $APP_ROOT/.devpanel/dumps/*
fi
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "
  UPDATE sales_channel_domain
  SET url = REPLACE(url, 'http://', 'https://');"

cd $APP_ROOT && bin/console cache:clear && bin/console cache:warmup
echo "> Successful, please refresh your web page.";
