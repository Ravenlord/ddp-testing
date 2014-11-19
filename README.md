ddp-testing
===========

Repository containing benchmark testing/automation for my Master's Thesis.

If you want to rerun the benchmarks on a Debian-based system, just check out this repository and run `make` as root or `sudo make`. Elevated privileges are necessary to perform package installations.

**Important**: If you have MariaDB/MySQL already installed and don't want to mess it up, don't run the `all` target. Use `make install-sysbench` to install sysbench >= version 0.5 (if you don't have it already). `make benchmark` will then run all the benchmarks.

## Targets

- `all`: Installs MariaDB (including a custom configuration) and sybench and will run all the benchmarks, saving the results into the directory `results`.
- `benchmark`: Executes all benchmarks in the `tests` directory and saves the results into the `results` directory.
- `clean`: Uninstalls all packages installed by `install-all` and purges their configuration directories. Also removes the `results` directory and MariaDB/sysbench package sources.
- `install-all`: Installs MariaDB (including a custom configuration) and sybench.
- `install-mariadb`: Installs MariaDB (including a custom configuration).
- `install-sysbench`: Installs the most recent version of sysbench.
- `update`: Updates the system.
