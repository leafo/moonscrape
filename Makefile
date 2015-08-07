
.PHONY: init_db

init_db:
	tup
	-dropdb -U postgres moonscrape
	createdb -U postgres moonscrape
	lapis migrate
	make test_db > /dev/null

# copy dev db schema into test db
test_db::
	-dropdb -U postgres moonscrape_test
	createdb -U postgres moonscrape_test
	pg_dump -s -U postgres moonscrape | psql -U postgres moonscrape_test
	pg_dump -a -t lapis_migrations -U postgres moonscrape | psql -U postgres moonscrape_test

