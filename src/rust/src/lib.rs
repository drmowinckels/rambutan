use extendr_api::prelude::*;
use futures::stream::{self, StreamExt};
use lychee_lib::{BaseInfo, Client, ClientBuilder, Collector, Input};
use regex::RegexSet;
use std::collections::HashSet;
use std::sync::OnceLock;
use tokio::runtime::Runtime;

const CONCURRENCY: usize = 8;

fn runtime() -> &'static Runtime {
    static RUNTIME: OnceLock<Runtime> = OnceLock::new();
    RUNTIME.get_or_init(|| Runtime::new().expect("failed to start tokio runtime"))
}

fn build_client(excludes: &[String]) -> std::result::Result<Client, String> {
    let regex_set = RegexSet::new(excludes).map_err(|e| format!("invalid exclude pattern: {e}"))?;
    ClientBuilder::builder()
        .excludes(regex_set)
        .build()
        .client()
        .map_err(|e| e.to_string())
}

fn status_fields(status: &lychee_lib::Status) -> (bool, Option<i32>, String) {
    (
        status.is_success(),
        status.code().map(|c| c.as_u16() as i32),
        status.details(),
    )
}

/// Check a single URL with lychee and return its status.
/// @param url A single URL string to check.
/// @return A list with `url`, `is_success`, `code`, and `details`.
/// @export
#[extendr]
fn check_url(url: &str) -> List {
    let url_owned = url.to_string();

    let (is_success, code, details) = runtime().block_on(async {
        let client = ClientBuilder::default()
            .client()
            .expect("failed to build lychee client");

        match client.check(url_owned.as_str()).await {
            Ok(response) => status_fields(&response.status()),
            Err(e) => (false, None, e.to_string()),
        }
    });

    list!(
        url = url,
        is_success = is_success,
        code = code,
        details = details
    )
}

/// Check multiple URLs concurrently with lychee.
/// @param urls Character vector of URLs to check.
/// @param excludes Character vector of regular expressions; URLs matching
///   any pattern are treated as excluded rather than checked. Empty for none.
/// @return A list of parallel vectors: `is_success`, `code`, `details`, one
///   entry per element of `urls`, in the same order.
/// @noRd
#[extendr]
fn check_urls_impl(urls: Vec<String>, excludes: Vec<String>) -> std::result::Result<List, String> {
    let client = build_client(&excludes)?;

    let results: Vec<(bool, Option<i32>, String)> = runtime().block_on(async {
        let checks = urls.iter().map(|url| {
            let client = &client;
            async move {
                match client.check(url.as_str()).await {
                    Ok(response) => status_fields(&response.status()),
                    Err(e) => (false, None, e.to_string()),
                }
            }
        });
        stream::iter(checks).buffered(CONCURRENCY).collect().await
    });

    let mut is_success = Vec::with_capacity(results.len());
    let mut code: Vec<Option<i32>> = Vec::with_capacity(results.len());
    let mut details = Vec::with_capacity(results.len());
    for (success, c, detail) in results {
        is_success.push(success);
        code.push(c);
        details.push(detail);
    }

    Ok(list!(
        is_success = is_success,
        code = code,
        details = details
    ))
}

/// Scan files, directories, or glob patterns for links and check each one.
/// @param paths Character vector of file paths, directories, or glob
///   patterns (e.g. `"**/*.md"`) to scan for links.
/// @param excludes Character vector of regular expressions; URLs matching
///   any pattern are treated as excluded rather than checked. Empty for none.
/// @return A list of parallel vectors: `source`, `line`, `column`, `url`,
///   `is_success`, `code`, `details`, one entry per discovered link.
/// @noRd
#[extendr]
fn check_paths_impl(
    paths: Vec<String>,
    excludes: Vec<String>,
) -> std::result::Result<List, String> {
    let client = build_client(&excludes)?;

    let mut inputs = HashSet::with_capacity(paths.len());
    for path in &paths {
        let input = Input::from_value(path).map_err(|e| format!("invalid input '{path}': {e}"))?;
        inputs.insert(input);
    }

    let results: Vec<(String, i32, Option<i32>, String, bool, Option<i32>, String)> = runtime()
        .block_on(async {
            let collector = Collector::new(None, BaseInfo::none()).map_err(|e| e.to_string())?;

            let requests: Vec<_> = collector
                .collect_links(inputs)
                .filter_map(|item| async move { item.ok() })
                .collect()
                .await;

            let checks = requests.into_iter().map(|req| {
                let client = &client;
                async move {
                    let source = req.source.to_string();
                    let (line, column) = req
                        .span
                        .as_ref()
                        .map(|s| (s.line.get() as i32, s.column.map(|c| c.get() as i32)))
                        .unwrap_or((0, None));
                    let url = req.uri.to_string();

                    let (is_success, code, details) = match client.check(req).await {
                        Ok(response) => status_fields(&response.status()),
                        Err(e) => (false, None, e.to_string()),
                    };

                    (source, line, column, url, is_success, code, details)
                }
            });

            let results: Vec<_> = stream::iter(checks)
                .buffer_unordered(CONCURRENCY)
                .collect()
                .await;
            Ok::<_, String>(results)
        })?;

    let mut source = Vec::with_capacity(results.len());
    let mut line = Vec::with_capacity(results.len());
    let mut column: Vec<Option<i32>> = Vec::with_capacity(results.len());
    let mut url = Vec::with_capacity(results.len());
    let mut is_success = Vec::with_capacity(results.len());
    let mut code: Vec<Option<i32>> = Vec::with_capacity(results.len());
    let mut details = Vec::with_capacity(results.len());
    for (s, l, c, u, ok, code_val, detail) in results {
        source.push(s);
        line.push(l);
        column.push(c);
        url.push(u);
        is_success.push(ok);
        code.push(code_val);
        details.push(detail);
    }

    Ok(list!(
        source = source,
        line = line,
        column = column,
        url = url,
        is_success = is_success,
        code = code,
        details = details
    ))
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod rambutan;
    fn check_url;
    fn check_urls_impl;
    fn check_paths_impl;
}
