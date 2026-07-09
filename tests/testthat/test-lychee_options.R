describe("lychee_options()", {
  it("returns defaults with class lychee_options", {
    opts <- lychee_options()
    expect_s3_class(opts, "lychee_options")
    expect_equal(opts$exclude, character())
    expect_equal(opts$include, character())
    expect_equal(opts$accept, character())
    expect_null(opts$timeout)
    expect_null(opts$max_redirects)
    expect_null(opts$header)
  })

  it("keeps only the values that were actually supplied", {
    opts <- lychee_options(timeout = 5, exclude = "foo")
    expect_equal(opts$timeout, 5)
    expect_equal(opts$exclude, "foo")
    expect_null(opts$max_retries)
  })

  it("accepts a named header vector", {
    opts <- lychee_options(header = c(Accept = "text/html"))
    expect_equal(opts$header, c(Accept = "text/html"))
  })

  it("errors on a non-scalar timeout", {
    expect_error(lychee_options(timeout = c(1, 2)))
  })

  it("errors on a non-character exclude", {
    expect_error(lychee_options(exclude = 1))
  })

  it("errors on a non-logical exclude_all_private", {
    expect_error(lychee_options(exclude_all_private = "true"))
  })

  it("errors on an unnamed header vector", {
    expect_error(lychee_options(header = c("text/html")))
  })
})

describe("lychee.toml auto-discovery", {
  it("is used when no R-side options are supplied", {
    dir <- withr::local_tempdir()
    writeLines('exclude = ["9001"]', file.path(dir, "lychee.toml"))
    withr::local_dir(dir)

    result <- check_urls("http://localhost:9001/whatever")
    expect_false(result$is_success)
    expect_match(result$details, "exclude")
  })

  it("unions R-side exclude with the file's exclude", {
    dir <- withr::local_tempdir()
    writeLines('exclude = ["9001"]', file.path(dir, "lychee.toml"))
    withr::local_dir(dir)

    result <- check_urls(
      c("http://localhost:9001/aaa", "http://localhost:9002/bbb"),
      options = lychee_options(exclude = "9002")
    )
    expect_false(any(result$is_success))
    expect_true(all(grepl("exclude", result$details)))
  })

  it("is not read when the working directory has no lychee.toml", {
    dir <- withr::local_tempdir()
    withr::local_dir(dir)

    result <- check_urls("http://localhost:9003/whatever")
    expect_false(result$is_success)
    expect_false(grepl("exclude", result$details))
  })

  it("surfaces a clear error for malformed TOML", {
    dir <- withr::local_tempdir()
    writeLines("exclude = not valid toml +++", file.path(dir, "lychee.toml"))
    withr::local_dir(dir)

    expect_error(check_urls("http://localhost:9001/whatever"))
  })
})
