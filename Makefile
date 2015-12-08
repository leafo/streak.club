.PHONY: annotate_modes schema.sql init_schema test screenshot test_db prod_db migrate linit checkpoint restore_checkpoint devdb count

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
	pg_restore -U postgres -d streakclub_prod $$(find /home/leafo/bin/backups/ | grep streakclub | sort -V | tail -n 1)

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
