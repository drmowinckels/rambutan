# Check links found across an entire project directory

Convenience wrapper around
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md)
for scanning a whole project tree, recursively, while skipping
directories that are virtually never meant to be link-checked –
installed dependencies and build artifacts. Hidden files and directories
(e.g. `.git`, `.Rproj.user`) are always skipped. Unlike
[`check_package()`](http://drmowinckels.io/rambutan/reference/check_package.md),
`check_project()` makes no assumption that `path` is an R package.

## Usage

``` r
check_project(
  path = ".",
  exclude_dirs = c("node_modules", "renv", "packrat", "target", "dist", "build",
    "vendor"),
  options = lychee_options()
)
```

## Arguments

- path:

  Path to the root of the project to scan. Defaults to the current
  directory.

- exclude_dirs:

  Character vector of directory names to skip anywhere in the tree, in
  addition to hidden directories, which are always skipped. Defaults to
  common dependency and build-artifact directories (`node_modules`,
  `renv`, `packrat`, `target`, `dist`, `build`, `vendor`).

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per discovered link: `source`, `line`,
`column`, `url`, `is_success`, `code`, `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_project(".")
} # }
```
