#!/bin/bash
# Copyright (c) 2016 Mattermost, Inc. All Rights Reserved.
# See License.txt for license information.

echo "Starting MySQL"
/entrypoint.sh mysqld &

until mysqladmin -hlocalhost -P3306 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" processlist &> /dev/null; do
	echo "MySQL still not ready, sleeping"
	sleep 5
done

function update_db {
	if [ ! -f /var/lib/mysql/custom-ja ]; then
		echo "########## Updating db for Japanese ##########"
		while true; do
			MYSQL_PWD=mostest mysql -u mmuser mattermost_test -e "select * from Posts limit 0;"
			if [ $? -ne 0 ]; then
				sleep 3
				echo "########## No Posts Table -> sleep 3 ##########"
			else
				sleep 3
				break
			fi
		done
		
		while true; do
			MYSQL_PWD=mostest mysql mattermost_test -u mmuser -e "ALTER TABLE Posts DROP INDEX idx_posts_message_txt;"
			if [ $? -eq 0 ]; then
				break
			fi
			echo "##### retring DROP INDEX ... #####"
			sleep 3
		done
		while true; do
			MYSQL_PWD=mostest mysql mattermost_test -u mmuser -e "ALTER TABLE Posts ADD FULLTEXT INDEX idx_posts_message_txt (\`Message\`) WITH PARSER ngram COMMENT 'ngram index sample';"
			if [ $? -eq 0 ]; then
				break
			fi
			echo "##### retring ADD INDEX ... #####"
			sleep 3
		done
		touch /var/lib/mysql/custom-ja
		echo "########## /var/lib/mysql/custom-ja created ##########"
	else
		echo "########## Already updated for Japanese ##########"
	fi
}

update_db &
echo "Starting platform"
cd mattermost
exec ./bin/platform --config=config/config_docker.json
