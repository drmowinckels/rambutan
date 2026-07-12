#' Check links found in every file within a folder
#'
#' Convenience wrapper around [check_paths()] for scanning a directory. By
#' default the whole directory tree is scanned, exactly like
#' `check_paths(path)`. Set `recursive = FALSE` to scan only the files
#' directly inside `path`, or `extensions` to restrict the scan to files
#' with the given extensions; both are implemented as glob patterns handed
#' to [check_paths()], so hidden files/directories and anything matched by
#' a `.gitignore` are skipped in every case, same as the 'lychee' CLI.
#'
#' @param path Path to a single existing directory to scan for links.
#' @param recursive Single logical. Scan subdirectories as well? Defaults
#'   to `TRUE`.
#' @param extensions Character vector of file extensions (with or without
#'   the leading dot, e.g. `c("md", "html")`) to restrict the scan to, or
#'   `NULL` to scan every file lychee can extract links from.
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A data frame with one row per discovered link: `source`, `line`,
#'   `column`, `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_folder("vignettes")
#' check_folder("vignettes", recursive = FALSE)
#' check_folder(".", extensions = "md")
#' }
check_folder <- function(
  path,
  recursive = TRUE,
  extensions = NULL,
  options = lychee_options()
) {
  stopifnot(
    "`path` must be a single path" = is.character(path) && length(path) == 1L,
    "`recursive` must be a single logical" = is.logical(recursive) &&
      length(recursive) == 1L &&
      !is.na(recursive),
    "`extensions` must be a character vector or NULL" = is.null(extensions) ||
      is.character(extensions),
    "`extensions` must not contain empty strings" = is.null(extensions) ||
      all(nzchar(sub("^\\.", "", extensions))),
    inherits(options, "lychee_options")
  )

  if (file.exists(path) && !dir.exists(path)) {
    stop(
      "`path` is a file, not a directory: '",
      path,
      "'. Use check_file() instead.",
      call. = FALSE
    )
  }
  if (!dir.exists(path)) {
    stop("`path` is not an existing directory: '", path, "'", call. = FALSE)
  }

  if (is.null(extensions) && recursive) {
    return(check_paths(path, options = options))
  }

  suffixes <- if (is.null(extensions)) {
    "*"
  } else {
    paste0("*.", sub("^\\.", "", extensions))
  }
  globs <- if (recursive) {
    file.path(path, "**", suffixes)
  } else {
    file.path(path, suffixes)
  }

  check_paths(globs, options = options)
}
