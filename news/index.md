# Changelog

## rambutan (development version)

- Added
  [`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md),
  [`check_urls()`](http://drmowinckels.io/rambutan/reference/check_urls.md),
  and
  [`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md),
  wrapping `lychee-lib` via extendr to check single URLs, vectors of
  URLs concurrently, and links discovered in files, directories, or glob
  patterns.
- Added
  [`check_package()`](http://drmowinckels.io/rambutan/reference/check_package.md)
  to scan an R package’s `DESCRIPTION`, Rd files, `NEWS`, `CITATION`,
  and vignettes for URLs – mirroring CRAN’s own URL check – and check
  each one found.
- Added
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md)
  to configure retries, timeouts, redirects, excluded/included URL
  patterns, and other `lychee-lib` behaviour shared by
  [`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md),
  [`check_urls()`](http://drmowinckels.io/rambutan/reference/check_urls.md),
  [`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md),
  and
  [`check_package()`](http://drmowinckels.io/rambutan/reference/check_package.md).
  Options can also be read from a `lychee.toml` file in the working
  directory.
