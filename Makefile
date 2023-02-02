LUAJIT ?= /usr/local/openresty/luajit/bin/luajit

.PHONY: annotate_modes schema.sql init_schema test screenshot test_db prod_db migrate linit checkpoint restore_checkpoint devdb count vendor install_dependencies

test:
	busted

pin_dependencies:
	luarocks --lua-version=5.1 --local build --only-deps --pin

install_dependencies:
	luarocks --lua-version=5.1 --local build --only-deps

migrate:
	lapis migrate
	make schema.sql

assetspec::
	 lapis-eswidget generate_spec --esbuild-args='--external:/static/*' --tup-compile-dep-group='$$(TOP)/<moon>' --tup-bundle-dep-group='$$(TOP)/<coffee>' --source-dir=static/coffee --format tup > assetspec.Tupfile

schema.sql:
	pg_dump -s -U postgres streakclub > schema.sql
	pg_dump -a -t lapis_migrations -U postgres streakclub >> schema.sql

init_schema:
	createdb -U postgres streakclub
	cat schema.sql | psql -U postgres streakclub

screenshot:
	busted -o spec/screenshot_handler.lua

test_db:
	-dropdb -U postgres streakclub_test
	createdb -U postgres streakclub_test
	pg_dump -s -U postgres streakclub | psql -U postgres streakclub_test
	pg_dump -a -t lapis_migrations -U postgres streakclub | psql -U postgres streakclub_test

prod_db:
	-dropdb -U postgres streakclub_prod
	createdb -U postgres streakclub_prod
	pg_restore -U postgres -d streakclub_prod $$(find /mnt/drive/site-backups/ | grep streakclub | sort -V | tail -n 1)

lint:
	git ls-files | grep '\.moon$$' | grep -v config.moon | grep -v spec/ | xargs -n 100 moonc -l

checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres streakclub > dev_backup/$$(date +%F_%H-%M-%S).dump

restore_checkpoint:
	-dropdb -U postgres streakclub
	createdb -U postgres streakclub
	pg_restore -U postgres -d streakclub $$(find dev_backup | grep \.dump | sort -V | tail -n 1)

annotate_models:
	lapis annotate $$(find models -type f | grep moon$$)

count:
	wc -l $$(git ls-files | grep 'scss$$\|moon$$\|coffee$$\|md$$\|conf$$') | sort -n | tail

# copy all the node modules
vendor:
	npm install
	cp node_modules/jquery/dist/jquery.min.js static/lib
	cp node_modules/jstz/dist/jstz.min.js static/lib
	cp node_modules/typed.js/lib/typed.min.js static/lib
	cp node_modules/commonmark/dist/commonmark.min.js static/markdown/
	cp node_modules/turndown/dist/turndown.js static/markdown/
	cp node_modules/selectize/dist/js/standalone/selectize.min.js static/lib
	cp node_modules/selectize/dist/css/selectize.css static/lib
