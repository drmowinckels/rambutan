describe("url_db_from_package()", {
  it("finds URLs from every CRAN-checked source file", {
    db <- url_db_from_package(testpkg_dir)

    expect_s3_class(db, "data.frame")
    expect_named(db, c("URL", "Parent"))
    expect_setequal(
      db$URL,
      c(
        "https://url-field.example.com",
        "https://bugreports.example.com",
        "https://description.example.com",
        "https://rd-url.example.com",
        "https://rd-href.example.com",
        "https://citation.example.com",
        "https://readme.example.com",
        "https://news.example.com",
        "https://builtvignette.example.com",
        "https://vignette.example.com"
      )
    )
  })

  it("attributes each URL to the file it was found in", {
    db <- url_db_from_package(testpkg_dir)
    parent_of <- function(url) db$Parent[db$URL == url]

    expect_equal(parent_of("https://url-field.example.com"), "DESCRIPTION")
    expect_equal(parent_of("https://rd-url.example.com"), "man/foo.Rd")
    expect_equal(parent_of("https://citation.example.com"), "inst/CITATION")
    expect_equal(parent_of("https://readme.example.com"), "README.md")
    expect_equal(parent_of("https://news.example.com"), "NEWS.md")
    expect_equal(
      parent_of("https://builtvignette.example.com"),
      "inst/doc/manual.html"
    )
    expect_equal(
      parent_of("https://vignette.example.com"),
      "vignettes/intro.Rmd"
    )
  })

  it("returns a zero-row data frame for a package with no URLs", {
    db <- url_db_from_package(nourls_dir)

    expect_s3_class(db, "data.frame")
    expect_named(db, c("URL", "Parent"))
    expect_equal(nrow(db), 0L)
  })
})

describe("url_db_from_description()", {
  it("finds URLs in the URL, BugReports, and Description fields", {
    db <- url_db_from_description(testpkg_dir)

    expect_setequal(
      db$URL,
      c(
        "https://url-field.example.com",
        "https://bugreports.example.com",
        "https://description.example.com"
      )
    )
    expect_true(all(db$Parent == "DESCRIPTION"))
  })

  it("returns a zero-row data frame when no field has a URL", {
    db <- url_db_from_description(nourls_dir)

    expect_equal(nrow(db), 0L)
  })
})

describe("extract_bare_urls()", {
  it("extracts one or more bare URLs from free text", {
    expect_equal(
      extract_bare_urls("See https://a.example.com and https://b.example.com."),
      c("https://a.example.com", "https://b.example.com")
    )
  })

  it("strips trailing punctuation", {
    expect_equal(
      extract_bare_urls("Docs at https://a.example.com."),
      "https://a.example.com"
    )
  })

  it("returns an empty character vector when there is no URL", {
    expect_equal(extract_bare_urls("no links here"), character())
  })
})

describe("url_db_from_rd_files()", {
  it("finds \\url and \\href targets in man/*.Rd", {
    db <- url_db_from_rd_files(testpkg_dir)

    expect_setequal(
      db$URL,
      c("https://rd-url.example.com", "https://rd-href.example.com")
    )
    expect_true(all(db$Parent == "man/foo.Rd"))
  })

  it("returns a zero-row data frame when no Rd file has a link", {
    db <- url_db_from_rd_files(nourls_dir)

    expect_equal(nrow(db), 0L)
  })
})

describe("urls_from_rd()", {
  it("extracts the target of \\url and the URL argument of \\href", {
    rd <- tools::parse_Rd(file.path(testpkg_dir, "man", "foo.Rd"))

    expect_setequal(
      urls_from_rd(rd),
      c("https://rd-url.example.com", "https://rd-href.example.com")
    )
  })

  it("returns an empty character vector for Rd content with no links", {
    rd <- tools::parse_Rd(file.path(nourls_dir, "man", "bar.Rd"))

    expect_equal(urls_from_rd(rd), character())
  })
})

describe("url_db_from_news_rd()", {
  it("returns a zero-row data frame when there is no NEWS.Rd", {
    db <- url_db_from_news_rd(testpkg_dir)

    expect_s3_class(db, "data.frame")
    expect_named(db, c("URL", "Parent"))
    expect_equal(nrow(db), 0L)
  })
})

describe("url_db_from_citation()", {
  it("finds the URL declared in inst/CITATION", {
    db <- url_db_from_citation(testpkg_dir)

    expect_equal(db$URL, "https://citation.example.com")
    expect_equal(db$Parent, "inst/CITATION")
  })

  it("returns a zero-row data frame when there is no CITATION file", {
    db <- url_db_from_citation(nourls_dir)

    expect_equal(nrow(db), 0L)
  })
})

describe("url_db_from_markdown_file()", {
  it("finds URLs in README.md", {
    db <- url_db_from_markdown_file(
      testpkg_dir,
      "README.md",
      extensions = character()
    )

    expect_equal(db$URL, "https://readme.example.com")
    expect_equal(db$Parent, "README.md")
  })

  it("finds URLs in NEWS.md", {
    db <- url_db_from_markdown_file(
      testpkg_dir,
      "NEWS.md",
      extensions = character()
    )

    expect_equal(db$URL, "https://news.example.com")
    expect_equal(db$Parent, "NEWS.md")
  })

  it("returns a zero-row data frame when the file doesn't exist", {
    db <- url_db_from_markdown_file(
      nourls_dir,
      "README.md",
      extensions = character()
    )

    expect_equal(nrow(db), 0L)
  })
})

describe("url_db_from_built_vignettes()", {
  it("finds URLs in already-built inst/doc/*.html files", {
    db <- url_db_from_built_vignettes(testpkg_dir)

    expect_equal(db$URL, "https://builtvignette.example.com")
    expect_equal(db$Parent, "inst/doc/manual.html")
  })

  it("returns a zero-row data frame when there is no inst/doc directory", {
    db <- url_db_from_built_vignettes(nourls_dir)

    expect_equal(nrow(db), 0L)
  })
})

describe("url_db_from_package_vignettes()", {
  it("extracts URLs from unbuilt R Markdown vignettes", {
    db <- url_db_from_package_vignettes(testpkg_dir)

    expect_equal(db$URL, "https://vignette.example.com")
    expect_equal(db$Parent, "vignettes/intro.Rmd")
  })

  it("returns a zero-row data frame when there are no vignettes", {
    db <- url_db_from_package_vignettes(nourls_dir)

    expect_s3_class(db, "data.frame")
    expect_equal(nrow(db), 0L)
  })
})

describe("relative_path()", {
  it("strips the base directory prefix", {
    expect_equal(
      relative_path("/pkg/man/foo.Rd", "/pkg"),
      "man/foo.Rd"
    )
  })

  it("leaves paths outside the base directory untouched", {
    expect_equal(
      relative_path("/other/foo.Rd", "/pkg"),
      "/other/foo.Rd"
    )
  })
})

describe("first_existing()", {
  it("returns the first path that exists", {
    expect_equal(
      first_existing(c(
        file.path(nourls_dir, "does-not-exist"),
        file.path(nourls_dir, "DESCRIPTION")
      )),
      file.path(nourls_dir, "DESCRIPTION")
    )
  })

  it("returns NA when none of the paths exist", {
    expect_true(is.na(first_existing(file.path(nourls_dir, "does-not-exist"))))
  })
})
