describe("check_file()", {
  it("finds and checks every link in a file", {
    skip_if_offline()
    result <- check_file(test_path("fixtures/sample-links.md"))

    expect_named(
      result,
      c("source", "line", "column", "url", "is_success", "code", "details")
    )
    expect_equal(nrow(result), 3L)
  })

  it("errors when file does not exist", {
    expect_error(check_file("does/not/exist-xyz.md"), "does not exist")
  })

  it("errors when file is a directory", {
    expect_error(
      check_file(test_path("fixtures/folder")),
      "Use check_folder"
    )
  })
})
