# rambutan (development version)

- Added `check_url()`, `check_urls()`, and `check_paths()`, wrapping
  `lychee-lib` via extendr to check single URLs, vectors of URLs
  concurrently, and links discovered in files, directories, or glob
  patterns.
- Added `check_package()` to scan an R package's `DESCRIPTION`, Rd files,
  `NEWS`, `CITATION`, and vignettes for URLs -- mirroring CRAN's own URL
  check -- and check each one found.
- Added `lychee_options()` to configure retries, timeouts, redirects,
  excluded/included URL patterns, and other `lychee-lib` behaviour shared
  by `check_url()`, `check_urls()`, `check_paths()`, and `check_package()`.
  Options can also be read from a `lychee.toml` file in the working
  directory.
- Added `check_file()`, `check_folder()`, and `check_project()` as
  convenience wrappers around `check_paths()`: `check_file()` validates a
  single file, `check_folder()` adds `recursive` and `extensions` options
  for scanning a directory, and `check_project()` recursively scans a
  whole project directory while skipping dependency and build-artifact
  directories (`node_modules`, `renv`, `packrat`, `target`, `dist`,
  `build`, `vendor`) as well as hidden directories.
