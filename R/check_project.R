#' Check links found across an entire project directory
#'
#' Convenience wrapper around [check_paths()] for scanning a whole project
#' tree, recursively, while skipping directories that are virtually never
#' meant to be link-checked -- installed dependencies and build artifacts.
#' Hidden files and directories (e.g. `.git`, `.Rproj.user`) are always
#' skipped. Unlike [check_package()], `check_project()` makes no assumption
#' that `path` is an R package.
#'
#' @param path Path to the root of the project to scan. Defaults to the
#'   current directory.
#' @param exclude_dirs Character vector of directory names to skip
#'   anywhere in the tree, in addition to hidden directories, which are
#'   always skipped. Defaults to common dependency and build-artifact
#'   directories (`node_modules`, `renv`, `packrat`, `target`, `dist`,
#'   `build`, `vendor`).
#' @param options A `lychee_options` object created by [lychee_options()].
#' @return A data frame with one row per discovered link: `source`, `line`,
#'   `column`, `url`, `is_success`, `code`, `details`.
#' @export
#' @examples
#' \dontrun{
#' check_project(".")
#' }
check_project <- function(
  path = ".",
  exclude_dirs = c(
    "node_modules",
    "renv",
    "packrat",
    "target",
    "dist",
    "build",
    "vendor"
  ),
  options = lychee_options()
) {
  stopifnot(
    "`path` must be a single path" = is.character(path) && length(path) == 1L,
    "`exclude_dirs` must be a character vector" = is.character(exclude_dirs),
    "`exclude_dirs` must not contain empty strings" = all(nzchar(
      exclude_dirs
    )),
    inherits(options, "lychee_options")
  )

  if (!dir.exists(path)) {
    stop("`path` is not an existing directory: '", path, "'", call. = FALSE)
  }

  files <- list_files_excluding(path, exclude_dirs)
  check_paths(files, options = options)
}
