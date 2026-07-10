# rambutan: Fast Link Checking Powered by 'lychee'

An interface to the 'lychee' Rust crate
(<https://github.com/lycheeverse/lychee>), a fast, async link checker.
Wraps 'lychee-lib' via 'extendr' to check URLs, files, and directories
for broken links.

## Known issue on Windows

On Windows, the R process can exit with a non-zero status (a native
`STATUS_STACK_BUFFER_OVERRUN` crash) *after* a rambutan call has already
completed successfully and returned its result. This happens during
process/DLL teardown, not during the link check itself – calling
[`check_url()`](http://drmowinckels.io/rambutan/reference/check_url.md),
[`check_urls()`](http://drmowinckels.io/rambutan/reference/check_urls.md),
[`check_paths()`](http://drmowinckels.io/rambutan/reference/check_paths.md),
or
[`check_package()`](http://drmowinckels.io/rambutan/reference/check_package.md)
interactively returns correct results every time.

It only matters for non-interactive use where the exit code of the R
process itself is checked, e.g. `Rscript -e 'rambutan::check_url(...)'`
in a CI step or batch script. The underlying cause is very likely in a
transitive TLS dependency (`aws-lc-rs`, via `rustls`) rather than in
rambutan's own code, so it isn't something fixable here directly; it may
resolve with a future upstream update.

## See also

Useful links:

- <http://drmowinckels.io/rambutan/>

## Author

**Maintainer**: Athanasia Mo Mowinckel <a.m.mowinckel@psykologi.uio.no>
([ORCID](https://orcid.org/0000-0002-5756-0223)) (drmowinckels)
