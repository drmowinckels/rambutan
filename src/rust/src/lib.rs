mod config;

use config::RambutanConfig;
use extendr_api::prelude::*;
use futures::stream::{self, StreamExt};
use lychee_lib::{BaseInfo, Client, Collector, Input, StatusCodeSelector};
use std::collections::HashSet;
use std::str::FromStr;
use std::sync::OnceLock;
use tokio::runtime::Runtime;

const CONCURRENCY: usize = 8;

// A current-thread runtime is used instead of the multi-threaded default:
// our workload is I/O-bound concurrent HTTP checks (no CPU parallelism
// needed), so nothing is lost by driving it on one thread.
//
// The runtime is intentionally leaked (never dropped) rather than stored
// directly in the OnceLock. Tokio's `Runtime::drop` does its own thread/
// driver teardown, and on Windows that logic running during process or
// DLL exit (a restricted context -- see DLL_PROCESS_DETACH) was observed
// to make the R subprocess exit non-zero even after a fully passing test
// run printed its summary and returned normally. Leaking guarantees that
// teardown code never executes; the OS reclaims everything at process
// exit regardless.
fn runtime() -> &'static Runtime {
    static RUNTIME: OnceLock<&'static Runtime> = OnceLock::new();
    *RUNTIME.get_or_init(|| {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("failed to start tokio runtime");
        Box::leak(Box::new(rt))
    })
}

/// Flatten the extendr-friendly scalar/vector arguments coming from R's
/// `lychee_options()` into a `RambutanConfig`. Kept separate from
/// `#[extendr]` functions so the three call sites share one conversion.
#[allow(clippy::too_many_arguments)]
fn config_from_args(
    exclude: Vec<String>,
    include: Vec<String>,
    timeout: Nullable<f64>,
    max_redirects: Nullable<f64>,
    max_retries: Nullable<f64>,
    retry_wait_time: Nullable<f64>,
    user_agent: Nullable<String>,
    method: Nullable<String>,
    accept: Vec<String>,
    exclude_all_private: Nullable<bool>,
    exclude_private: Nullable<bool>,
    exclude_link_local: Nullable<bool>,
    exclude_loopback: Nullable<bool>,
    require_https: Nullable<bool>,
    include_mail: Nullable<bool>,
    header_names: Vec<String>,
    header_values: Vec<String>,
) -> std::result::Result<RambutanConfig, String> {
    let accept = if accept.is_empty() {
        None
    } else {
        Some(
            StatusCodeSelector::from_str(&accept.join(","))
                .map_err(|e| format!("invalid accept status code range: {e}"))?,
        )
    };

    if header_names.len() != header_values.len() {
        return Err("header names and values must be the same length".to_string());
    }

    Ok(RambutanConfig {
        exclude,
        include,
        timeout: timeout.into_option().map(|v| v as u64),
        max_redirects: max_redirects.into_option().map(|v| v as usize),
        max_retries: max_retries.into_option().map(|v| v as u64),
        retry_wait_time: retry_wait_time.into_option().map(|v| v as u64),
        user_agent: user_agent.into_option(),
        method: method.into_option(),
        accept,
        exclude_all_private: exclude_all_private.into_option(),
        exclude_private: exclude_private.into_option(),
        exclude_link_local: exclude_link_local.into_option(),
        exclude_loopback: exclude_loopback.into_option(),
        require_https: require_https.into_option(),
        include_mail: include_mail.into_option(),
        header: header_names.into_iter().zip(header_values).collect(),
    })
}

