# `tools:::url_db_from_package_sources()` implements the exact file scan
# `R CMD check --as-cran` and CRAN's incoming checks run for "Checking URLs"
# (DESCRIPTION, man/*.Rd, CITATION, NEWS.Rd/NEWS.md, README.md, built HTML
# vignettes). It has no exported public interface, so we reach into the
# namespace the same way the CRAN package `urlchecker` does. `tools` has
# shipped this function since R 4.1, well below this package's R (>= 4.2)
# floor.
url_db_from_package <- function(path) {
  tools_internal <- asNamespace("tools")
  db <- tools_internal$url_db_from_package_sources(path)
  db <- rbind(db, url_db_from_package_vignettes(path))
  row.names(db) <- NULL
  db
}

# `url_db_from_package_sources()` only covers built HTML vignettes
# (inst/doc/*.html). Unbuilt vignettes/*.Rmd sources are missed unless the
# package has already been built, so render them to HTML with pandoc and
# scan those too, mirroring urlchecker::url_db_from_package_rmd_vignettes().
url_db_from_package_vignettes <- function(path) {
  docs <- Filter(file.exists, tools::pkgVignettes(dir = path)$docs)

  urls <- character()
  parents <- character()

  if (
    length(docs) &&
      nzchar(Sys.which("pandoc")) &&
      requireNamespace("xml2", quietly = TRUE)
  ) {
    for (doc in docs) {
      doc_urls <- url_from_rmd_vignette(doc)
      if (length(doc_urls)) {
        urls <- c(urls, doc_urls)
        parents <- c(
          parents,
          rep.int(relative_path(doc, path), length(doc_urls))
        )
      }
    }
  }

  data.frame(URL = urls, Parent = parents, stringsAsFactors = FALSE)
}

url_from_rmd_vignette <- function(doc) {
  html_file <- tempfile(fileext = ".html")
  on.exit(unlink(html_file))

  status <- system2(
    "pandoc",
    c(
      shQuote(normalizePath(doc)),
      "-s",
      "--mathjax",
      "--email-obfuscation=references",
      "-f",
      "markdown+autolink_bare_uris",
      "-o",
      shQuote(html_file)
    ),
    stdout = FALSE,
    stderr = FALSE
  )
  if (status != 0) {
    return(character())
  }

  extract_urls_from_html(html_file)
}

extract_urls_from_html <- function(file) {
  doc <- xml2::read_html(file)
  nodes <- xml2::xml_find_all(doc, "//a")
  hrefs <- xml2::xml_attr(nodes, "href")
  unique(hrefs[!is.na(hrefs) & !startsWith(hrefs, "#")])
}

relative_path <- function(x, dir) {
  dir <- sub("/+$", "", dir)
  ifelse(startsWith(x, dir), substring(x, nchar(dir) + 2L), x)
}
