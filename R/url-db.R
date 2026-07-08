# Mirrors the file set `R CMD check --as-cran` and CRAN's incoming checks
# scan for the "Checking URLs" step (DESCRIPTION, man/*.Rd, CITATION,
# NEWS.Rd/NEWS.md, README.md, built HTML vignettes), plus unbuilt
# vignettes/*.Rmd sources like urlchecker adds. Built only from exported,
# public APIs (tools::, desc::, utils::, xml2::) -- never a package's
# non-exported internals.
url_db_from_package <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)

  parts <- list(
    url_db_from_description(path),
    url_db_from_rd_files(path),
    url_db_from_news_rd(path),
    url_db_from_citation(path),
    url_db_from_markdown_file(path, "README.md", extensions = character()),
    url_db_from_markdown_file(path, "NEWS.md", extensions = character()),
    url_db_from_built_vignettes(path),
    url_db_from_package_vignettes(path)
  )

  db <- do.call(rbind, parts)
  row.names(db) <- NULL
  db
}

url_db_from_description <- function(path) {
  d <- desc::desc(file = path)

  fields <- c("URL", "BugReports", "Description")
  urls <- unique(unlist(
    lapply(fields, function(f) extract_bare_urls(d$get_field(f, default = ""))),
    use.names = FALSE
  ))

  data.frame(
    URL = urls,
    Parent = rep.int("DESCRIPTION", length(urls)),
    stringsAsFactors = FALSE
  )
}

extract_bare_urls <- function(text) {
  m <- gregexpr("(https?|ftp)://[^[:space:]<>\"']+", text)
  urls <- regmatches(text, m)[[1L]]
  sub("[.,;:)]+$", "", urls)
}

url_db_from_rd_files <- function(path) {
  rd_db <- tools::Rd_db(dir = path)

  urls <- character()
  parents <- character()
  for (name in names(rd_db)) {
    doc_urls <- urls_from_rd(rd_db[[name]])
    if (length(doc_urls)) {
      urls <- c(urls, doc_urls)
      parents <- c(parents, rep.int(file.path("man", name), length(doc_urls)))
    }
  }

  data.frame(URL = urls, Parent = parents, stringsAsFactors = FALSE)
}

url_db_from_news_rd <- function(path) {
  file <- first_existing(file.path(
    path,
    c("NEWS.Rd", file.path("inst", "NEWS.Rd"))
  ))
  if (is.na(file)) {
    return(empty_url_db())
  }

  urls <- urls_from_rd(tools::parse_Rd(file))
  data.frame(
    URL = urls,
    Parent = rep.int(relative_path(file, path), length(urls)),
    stringsAsFactors = FALSE
  )
}

# `\url{...}` and `\href{url}{text}` are documented Rd markup tags; walking
# the public tools::parse_Rd()/tools::Rd_db() parse tree by its `Rd_tag`
# attribute is how e.g. Rd2HTML-style tooling has always read Rd content.
urls_from_rd <- function(rd) {
  urls <- character()
  walk <- function(e) {
    tag <- attr(e, "Rd_tag")
    if (identical(tag, "\\url") || identical(tag, "\\href")) {
      urls <<- c(urls, trimws(rd_leaf_text(e[[1L]])))
    } else if (is.list(e)) {
      lapply(e, walk)
    }
  }
  lapply(rd, walk)
  unique(urls)
}

rd_leaf_text <- function(x) {
  if (is.character(x)) {
    return(paste(x, collapse = ""))
  }
  paste(vapply(x, rd_leaf_text, character(1)), collapse = "")
}

url_db_from_citation <- function(path) {
  file <- first_existing(file.path(
    path,
    c("CITATION", file.path("inst", "CITATION"))
  ))
  if (is.na(file)) {
    return(empty_url_db())
  }

  meta <- as.list(read.dcf(file.path(path, "DESCRIPTION"))[1L, ])
  cinfo <- tryCatch(
    utils::readCitationFile(file, meta = meta),
    error = function(e) NULL
  )
  urls <- if (is.null(cinfo)) {
    character()
  } else {
    unique(trimws(unlist(
      lapply(unclass(cinfo), function(e) e$url),
      use.names = FALSE
    )))
  }

  data.frame(
    URL = urls,
    Parent = rep.int(relative_path(file, path), length(urls)),
    stringsAsFactors = FALSE
  )
}

url_db_from_markdown_file <- function(path, filename, extensions) {
  file <- first_existing(file.path(
    path,
    c(filename, file.path("inst", filename))
  ))
  if (
    is.na(file) ||
      !pandoc_available() ||
      !requireNamespace("xml2", quietly = TRUE)
  ) {
    return(empty_url_db())
  }

  urls <- urls_from_markdown(file, extensions)
  data.frame(
    URL = urls,
    Parent = rep.int(relative_path(file, path), length(urls)),
    stringsAsFactors = FALSE
  )
}

url_db_from_built_vignettes <- function(path) {
  files <- Sys.glob(file.path(path, "inst", "doc", "*.html"))
  if (!length(files) || !requireNamespace("xml2", quietly = TRUE)) {
    return(empty_url_db())
  }

  urls <- lapply(files, extract_urls_from_html)
  names(urls) <- files
  urls <- Filter(length, urls)
  if (!length(urls)) {
    return(empty_url_db())
  }

  data.frame(
    URL = unlist(urls, use.names = FALSE),
    Parent = rep.int(
      relative_path(names(urls), path),
      lengths(urls)
    ),
    stringsAsFactors = FALSE
  )
}

# `url_db_from_rd_files()`/DESCRIPTION/CITATION cover everything R CMD check
# itself scans. Unbuilt vignettes/*.Rmd sources are the one addition
# urlchecker layers on top (a package's vignettes are only rendered to
# inst/doc/*.html once built), so render them the same way it does.
url_db_from_package_vignettes <- function(path) {
  # tools::pkgVignettes() canonicalizes `dir` itself and returns doc paths
  # built from that canonical form, so `path` must match or relative_path()
  # won't be able to strip the prefix back off.
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  docs <- Filter(file.exists, tools::pkgVignettes(dir = path)$docs)
  if (
    !length(docs) ||
      !pandoc_available() ||
      !requireNamespace("xml2", quietly = TRUE)
  ) {
    return(empty_url_db())
  }

  urls <- character()
  parents <- character()
  for (doc in docs) {
    doc_urls <- urls_from_markdown(doc, extensions = "autolink_bare_uris")
    if (length(doc_urls)) {
      urls <- c(urls, doc_urls)
      parents <- c(parents, rep.int(relative_path(doc, path), length(doc_urls)))
    }
  }

  data.frame(URL = urls, Parent = parents, stringsAsFactors = FALSE)
}

pandoc_available <- function() nzchar(Sys.which("pandoc"))

urls_from_markdown <- function(file, extensions) {
  html_file <- tempfile(fileext = ".html")
  on.exit(unlink(html_file))

  pandoc_format <- paste(c("markdown", extensions), collapse = "+")
  status <- system2(
    "pandoc",
    c(
      shQuote(normalizePath(file)),
      "-s",
      "--mathjax",
      "--email-obfuscation=references",
      "-f",
      pandoc_format,
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

first_existing <- function(paths) {
  Filter(file.exists, paths)[1L]
}

relative_path <- function(x, dir) {
  dir <- sub("/+$", "", dir)
  ifelse(startsWith(x, dir), substring(x, nchar(dir) + 2L), x)
}

empty_url_db <- function() {
  data.frame(URL = character(), Parent = character(), stringsAsFactors = FALSE)
}
