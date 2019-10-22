PLUGIN_NAME = custom-data-type-gvk

L10N_FILES = easydb-library/src/commons.l10n.csv \
    l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1ux8r_kpskdAwTaTjqrk92up5eyyILkpsv4k96QltmI0
L10N_GOOGLE_GID = 1040395818
L10N2JSON = python easydb-library/tools/l10n2json.py

INSTALL_FILES = \
    $(WEB)/l10n/cultures.json \
    $(WEB)/l10n/de-DE.json \
    $(WEB)/l10n/en-US.json \
    $(JS) \
    $(CSS) \
    CustomDataTypeGVK.config.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
    src/webfrontend/CustomDataTypeGVK.coffee

CSS_FILE = src/webfrontend/css/main.css

all: build

include easydb-library/tools/base-plugins.make

build:	code
				mkdir -p build/webfrontend/css
				cat $(CSS_FILE) >> build/webfrontend/custom-data-type-gvk.css

code: $(JS) $(L10N)

clean: clean-base
