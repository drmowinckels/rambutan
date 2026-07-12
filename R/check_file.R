#' Check links found in a single file
#'
#' Convenience wrapper around [check_paths()] for the common case of
#' scanning one file, with a clearer error when `file` doesn't exist or is
#' a directory.
#'
#' @param file Path to a single existing file to scan for links.
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A data frame with one row per discovered link: `source`, `line`,
#'   `column`, `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_file("README.md")
#' }
check_file <- function(file, options = lychee_options()) {
  stopifnot(
    "`file` must be a single path" = is.character(file) && length(file) == 1L,
    inherits(options, "lychee_options")
  )

  if (dir.exists(file)) {
    stop(
      "`file` is a directory, not a file: '",
      file,
      "'. Use check_folder() instead.",
      call. = FALSE
    )
  }
  if (!file.exists(file)) {
    stop("`file` does not exist: '", file, "'", call. = FALSE)
  }

  check_paths(file, options = options)
}
