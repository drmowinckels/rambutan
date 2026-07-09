#' Check a single URL
#'
#' @param url A single URL string to check.
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A list with `url`, `is_success`, `code`, and `details`.
#' @export
#' @examples
#' \dontrun{
#' check_url("https://www.r-project.org")
#' }
check_url <- function(url, options = lychee_options()) {
  stopifnot(
    is.character(url),
    length(url) == 1L,
    inherits(options, "lychee_options")
  )

  args <- lychee_options_impl_args(options)
  do.call(check_url_impl, c(list(url = url), args))
}

#' Check multiple URLs concurrently
#'
#' Vectorised version of [check_url()]. URLs are checked concurrently rather
#' than one at a time.
#'
#' @param urls Character vector of URLs to check.
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A data frame with one row per element of `urls` (in the same
#'   order): `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_urls(c("https://www.r-project.org", "https://cran.r-project.org"))
#' }
check_urls <- function(urls, options = lychee_options()) {
  stopifnot(is.character(urls), inherits(options, "lychee_options"))

  args <- lychee_options_impl_args(options)
  res <- do.call(check_urls_impl, c(list(urls = urls), args))
  data.frame(
    url = urls,
    is_success = res$is_success,
    code = res$code,
    details = res$details,
    stringsAsFactors = FALSE
  )
}

#' Check links found in files, directories, or glob patterns
#'
#' Scans the given paths for links using 'lychee's built-in Markdown, HTML,
#' and plain-text extractors, then checks every link found.
#'
#' @param paths Character vector of file paths, directories, or glob
#'   patterns (e.g. `"**/*.md"`) to scan for links.
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A data frame with one row per discovered link: `source`, `line`,
#'   `column`, `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_paths("README.md")
#' check_paths(c("README.md", "vignettes"))
#' }
check_paths <- function(paths, options = lychee_options()) {
  stopifnot(is.character(paths), inherits(options, "lychee_options"))

  args <- lychee_options_impl_args(options)
  res <- do.call(check_paths_impl, c(list(paths = paths), args))
  as.data.frame(res, stringsAsFactors = FALSE)
}
