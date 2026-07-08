#' Check multiple URLs concurrently
#'
#' Vectorised version of [check_url()]. URLs are checked concurrently rather
#' than one at a time.
#'
#' @param urls Character vector of URLs to check.
#' @param excludes Character vector of regular expressions. URLs matching
#'   any pattern are treated as excluded rather than checked.
#' @return A data frame with one row per element of `urls` (in the same
#'   order): `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_urls(c("https://www.r-project.org", "https://cran.r-project.org"))
#' }
check_urls <- function(urls, excludes = character()) {
  stopifnot(is.character(urls), is.character(excludes))

  res <- check_urls_impl(urls, excludes)
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
#' @param excludes Character vector of regular expressions. URLs matching
#'   any pattern are treated as excluded rather than checked.
#' @return A data frame with one row per discovered link: `source`, `line`,
#'   `column`, `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_paths("README.md")
#' check_paths(c("README.md", "vignettes"))
#' }
check_paths <- function(paths, excludes = character()) {
  stopifnot(is.character(paths), is.character(excludes))

  res <- check_paths_impl(paths, excludes)
  as.data.frame(res, stringsAsFactors = FALSE)
}
