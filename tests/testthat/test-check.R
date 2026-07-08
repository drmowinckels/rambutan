describe("check_urls()", {
  it("returns one row per URL in the same order", {
    skip_if_offline()
    result <- check_urls(c(
      "https://www.r-project.org",
      "https://www.r-project.org/this-page-does-not-exist-xyz"
    ))
    expect_equal(nrow(result), 2L)
    expect_named(result, c("url", "is_success", "code", "details"))
    expect_equal(result$is_success, c(TRUE, FALSE))
    expect_equal(result$code, c(200L, 404L))
  })

  it("excludes URLs matching a supplied pattern", {
    result <- check_urls(
      "http://localhost:9999/whatever",
      excludes = "localhost"
    )
    expect_false(result$is_success)
    expect_true(is.na(result$code))
  })
})

describe("check_paths()", {
  it("finds and checks every link in a file", {
    skip_if_offline()
    result <- check_paths(test_path("fixtures/sample-links.md"))

    expect_named(
      result,
      c("source", "line", "column", "url", "is_success", "code", "details")
    )
    expect_equal(nrow(result), 3L)

    ok <- result[result$url == "https://www.r-project.org/", ]
    expect_true(ok$is_success)
    expect_equal(ok$line, 3L)

    dead <- result[
      result$url == "https://www.r-project.org/this-page-does-not-exist-xyz",
    ]
    expect_false(dead$is_success)
    expect_equal(dead$code, 404L)
  })

  it("excludes links matching a supplied pattern", {
    result <- check_paths(
      test_path("fixtures/sample-links.md"),
      excludes = "localhost"
    )
    excluded <- result[result$url == "http://localhost:9999/whatever", ]
    expect_false(excluded$is_success)
    expect_true(is.na(excluded$code))
  })

  it("errors on a path that does not exist", {
    expect_error(check_paths("does/not/exist-xyz.md"))
  })
})
