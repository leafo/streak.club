schema.sql::
	pg_dump -s -U postgres streakclub > schema.sql
	pg_dump -a -t lapis_migrations -U postgres streakclub >> schema.sql

init_schema::
	createdb -U postgres streakclub
	cat schema.sql | psql -U postgres streakclub

test::
	busted -p _spec.moon$

test_db::
	-dropdb -U postgres streakclub_test
	createdb -U postgres streakclub_test
	pg_dump -s -U postgres streakclub | psql -U postgres streakclub_test
	pg_dump -a -t lapis_migrations -U postgres streakclub | psql -U postgres streakclub_test

migrate::
	lapis migrate

lint::
	# moonc -l $$(git ls-files | grep '\.moon$$' | grep -v config.moon)
	for file in $$(git ls-files | grep '\.moon$$' | grep -v config.moon); do moonc -l $$file; done

backup_dev_db:
	mkdir -p dev_backup
	pg_dump -F c -U postgres streakclub > dev_backup/$$(date +%F_%H-%M-%S).dump

restore_dev_db::
	-dropdb -U postgres streakclub
	createdb -U postgres streakclub
	pg_restore -U postgres -d streakclub $$(find dev_backup | grep \.dump | sort -V | tail -n 1)

