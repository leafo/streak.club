.PHONY: annotate_modes schema.sql init_schema test screenshot test_db prod_db migrate linit checkpoint restore_checkpoint devdb count vendor

test:
	busted

migrate:
	lapis migrate
	make schema.sql

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
	git ls-files | grep '\.moon$$' | grep -v config.moon | xargs -n 100 moonc -l

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
	cp node_modules/d3/d3.min.js static/lib
	cp node_modules/moment/min/moment.min.js static/lib
	cp node_modules/jstz/dist/jstz.min.js static/lib
	cp node_modules/underscore/underscore-min.js static/lib
	cp node_modules/underscore.string/dist/underscore.string.min.js static/lib
	cp node_modules/react/dist/react.min.js static/lib
	cp node_modules/react-dom/dist/react-dom.min.js static/lib
	cp node_modules/sticky-kit/dist/sticky-kit.min.js static/lib
	cp node_modules/typed.js/dist/typed.min.js static/lib
