describe("check_url()", {
  it("returns a list with url, is_success, code, and details", {
    skip_if_offline()
    result <- check_url("https://www.r-project.org")
    expect_type(result, "list")
    expect_named(result, c("url", "is_success", "code", "details"))
  })

  it("reports success for a reachable URL", {
    skip_if_offline()
    result <- check_url("https://www.r-project.org")
    expect_true(result$is_success)
    expect_equal(result$code, 200L)
  })

  it("reports failure and the status code for a 404 response", {
    skip_if_offline()
    result <- check_url(
      "https://www.r-project.org/this-page-does-not-exist-xyz"
    )
    expect_false(result$is_success)
    expect_equal(result$code, 404L)
  })

  it("excludes RFC 6761 reserved .invalid domains without erroring", {
    result <- check_url("https://this-domain-should-not-exist-xyz123.invalid")
    expect_false(result$is_success)
    expect_true(is.na(result$code))
  })
})
