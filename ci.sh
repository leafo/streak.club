#!/bin/bash
set -e
set -o pipefail
set -o xtrace

luarocks="luarocks --tree=\"$HOME/.luarocks\" --lua-version=5.1"

$luarocks build --only-deps
eval $($luarocks path)

# for running CI with dev stuff
# $luarocks install https://raw.githubusercontent.com/leafo/lapis/master/lapis-dev-1.rockspec
# $luarocks install https://raw.githubusercontent.com/leafo/lapis-community/master/lapis-community-dev-1.rockspec

# prepare secrets
cp -r secret_example secret
echo "config 'test', -> logging false" >> config.moon
echo "user root;" >> nginx.conf

# build
npm install
tup init && tup generate build.sh && ./build.sh
cat $(which busted) | sed 's/\/usr\/bin\/lua5\.1/\/usr\/local\/openresty\/luajit\/bin\/luajit/' > busted
chmod +x busted

# start postgres
echo "fsync = off" >> /var/lib/postgres/data/postgresql.conf
echo "synchronous_commit = off" >> /var/lib/postgres/data/postgresql.conf
echo "full_page_writes = off" >> /var/lib/postgres/data/postgresql.conf
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data start -w -t 120'

make init_schema
make migrate
make test_db

mkdir -p logs
touch logs/notice.log
tail -f logs/notice.log &

LAPIS_NOTICE_LOG=logs/notice.log ./busted --helper lapis.db -o utfTerminal -v