fn build_client(overrides: RambutanConfig) -> std::result::Result<Client, String> {
    let file_config = config::load_file_config()?;
    let merged = config::merge(overrides, file_config);
    config::apply_to_builder(&merged)?
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
/// @noRd
#[extendr]
#[allow(clippy::too_many_arguments)]
fn check_url_impl(
    url: &str,
    exclude: Vec<String>,
    include: Vec<String>,
    timeout: Nullable<f64>,
    max_redirects: Nullable<f64>,
    max_retries: Nullable<f64>,
    retry_wait_time: Nullable<f64>,
    user_agent: Nullable<String>,
    method: Nullable<String>,
    accept: Vec<String>,
    exclude_all_private: Nullable<bool>,
    exclude_private: Nullable<bool>,
    exclude_link_local: Nullable<bool>,
    exclude_loopback: Nullable<bool>,
    require_https: Nullable<bool>,
    include_mail: Nullable<bool>,
    header_names: Vec<String>,
    header_values: Vec<String>,
) -> std::result::Result<List, String> {
    let config = config_from_args(
        exclude,
        include,
        timeout,
        max_redirects,
        max_retries,
        retry_wait_time,
        user_agent,
        method,
        accept,
        exclude_all_private,
        exclude_private,
        exclude_link_local,
        exclude_loopback,
        require_https,
        include_mail,
        header_names,
        header_values,
    )?;
    let client = build_client(config)?;
    let url_owned = url.to_string();

    let (is_success, code, details) = runtime().block_on(async {
        match client.check(url_owned.as_str()).await {
            Ok(response) => status_fields(&response.status()),
            Err(e) => (false, None, e.to_string()),
        }
    });

    Ok(list!(
        url = url,
        is_success = is_success,
        code = code,
        details = details
    ))
}

/// Check multiple URLs concurrently with lychee.
/// @noRd
#[extendr]
#[allow(clippy::too_many_arguments)]
fn check_urls_impl(
    urls: Vec<String>,
    exclude: Vec<String>,
    include: Vec<String>,
    timeout: Nullable<f64>,
    max_redirects: Nullable<f64>,
    max_retries: Nullable<f64>,
    retry_wait_time: Nullable<f64>,
    user_agent: Nullable<String>,
    method: Nullable<String>,
    accept: Vec<String>,
    exclude_all_private: Nullable<bool>,
    exclude_private: Nullable<bool>,
    exclude_link_local: Nullable<bool>,
    exclude_loopback: Nullable<bool>,
    require_https: Nullable<bool>,
    include_mail: Nullable<bool>,
    header_names: Vec<String>,
    header_values: Vec<String>,
) -> std::result::Result<List, String> {
    let config = config_from_args(
        exclude,
        include,
        timeout,
        max_redirects,
        max_retries,
        retry_wait_time,
        user_agent,
        method,
        accept,
        exclude_all_private,
        exclude_private,
        exclude_link_local,
        exclude_loopback,
        require_https,
        include_mail,
        header_names,
        header_values,
    )?;
    let client = build_client(config)?;

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
/// @noRd
#[extendr]
#[allow(clippy::too_many_arguments)]
fn check_paths_impl(
    paths: Vec<String>,
    exclude: Vec<String>,
    include: Vec<String>,
    timeout: Nullable<f64>,
    max_redirects: Nullable<f64>,
    max_retries: Nullable<f64>,
    retry_wait_time: Nullable<f64>,
    user_agent: Nullable<String>,
    method: Nullable<String>,
    accept: Vec<String>,
    exclude_all_private: Nullable<bool>,
    exclude_private: Nullable<bool>,
    exclude_link_local: Nullable<bool>,
    exclude_loopback: Nullable<bool>,
    require_https: Nullable<bool>,
    include_mail: Nullable<bool>,
    header_names: Vec<String>,
    header_values: Vec<String>,
) -> std::result::Result<List, String> {
    let config = config_from_args(
        exclude,
        include,
        timeout,
        max_redirects,
        max_retries,
        retry_wait_time,
        user_agent,
        method,
        accept,
        exclude_all_private,
        exclude_private,
        exclude_link_local,
        exclude_loopback,
        require_https,
        include_mail,
        header_names,
        header_values,
    )?;
    let client = build_client(config)?;

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
    fn check_url_impl;
    fn check_urls_impl;
    fn check_paths_impl;
}
