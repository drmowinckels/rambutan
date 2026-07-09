#' Configure optional lychee behaviour
#'
#' Builds the options object accepted by [check_url()], [check_urls()],
#' [check_paths()], and [check_package()]. Every argument here shares its
#' name with the matching field in a `lychee.toml` file -- the same
#' configuration file read by the 'lychee' CLI. When a `lychee.toml` is
#' present in the current working directory it is picked up automatically;
#' values passed here take precedence over the file, the file takes
#' precedence over 'lychee-lib's own defaults, and `exclude`/`include`/
#' `header` are combined with the file rather than replacing it.
#'
#' @param exclude Character vector of regular expressions. URLs matching
#'   any pattern are treated as excluded rather than checked.
#' @param include Character vector of regular expressions. URLs matching
#'   any pattern are always checked, even if they also match `exclude`.
#' @param timeout Request timeout in seconds, or `NULL` to use the default
#'   (20).
#' @param max_redirects Maximum number of redirects to follow, or `NULL`
#'   to use the default (10).
#' @param max_retries Maximum number of retries per request, or `NULL` to
#'   use the default (3).
#' @param retry_wait_time Initial wait time in seconds between retries, or
#'   `NULL` to use the default (1).
#' @param user_agent User agent string sent with every request, or `NULL`
#'   to use lychee's default.
#' @param method A single HTTP method, e.g. `"get"` or `"head"`, or `NULL`
#'   to use the default (`"get"`).
#' @param accept Character vector of accepted status codes/ranges, e.g.
#'   `c("200..=204", "429")`. Defaults to lychee's own accepted range
#'   when empty.
#' @param exclude_all_private Single logical. Exclude all private,
#'   link-local, and loopback IP addresses, or `NULL`.
#' @param exclude_private Single logical. Exclude private IP addresses,
#'   or `NULL`.
#' @param exclude_link_local Single logical. Exclude link-local IP
#'   addresses, or `NULL`.
#' @param exclude_loopback Single logical. Exclude loopback IP addresses,
#'   or `NULL`.
#' @param require_https Single logical. Treat unencrypted HTTP links as
#'   errors when HTTPS is available, or `NULL`.
#' @param include_mail Single logical. Also check `mailto:` links, or
#'   `NULL`.
#' @param header Named character vector of custom HTTP headers sent with
#'   every request, or `NULL`.
#' @return A list with class `lychee_options`.
#' @export
#' @examples
#' lychee_options(timeout = 10, exclude = "^https://example\\.com")
lychee_options <- function(
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
) {
  is_null_or_scalar <- function(x, type) {
    is.null(x) ||
      (length(x) == 1L &&
        !is.na(x) &&
        switch(
          type,
          character = is.character(x),
          numeric = is.numeric(x),
          logical = is.logical(x)
        ))
  }

  stopifnot(
    "`exclude` must be a character vector" = is.character(exclude),
    "`include` must be a character vector" = is.character(include),
    "`timeout` must be a single number or NULL" = is_null_or_scalar(
      timeout,
      "numeric"
    ),
    "`max_redirects` must be a single number or NULL" = is_null_or_scalar(
      max_redirects,
      "numeric"
    ),
    "`max_retries` must be a single number or NULL" = is_null_or_scalar(
      max_retries,
      "numeric"
    ),
    "`retry_wait_time` must be a single number or NULL" = is_null_or_scalar(
      retry_wait_time,
      "numeric"
    ),
    "`user_agent` must be a single string or NULL" = is_null_or_scalar(
      user_agent,
      "character"
    ),
    "`method` must be a single string or NULL" = is_null_or_scalar(
      method,
      "character"
    ),
    "`accept` must be a character vector" = is.character(accept),
    "`exclude_all_private` must be a single logical or NULL" = is_null_or_scalar(
      exclude_all_private,
      "logical"
    ),
    "`exclude_private` must be a single logical or NULL" = is_null_or_scalar(
      exclude_private,
      "logical"
    ),
    "`exclude_link_local` must be a single logical or NULL" = is_null_or_scalar(
      exclude_link_local,
      "logical"
    ),
    "`exclude_loopback` must be a single logical or NULL" = is_null_or_scalar(
      exclude_loopback,
      "logical"
    ),
    "`require_https` must be a single logical or NULL" = is_null_or_scalar(
      require_https,
      "logical"
    ),
    "`include_mail` must be a single logical or NULL" = is_null_or_scalar(
      include_mail,
      "logical"
    ),
    "`header` must be a named character vector or NULL" = is.null(header) ||
      (is.character(header) &&
        !is.null(names(header)) &&
        all(nzchar(names(header))))
  )

  structure(
    list(
      exclude = exclude,
      include = include,
      timeout = timeout,
      max_redirects = max_redirects,
      max_retries = max_retries,
      retry_wait_time = retry_wait_time,
      user_agent = user_agent,
      method = method,
      accept = accept,
      exclude_all_private = exclude_all_private,
      exclude_private = exclude_private,
      exclude_link_local = exclude_link_local,
      exclude_loopback = exclude_loopback,
      require_https = require_https,
      include_mail = include_mail,
      header = header
    ),
    class = "lychee_options"
  )
}

#' Flatten a `lychee_options` object into the positional arguments expected
#' by the Rust `*_impl()` bridge functions.
#' @noRd
lychee_options_impl_args <- function(options) {
  stopifnot(inherits(options, "lychee_options"))

  header <- options$header
  list(
    exclude = options$exclude,
    include = options$include,
    timeout = options$timeout,
    max_redirects = options$max_redirects,
    max_retries = options$max_retries,
    retry_wait_time = options$retry_wait_time,
    user_agent = options$user_agent,
    method = options$method,
    accept = options$accept,
    exclude_all_private = options$exclude_all_private,
    exclude_private = options$exclude_private,
    exclude_link_local = options$exclude_link_local,
    exclude_loopback = options$exclude_loopback,
    require_https = options$require_https,
    include_mail = options$include_mail,
    header_names = if (is.null(header)) character() else names(header),
    header_values = if (is.null(header)) character() else unname(header)
  )
}
