# tests
This folder contains all the sysbench test files used for the benchmarks.

`common.inc` is a special file containing functions that are common to all tests.

`provision.prov` is used to set up a database for test data. This is then used in the test files to generate test data relevant for the benchmark in question.

`first_names.txt` and `last_names.txt` are used to generate random names for people. The original files can be found [here](https://github.com/enorvelle/NameDatabases). The data contained has been cleaned to ensure flawless SQL inserts.
