# Check links found in every file within a folder

Convenience wrapper around
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md)
for scanning a directory. By default the whole directory tree is
scanned, exactly like `check_paths(path)`. Set `recursive = FALSE` to
scan only the files directly inside `path`, or `extensions` to restrict
the scan to files with the given extensions; both are implemented as
glob patterns handed to
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md),
so hidden files/directories and anything matched by a `.gitignore` are
skipped in every case, same as the 'lychee' CLI.

## Usage

``` r
check_folder(
  path,
  recursive = TRUE,
  extensions = NULL,
  options = lychee_options()
)
```

## Arguments

- path:

  Path to a single existing directory to scan for links.

- recursive:

  Single logical. Scan subdirectories as well? Defaults to `TRUE`.

- extensions:

  Character vector of file extensions (with or without the leading dot,
  e.g. `c("md", "html")`) to restrict the scan to, or `NULL` to scan
  every file lychee can extract links from.

- options:

  A `lychee_options` object created by
  [`lychee_options()`](http://drmowinckels.io/rambutan/reference/lychee_options.md).

## Value

A data frame with one row per discovered link: `source`, `line`,
`column`, `url`, `is_success`, `code`, `details`.

## Examples

``` r
if (FALSE) { # \dontrun{
check_folder("vignettes")
check_folder("vignettes", recursive = FALSE)
check_folder(".", extensions = "md")
} # }
```
