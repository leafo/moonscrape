
.PHONY: init_db test_db lint build null migrate backup

null:
	echo "Choose a task init_db, local, build, test_db, backup"

backup:
	mkdir -p backup
	pg_dump -F c -U postgres moonscrape > backup/$$(date +%F_%H-%M-%S)_$$(luajit -e 'print(require("lapis.db").query("select max(name) from lapis_migrations")[1].max)').dump

migrate: build
	tup
	lapis migrate
	make test_db > /dev/null

init_db: build
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
