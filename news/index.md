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
- Added
  [`check_file()`](http://drmowinckels.io/rambutan/reference/check_file.md),
  [`check_folder()`](http://drmowinckels.io/rambutan/reference/check_folder.md),
  and
  [`check_project()`](http://drmowinckels.io/rambutan/reference/check_project.md)
  as convenience wrappers around
  [`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md):
  [`check_file()`](http://drmowinckels.io/rambutan/reference/check_file.md)
  validates a single file,
  [`check_folder()`](http://drmowinckels.io/rambutan/reference/check_folder.md)
  adds `recursive` and `extensions` options for scanning a directory,
  and
  [`check_project()`](http://drmowinckels.io/rambutan/reference/check_project.md)
  recursively scans a whole project directory while skipping dependency
  and build-artifact directories (`node_modules`, `renv`, `packrat`,
  `target`, `dist`, `build`, `vendor`) as well as hidden directories.
- Fixed a Windows-only crash (`STATUS_STACK_BUFFER_OVERRUN`) that hit
  the R process after a rambutan call had already completed and returned
  its result, caused by the `aws-lc-rs` TLS crypto backend’s teardown at
  DLL/process exit. rambutan now installs rustls’s `ring` provider
  before building its HTTP client, avoiding the crash.
