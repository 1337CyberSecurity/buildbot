#!/bin/bash

set -xeuvo pipefail

cd /code
[ -d mysql ] || git clone https://github.com/mysqljs/mysql
cd mysql
git clean -dfx
git pull --tags
if [ $# -gt 0 ]
then
  if [ ! -d ../"$1" ]
  then
    git worktree add ../"$1" "$1"
  fi
  cd ../"$1"
  # this is right for tags, not for branches yet
  git checkout $1
fi

# awaiting fix https://github.com/mysqljs/mysql/pull/2442
sed -i -e '/flush_tables/d' test/integration/connection/test-statistics.js

# fix for ERR_SSL_EE_KEY_TOO_SMALL (1024 bit test/fixtures/server.key)
rm -f test/unit/connection/test-connection-ssl-reject.js \
	 test/unit/connection/test-connection-ssl-ignore.js \
	 test/unit/connection/test-connection-ssl-ciphers.js

npm install
# Run the unit tests (probably should be controlled with worker variable)
# If unit==1 run unit test else run integration test
cd ./test
FILTER=unit npm test

# Run integration test - we are more interested in this!
/usr/local/mariadb/bin/mysql -u root -e "CREATE DATABASE IF NOT EXISTS node_mysql_test"
MYSQL_HOST=localhost MYSQL_PORT=3306 MYSQL_DATABASE=node_mysql_test MYSQL_USER=root MYSQL_PASSWORD= FILTER=integration npm test

