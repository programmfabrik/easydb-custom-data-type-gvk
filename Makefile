PLUGIN_NAME = custom-data-type-gvk
PLUGIN_PATH = easydb-custom-data-type-gvk

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv

INSTALL_FILES = \
    $(WEB)/l10n/cultures.json \
    $(WEB)/l10n/de-DE.json \
    $(WEB)/l10n/en-US.json \
    $(JS) \
    $(CSS) \
    manifest.yml \
    build/updater/gvk-update.js

COFFEE_FILES = easydb-library/src/commons.coffee \
    src/webfrontend/CustomDataTypeGVK.coffee

UPDATE_SCRIPT_COFFEE_FILES = \
	src/updater/GVKUpdate.coffee

CSS_FILE = src/webfrontend/css/main.css

all: build

include easydb-library/tools/base-plugins.make

build:	code buildupdater buildinfojson
				mkdir -p build/webfrontend/css
				cat $(CSS_FILE) >> build/webfrontend/custom-data-type-gvk.css

buildupdater: $(subst .coffee,.coffee.js,${UPDATE_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/gvk-update.js

code: $(JS) $(L10N)

clean: clean-base

wipe: wipe-base

.PHONY: clean wipe
