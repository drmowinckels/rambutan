describe("check_package()", {
  it("errors when path has no DESCRIPTION file", {
    expect_error(check_package(notapkg_dir), "no DESCRIPTION file found")
  })

  it("returns a zero-row result with the expected columns when there are no URLs", {
    res <- check_package(nourls_dir)

    expect_s3_class(res, "data.frame")
    expect_named(res, c("url", "parent", "is_success", "code", "details"))
    expect_equal(nrow(res), 0L)
  })

  it("checks every URL found across a package's sources and reports its parent file", {
    res <- check_package(testpkg_dir)

    expect_named(res, c("url", "parent", "is_success", "code", "details"))
    expect_setequal(
      res$url,
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
    expect_equal(
      res$parent[res$url == "https://readme.example.com"],
      "README.md"
    )

    # example.com is an RFC 6761 reserved domain, so lychee excludes it by
    # default without making a network request -- these checks stay
    # deterministic offline.
    expect_true(all(!res$is_success))
    expect_true(all(is.na(res$code)))
  })

  it("threads the options argument through to every checked URL", {
    res <- check_package(testpkg_dir, options = lychee_options(exclude = "."))
    expect_true(all(grepl("exclude", res$details)))
  })
})
