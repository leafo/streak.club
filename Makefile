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

