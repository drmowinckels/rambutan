# Check multiple URLs concurrently

Vectorised version of
[`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md).
URLs are checked concurrently rather than one at a time.

## Usage

``` r
check_urls(urls, options = lychee_options())
```

## Arguments

- urls:

  Character vector of URLs to check.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per element of `urls` (in the same order):
`url`, `is_success`, `code`, `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_urls(c("https://www.r-project.org", "https://cran.r-project.org"))
} # }
```
