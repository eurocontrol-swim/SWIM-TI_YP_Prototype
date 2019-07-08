#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 <<-EOSQL
	CREATE USER $DB_USER;

	CREATE DATABASE $DB_NAME WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';;
	GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

	CREATE DATABASE testing WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';;
	GRANT ALL PRIVILEGES ON DATABASE testing TO $DB_USER;
EOSQL