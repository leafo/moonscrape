
.PHONY: init_db test_db lint build

init_db:
	make build
	tup
	-dropdb -U postgres moonscrape
	createdb -U postgres moonscrape
	lapis migrate
	make test_db > /dev/null

local: build
	luarocks make --local moonscrape-dev-1.rockspec

build:
	moonc moonscrape

# copy dev db schema into test db
test_db:
	-dropdb -U postgres moonscrape_test
	createdb -U postgres moonscrape_test
	pg_dump -s -U postgres moonscrape | psql -U postgres moonscrape_test
	pg_dump -a -t lapis_migrations -U postgres moonscrape | psql -U postgres moonscrape_test

lint:
	tup
	moonc -l $$(find moonscrape | grep moon$$)
	moonc -l $$(find spec | grep moon$$)
