# Check a single URL

Check a single URL

## Usage

``` r
check_url(url, options = lychee_options())
```

## Arguments

- url:

  A single URL string to check.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A list with `url`, `is_success`, `code`, and `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_url("https://www.r-project.org")
} # }
```
