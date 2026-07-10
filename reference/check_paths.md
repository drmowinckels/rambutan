# Check links found in files, directories, or glob patterns

Scans the given paths for links using 'lychee's built-in Markdown, HTML,
and plain-text extractors, then checks every link found.

## Usage

``` r
check_paths(paths, options = lychee_options())
```

## Arguments

- paths:

  Character vector of file paths, directories, or glob patterns (e.g.
  `"**/*.md"`) to scan for links.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per discovered link: `source`, `line`,
`column`, `url`, `is_success`, `code`, `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_paths("README.md")
check_paths(c("README.md", "vignettes"))
} # }
```
