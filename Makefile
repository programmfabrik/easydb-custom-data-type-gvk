# have to use l10n2json from running docker container, so it
# is slightly complicated to launch the command
L10N2JSON = docker exec -t -i easydb-server /usr/bin/env LD_LIBRARY_PATH=/easydb-5/lib /easydb-5/bin/l10n2json

# absolute path in docker container
PATH_IN_CONTAINER=/config/plugin/custom-data-type-gvk

CULTURES_CSV = l10n/cultures.csv
CULTURES_CSV_IN_CONTAINER = $(PATH_IN_CONTAINER)/l10n/cultures.csv

L10N_FILES = l10n/custom-data-type-gvk.csv
L10N_FILES_IN_CONTAINER = $(PATH_IN_CONTAINER)/l10n/custom-data-type-gvk.csv

JS_FILE = build/webfrontend/custom-data-type-gvk.js

all: library ${JS_FILE} build-stamp-l10n

library:
	mkdir -p src/library
	wget -O src/library/commons.coffee https://raw.githubusercontent.com/programmfabrik/easydb-library/master/src/commons.coffee

clean:
	rm -f src/webfrontend/*.coffee.js
	rm -f build-stamp-l10n
	rm -rf build/

build-stamp-l10n: $(L10N_FILES) $(CULTURES_CSV)
	mkdir -p build/webfrontend/l10n
	$(L10N2JSON) $(CULTURES_CSV_IN_CONTAINER) $(L10N_FILES_IN_CONTAINER) $(PATH_IN_CONTAINER)/build/webfrontend/l10n/
	touch $@

${JS_FILE}: src/library/commons.coffee.js src/webfrontend/CustomDataTypeGVK.coffee.js
	mkdir -p build/webfrontend
	cat $^ > $@

%.coffee.js: %.coffee
	coffee -b -p --compile "$^" > "$@" || ( rm -f "$@" ; false )

.PHONY: clean
