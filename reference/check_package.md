# Check every URL referenced in an R package's sources

Scans the same files CRAN's automated URL checks (and
`R CMD check --as-cran`) inspect – `DESCRIPTION`, Rd files in `man/`,
`CITATION`, `NEWS.Rd`/`NEWS.md`, `README.md`, and built HTML vignettes –
plus unbuilt R Markdown vignette sources, then checks every URL found
with
[`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md).

## Usage

``` r
check_package(path = ".", options = lychee_options())
```

## Arguments

- path:

  Path to the root of an R package's source tree. Defaults to the
  current directory.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per checked URL: `url`, `parent` (the file the
URL was found in), `is_success`, `code`, and `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_package(".")
} # }
```
