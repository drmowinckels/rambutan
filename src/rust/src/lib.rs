use extendr_api::prelude::*;
use lychee_lib::ClientBuilder;
use std::sync::OnceLock;
use tokio::runtime::Runtime;

fn runtime() -> &'static Runtime {
    static RUNTIME: OnceLock<Runtime> = OnceLock::new();
    RUNTIME.get_or_init(|| Runtime::new().expect("failed to start tokio runtime"))
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
            Ok(response) => {
                let status = response.status();
                let code = status.code().map(|c| c.as_u16() as i32);
                (status.is_success(), code, status.details())
            }
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

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod rambutan;
    fn check_url;
}
