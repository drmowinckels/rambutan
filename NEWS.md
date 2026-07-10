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
