describe("check_folder()", {
  it("recursively checks every link by default", {
    result <- check_folder(test_path("fixtures/folder"))
    expect_setequal(
      result$url,
      c(
        "https://top.example.com/",
        "https://nested.example.com/",
        "https://text.example.com/"
      )
    )
  })

  it("only checks top-level files when recursive = FALSE", {
    result <- check_folder(test_path("fixtures/folder"), recursive = FALSE)
    expect_setequal(
      result$url,
      c("https://top.example.com/", "https://text.example.com/")
    )
  })

  it("restricts the scan to the given extensions", {
    result <- check_folder(test_path("fixtures/folder"), extensions = "md")
    expect_setequal(
      result$url,
      c("https://top.example.com/", "https://nested.example.com/")
    )
  })

  it("combines recursive = FALSE with extensions", {
    result <- check_folder(
      test_path("fixtures/folder"),
      recursive = FALSE,
      extensions = ".md"
    )
    expect_equal(result$url, "https://top.example.com/")
  })

  it("treats extensions as literal strings, not regular expressions", {
    dir <- withr::local_tempdir()
    writeLines("https://real.example.com", file.path(dir, "archive.tar.gz"))
    writeLines("https://fake.example.com", file.path(dir, "archive.tarXgz"))

    result <- check_folder(dir, extensions = "tar.gz")

    expect_equal(result$url, "https://real.example.com/")
  })

  it("skips hidden files even when extensions is set", {
    dir <- withr::local_tempdir()
    writeLines("https://visible.example.com", file.path(dir, "visible.md"))
    writeLines("https://hidden.example.com", file.path(dir, ".hidden.md"))

    result <- check_folder(dir, extensions = "md")

    expect_equal(result$url, "https://visible.example.com/")
  })

  it("errors when extensions contains an empty string", {
    expect_error(
      check_folder(test_path("fixtures/folder"), extensions = c("md", "")),
      "empty strings"
    )
  })

  it("errors when path does not exist", {
    expect_error(
      check_folder("does/not/exist-xyz"),
      "not an existing directory"
    )
  })

  it("errors when path is a file", {
    expect_error(
      check_folder(test_path("fixtures/sample-links.md")),
      "Use check_file"
    )
  })
})
