#!/bin/bash
# ---------------------------------------------------------------------
# Copyright (C) 2024 DevPanel
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

echo -e "-------------------------------"
echo -e "| DevPanel Quickstart Creator |"
echo -e "-------------------------------\n"

# Preparing
WORK_DIR=$APP_ROOT
DUMPS_DIR=$APP_ROOT/.devpanel/dumps
mkdir -p $DUMPS_DIR
MYSQL_CONN="-h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD"
TMP_TABLE=tmp_table
TMP_FILE=tmp_file

# Step 1 - Export and compress database
cd $WORK_DIR
echo -e "> Export database"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  --ignore-table=$DB_NAME.media \
  --ignore-table=$DB_NAME.document \
  --ignore-table=$DB_NAME.order \
  --ignore-table=$DB_NAME.order_delivery_position \
  --ignore-table=$DB_NAME.order_line_item \
  --ignore-table=$DB_NAME.product_keyword_dictionary \
  $DB_NAME > $DUMPS_DIR/db.sql

# - Custom media table
echo "> Custom media table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME media --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, user_id, media_folder_id, mime_type, file_extension,
    file_size, meta_data, file_name, media_type, thumbnails_ro,
    private, uploaded_at, created_at, updated_at, path, config
  FROM media;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`media`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `media`/INSERT INTO `media` (`id`, `user_id`, `media_folder_id`, `mime_type`, `file_extension`, `file_size`, `meta_data`, `file_name`, `media_type`, `thumbnails_ro`, `private`, `uploaded_at`, `created_at`, `updated_at`, `path`, `config`)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

# - Custom document table
echo "> Custom document table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME document --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, document_type_id, referenced_document_id, order_id, order_version_id,
    config, sent, static, deep_link_code, document_media_file_id,
    custom_fields, created_at, updated_at, document_a11y_media_file_id
  FROM document;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`document`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `document`/INSERT INTO `document` (`id`, `document_type_id`, `referenced_document_id`, `order_id`, `order_version_id`, `config`, `sent`, `static`, `deep_link_code`, `document_media_file_id`, `custom_fields`, `created_at`, `updated_at`, `document_a11y_media_file_id`)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

# - Custom order table
echo "> Custom order table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME order --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, version_id, state_id, auto_increment, order_number, currency_id, language_id, currency_factor, sales_channel_id, 
    billing_address_id, billing_address_version_id, price, order_date_time, shipping_costs, deep_link_code, custom_fields, 
    affiliate_code, campaign_code, customer_comment, created_at, updated_at, item_rounding, total_rounding, rule_ids, 
    created_by_id, updated_by_id, source, primary_order_delivery_id, primary_order_delivery_version_id, 
    primary_order_transaction_id, primary_order_transaction_version_id, internal_comment, tax_calculation_type
  FROM \`order\`;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`order`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `order`/INSERT INTO `order` (id, version_id, state_id, auto_increment, order_number, currency_id, language_id, currency_factor, sales_channel_id, billing_address_id, billing_address_version_id, price, order_date_time, shipping_costs, deep_link_code, custom_fields, affiliate_code, campaign_code, customer_comment, created_at, updated_at, item_rounding, total_rounding, rule_ids, created_by_id, updated_by_id, source, primary_order_delivery_id, primary_order_delivery_version_id, primary_order_transaction_id, primary_order_transaction_version_id, internal_comment, tax_calculation_type)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

# - Custom order_delivery_position table
echo "> Custom order_delivery_position table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME order_delivery_position --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, version_id, order_delivery_id, order_delivery_version_id, order_line_item_id, order_line_item_version_id, 
    price, custom_fields, created_at, updated_at
  FROM order_delivery_position;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`order_delivery_position`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `order_delivery_position`/INSERT INTO `order_delivery_position` (id, version_id, order_delivery_id, order_delivery_version_id, order_line_item_id, order_line_item_version_id, price, custom_fields, created_at, updated_at)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

# - Custom order_line_item table
echo "> Custom order_line_item table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME order_line_item --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, version_id, order_id, order_version_id, parent_id, parent_version_id, identifier, referenced_id, product_id, 
    product_version_id, promotion_id, label, description, cover_id, quantity, type, payload, price_definition, price, 
    stackable, removable, good, position, custom_fields, created_at, updated_at, states
  FROM order_line_item;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`order_line_item`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `order_line_item`/INSERT INTO `order_line_item` (id, version_id, order_id, order_version_id, parent_id, parent_version_id, identifier, referenced_id, product_id, product_version_id, promotion_id, label, description, cover_id, quantity, type, payload, price_definition, price, stackable, removable, good, position, custom_fields, created_at, updated_at, states)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

# - Custom product_keyword_dictionary table
echo "> Custom product_keyword_dictionary table"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces \
  $DB_NAME product_keyword_dictionary --where="1=0" >> $DUMPS_DIR/db.sql
mysql $MYSQL_CONN $DB_NAME -e "
  DROP TABLE IF EXISTS tmp_table;
  CREATE TABLE tmp_table AS
  SELECT
    id, language_id, keyword
  FROM product_keyword_dictionary;"
mysqldump $MYSQL_CONN \
  --quick --lock-tables=false --no-tablespaces --no-create-info \
  $DB_NAME tmp_table > $DUMPS_DIR/$TMP_FILE.sql

sed -i 's/`tmp_table`/`product_keyword_dictionary`/g' $DUMPS_DIR/$TMP_FILE.sql
sed -i 's/INSERT INTO `product_keyword_dictionary`/INSERT INTO `product_keyword_dictionary` (id, language_id, keyword)/g' $DUMPS_DIR/$TMP_FILE.sql
cat $DUMPS_DIR/$TMP_FILE.sql >> $DUMPS_DIR/db.sql

##
sed -i 's/INSERT INTO/INSERT IGNORE INTO/g' $DUMPS_DIR/db.sql
du -h $DUMPS_DIR/db.sql

echo -e "> Compress database"
tar -czf "$DUMPS_DIR/db.sql.tgz" -C $DUMPS_DIR db.sql
rm -rf $DUMPS_DIR/db.sql $DUMPS_DIR/tmp_file.sql

# Step 2 - Compress static files
echo -e "> Compress static files and store to $DUMPS_DIR"
tar czf $DUMPS_DIR/files.tgz -C $WORK_DIR/public \
  --exclude='.htaccess' \
  --exclude='.htaccess.dist' \
  --exclude='index.php' \
  --exclude='maintenance.html' \
  .
