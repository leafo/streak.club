schema.sql::
	pg_dump -s -U postgres streakclub > schema.sql
	pg_dump -a -t lapis_migrations -U postgres streakclub >> schema.sql

init_schema::
	createdb -U postgres streakclub
	cat schema.sql | psql -U postgres streakclub

test::
	busted

screenshot::
	busted -o spec/screenshot_handler.lua

test_db::
	-dropdb -U postgres streakclub_test
	createdb -U postgres streakclub_test
	pg_dump -s -U postgres streakclub | psql -U postgres streakclub_test
	pg_dump -a -t lapis_migrations -U postgres streakclub | psql -U postgres streakclub_test

prod_db::
	-dropdb -U postgres streakclub_prod
	createdb -U postgres streakclub_prod
	pg_restore -U postgres -d streakclub_prod $$(find /home/leafo/bin/backups/ | grep streakclub | sort -V | tail -n 1)

migrate::
	lapis migrate
	make schema.sql

lint::
	# moonc -l $$(git ls-files | grep '\.moon$$' | grep -v config.moon)
	for file in $$(git ls-files | grep '\.moon$$' | grep -v config.moon); do moonc -l $$file; done

checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U postgres streakclub > dev_backup/$$(date +%F_%H-%M-%S).dump

restore_checkpoint::
	-dropdb -U postgres streakclub
	createdb -U postgres streakclub
	pg_restore -U postgres -d streakclub $$(find dev_backup | grep \.dump | sort -V | tail -n 1)

devdb:
	psql -U postgres streakclub

count::
	wc -l $$(git ls-files | grep 'scss$$\|moon$$\|coffee$$\|md$$\|conf$$') | sort -n | tail
