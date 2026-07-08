#' Check every URL referenced in an R package's sources
#'
#' Scans the same files CRAN's automated URL checks (and
#' `R CMD check --as-cran`) inspect -- `DESCRIPTION`, Rd files in `man/`,
#' `CITATION`, `NEWS.Rd`/`NEWS.md`, `README.md`, and built HTML vignettes --
#' plus unbuilt R Markdown vignette sources, then checks every URL found
#' with [check_url()].
#'
#' @param path Path to the root of an R package's source tree. Defaults to
#'   the current directory.
#' @return A data frame with one row per checked URL: `url`, `parent` (the
#'   file the URL was found in), `is_success`, `code`, and `details`.
#' @export
#' @examples
#' \dontrun{
#' check_package(".")
#' }
check_package <- function(path = ".") {
  path <- normalizePath(path, mustWork = TRUE)

  if (!file.exists(file.path(path, "DESCRIPTION"))) {
    stop(
      "`path` does not look like an R package: no DESCRIPTION file found.",
      call. = FALSE
    )
  }

  db <- url_db_from_package(path)

  if (nrow(db) == 0L) {
    return(data.frame(
      url = character(),
      parent = character(),
      is_success = logical(),
      code = integer(),
      details = character(),
      stringsAsFactors = FALSE
    ))
  }

  checked <- lapply(unique(db$URL), check_url)
  checked <- do.call(
    rbind,
    lapply(checked, as.data.frame, stringsAsFactors = FALSE)
  )

  out <- merge(
    data.frame(url = db$URL, parent = db$Parent, stringsAsFactors = FALSE),
    checked,
    by = "url"
  )
  out[order(out$parent, out$url), , drop = FALSE]
}
