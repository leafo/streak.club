#!/bin/bash
set -e
set -o pipefail
set -o xtrace

# setup lua
luarocks --lua-version=5.1 --local remove --force lapis
luarocks --lua-version=5.1 --local remove --force moonscript
luarocks --lua-version=5.1 --local install https://luarocks.org/manifests/leafo/lapis-dev-1.rockspec
luarocks --lua-version=5.1 --local install https://luarocks.org/manifests/leafo/lapis-community-dev-1.rockspec
luarocks --lua-version=5.1 --local install moonscript
eval $(luarocks --lua-version=5.1 --local path)

# prepare secrets
rm -r secret
cp -r secret_example secret
echo "config 'test', -> logging false" >> config.moon

# build
tup init && tup generate build.sh && ./build.sh
cat $(which busted) | sed 's/\/usr\/bin\/lua5\.1/\/usr\/bin\/luajit/' > busted
chmod +x busted

# start postgres
echo "fsync = off" >> /var/lib/postgres/data/postgresql.conf
echo "synchronous_commit = off" >> /var/lib/postgres/data/postgresql.conf
echo "full_page_writes = off" >> /var/lib/postgres/data/postgresql.conf
su postgres -c '/usr/bin/pg_ctl -s -D /var/lib/postgres/data start -w -t 120'

make init_schema
make migrate
make test_db

./busted -o utfTerminal
