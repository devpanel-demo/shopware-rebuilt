#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2025 DevPanel
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

#== Import database
MYSQL_CONN="-h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD"
source_domain=$(grep -m1 -v '^[[:space:]]*$' $APP_ROOT/.devpanel/dumps/source_domain.txt)

if [[ $(mysql $MYSQL_CONN $DB_NAME -e "show tables;") == '' ]]; then
  if [[ -f "$APP_ROOT/.devpanel/dumps/db.sql.tgz" ]]; then
    echo 'Import mysql file ...'
    cd $APP_ROOT/.devpanel/dumps
    tar -xvzf db.sql.tgz

    mysql $MYSQL_CONN $DB_NAME < db.sql
    mysql $MYSQL_CONN $DB_NAME -e "UPDATE sales_channel_domain SET url='https://$DP_HOSTNAME' WHERE url IN ('http://localhost', 'https://localhost', '$source_domain');"

    rm -rf $APP_ROOT/.devpanel/dumps/*
  fi
else
  echo "Have tables"
fi
mysql $MYSQL_CONN $DB_NAME -e "
  UPDATE sales_channel_domain
  SET url = REPLACE(url, 'http://', 'https://');"

if [[ -n "$DB_SYNC_VOL" ]]; then
  if [[ ! -f "/var/www/build/.devpanel/init-container.sh" ]]; then
    echo 'Sync volume...'
    sudo chown -R 1000:1000 /var/www/build
    rsync -av --delete --delete-excluded $APP_ROOT/ /var/www/build
  fi
fi
