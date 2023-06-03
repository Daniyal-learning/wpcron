#!/bin/bash

# Define the regular expression pattern for WordPress installation directories
wordpress_pattern="/home/master/applications/*/public_html"

# Loop through each WordPress installation directory
for wordpress_dir in $wordpress_pattern; do
    wp_config="${wordpress_dir}/wp-config.php"

    # Check if wp-config.php exists
    if [ ! -f "$wp_config" ]; then
        echo "wp-config.php not found in $wordpress_dir. Not a WordPress app."
        continue
    fi

    # Extract the database name from wp-config.php
    db_name=$(grep -oP "define\(\s*'DB_NAME',\s*'\K[^']+" "$wp_config")
    echo "Database name: $db_name"

    # Check if cron is already disabled in wp-config.php
    grep -q "define( 'DISABLE_WP_CRON',\s*true );" "$wp_config"
    if [ $? -eq 0 ]; then
        echo "Cron is already disabled in $wp_config. Skipping..."
        continue
    fi

    # Add DISABLE_WP_CRON definition on the third line of wp-config.php
    sed -i '2i define( '\''DISABLE_WP_CRON'\'', true );' "$wp_config"

    # Add cron job to the application's cron tab on the server
    cronjob="*/5 * * * * cd ${wordpress_dir} && /usr/bin/php /usr/local/bin/wp cron event run --due-now"
    (crontab -u "$db_name" -l 2>/dev/null; echo "$cronjob") | crontab -u "$db_name" -
done

echo "Cron disabled in wp-config.php and added to the application's cron tab for each WordPress app."
