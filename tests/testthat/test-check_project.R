describe("check_project()", {
  it("checks links while skipping dependency and build directories", {
    result <- check_project(test_path("fixtures/project"))
    expect_equal(result$url, "https://project.example.com/")
  })

  it("always skips hidden directories", {
    # A dot-directory can't be committed as a static fixture -- R CMD check
    # flags hidden files/directories anywhere in the source tree -- so it's
    # created on the fly in a temp dir instead.
    dir <- withr::local_tempdir()
    hidden <- file.path(dir, ".hidden")
    dir.create(hidden)
    writeLines(
      "Hidden file referencing https://hidden.example.com for more.",
      file.path(hidden, "secret.md")
    )
    writeLines(
      "Visible file referencing https://visible.example.com for more.",
      file.path(dir, "visible.md")
    )

    result <- check_project(dir, exclude_dirs = character())

    expect_equal(result$url, "https://visible.example.com/")
  })

  it("only applies the exclude_dirs the caller asks for", {
    result <- check_project(
      test_path("fixtures/project"),
      exclude_dirs = "node_modules"
    )
    expect_setequal(
      result$url,
      c("https://project.example.com/", "https://target.example.com/")
    )
  })

  it("treats exclude_dirs as literal names, not regular expressions", {
    dir <- withr::local_tempdir()
    excluded <- file.path(dir, "vendor.old")
    kept <- file.path(dir, "vendorXold")
    dir.create(excluded)
    dir.create(kept)
    writeLines("https://excluded.example.com", file.path(excluded, "f.md"))
    writeLines("https://kept.example.com", file.path(kept, "f.md"))

    result <- check_project(dir, exclude_dirs = "vendor.old")

    expect_equal(result$url, "https://kept.example.com/")
  })

  it("errors when exclude_dirs contains an empty string", {
    expect_error(
      check_project(
        test_path("fixtures/project"),
        exclude_dirs = c("node_modules", "")
      ),
      "empty strings"
    )
  })

  it("errors when path does not exist", {
    expect_error(
      check_project("does/not/exist-xyz"),
      "not an existing directory"
    )
  })
})
