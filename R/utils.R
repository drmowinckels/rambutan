#' Recursively list files under `path`, never descending into a directory
#' whose basename is in `exclude_dirs`. Hidden files/directories are always
#' skipped, matching `list.files()`'s own default.
#' @noRd
list_files_excluding <- function(path, exclude_dirs) {
  entries <- list.files(path, full.names = TRUE)
  is_dir <- dir.exists(entries)
  dirs <- entries[is_dir & !(basename(entries) %in% exclude_dirs)]
  files <- entries[!is_dir]

  c(
    files,
    unlist(lapply(dirs, list_files_excluding, exclude_dirs = exclude_dirs))
  )
}
