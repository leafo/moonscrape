
.PHONY: init_db

init_db:
	-dropdb -U postgres moonscrape
	createdb -U postgres moonscrape
	lapis migrate