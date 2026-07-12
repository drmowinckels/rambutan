# Check links found in a single file

Convenience wrapper around
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md)
for the common case of scanning one file, with a clearer error when
`file` doesn't exist or is a directory.

## Usage

``` r
check_file(file, options = lychee_options())
```

## Arguments

- file:

  Path to a single existing file to scan for links.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per discovered link: `source`, `line`,
`column`, `url`, `is_success`, `code`, `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_file("README.md")
} # }
```
