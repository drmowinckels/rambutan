# A file literally named CITATION anywhere outside inst/CITATION makes
# `R CMD check` emit a "found ... in a non-standard place" NOTE against the
# whole package, even nested under tests/testthat/fixtures/. So the CITATION
# fixture is materialized into a temp copy at test time instead of being
# checked into the package sources.
build_testpkg_fixture <- function() {
  src <- test_path("fixtures/testpkg")
  dest <- file.path(tempdir(), "rambutan-testpkg-fixture")
  unlink(dest, recursive = TRUE, force = TRUE)
  dir.create(dest, recursive = TRUE)
  file.copy(
    list.files(src, full.names = TRUE, all.files = TRUE, no.. = TRUE),
    dest,
    recursive = TRUE
  )

  writeLines(
    c(
      "bibentry(",
      "  bibtype = \"Manual\",",
      "  title = \"Test Package\",",
      "  url = \"https://citation.example.com\"",
      ")"
    ),
    file.path(dest, "inst", "CITATION")
  )

  dest
}

testpkg_dir <- build_testpkg_fixture()
nourls_dir <- test_path("fixtures/nourls")
notapkg_dir <- test_path("fixtures/notapkg")
