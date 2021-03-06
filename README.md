> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# easydb-custom-data-type-gvk

This is a plugin for [easyDB 5](http://5.easydb.de/) with Custom Data Type `CustomDataTypeGVK` for references to entities of the [Gemeinsame Datenbank k10plus](https://kxp.k10plus.de/).

The Plugins uses <https://ws.gbv.de/suggest/csl2/> for the autocomplete-suggestions.

## configuration

* mask config:
    * useCustomDatabases - example: "VD17=1.28|VD18=1.65|"

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* _fulltext
    * easydb-fulltext
* _standard
    * easydb-standard

## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-gvk>. Please use [the issue tracker](https://github.com/programmfabrik/easydb-custom-data-type-gvk/issues) for bug reports and feature requests!
