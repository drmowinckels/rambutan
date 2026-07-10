# Configure optional lychee behaviour

Builds the options object accepted by
[`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md),
[`check_urls()`](http://drmowinckels.io/rambutan/reference/check_urls.md),
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md),
and
[`check_package()`](http://drmowinckels.io/rambutan/reference/check_package.md).
Every argument here shares its name with the matching field in a
`lychee.toml` file – the same configuration file read by the 'lychee'
CLI. When a `lychee.toml` is present in the current working directory it
is picked up automatically; values passed here take precedence over the
file, the file takes precedence over 'lychee-lib's own defaults, and
`exclude`/`include`/ `header` are combined with the file rather than
replacing it.

## Usage

``` r
lychee_options(
  exclude = character(),
  include = character(),
  timeout = NULL,
  max_redirects = NULL,
  max_retries = NULL,
  retry_wait_time = NULL,
  user_agent = NULL,
  method = NULL,
  accept = character(),
  exclude_all_private = NULL,
  exclude_private = NULL,
  exclude_link_local = NULL,
  exclude_loopback = NULL,
  require_https = NULL,
  include_mail = NULL,
  header = NULL
)
```

## Arguments

- exclude:

  Character vector of regular expressions. URLs matching any pattern are
  treated as excluded rather than checked.

- include:

  Character vector of regular expressions. URLs matching any pattern are
  always checked, even if they also match `exclude`.

- timeout:

  Request timeout in seconds, or `NULL` to use the default (20).

- max_redirects:

  Maximum number of redirects to follow, or `NULL` to use the default
  (10).

- max_retries:

  Maximum number of retries per request, or `NULL` to use the default
  (3).

- retry_wait_time:

  Initial wait time in seconds between retries, or `NULL` to use the
  default (1).

- user_agent:

  User agent string sent with every request, or `NULL` to use lychee's
  default.

- method:

  A single HTTP method, e.g. `"get"` or `"head"`, or `NULL` to use the
  default (`"get"`).

- accept:

  Character vector of accepted status codes/ranges, e.g.
  `c("200..=204", "429")`. Defaults to lychee's own accepted range when
  empty.

- exclude_all_private:

  Single logical. Exclude all private, link-local, and loopback IP
  addresses, or `NULL`.

- exclude_private:

  Single logical. Exclude private IP addresses, or `NULL`.

- exclude_link_local:

  Single logical. Exclude link-local IP addresses, or `NULL`.

- exclude_loopback:

  Single logical. Exclude loopback IP addresses, or `NULL`.

- require_https:

  Single logical. Treat unencrypted HTTP links as errors when HTTPS is
  available, or `NULL`.

- include_mail:

  Single logical. Also check `mailto:` links, or `NULL`.

- header:

  Named character vector of custom HTTP headers sent with every request,
  or `NULL`.

## Value

A list with class `lychee_options`.

## Examples

``` r
lychee_options(timeout = 10, exclude = "^https://example\\.com")
#> $exclude
#> [1] "^https://example\\.com"
#> 
#> $include
#> character(0)
#> 
#> $timeout
#> [1] 10
#> 
#> $max_redirects
#> NULL
#> 
#> $max_retries
#> NULL
#> 
#> $retry_wait_time
#> NULL
#> 
#> $user_agent
#> NULL
#> 
#> $method
#> NULL
#> 
#> $accept
#> character(0)
#> 
#> $exclude_all_private
#> NULL
#> 
#> $exclude_private
#> NULL
#> 
#> $exclude_link_local
#> NULL
#> 
#> $exclude_loopback
#> NULL
#> 
#> $require_https
#> NULL
#> 
#> $include_mail
#> NULL
#> 
#> $header
#> NULL
#> 
#> attr(,"class")
#> [1] "lychee_options"
```
