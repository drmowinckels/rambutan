use http::header::{HeaderMap, HeaderName, HeaderValue};
use lychee_lib::{
    ClientBuilder, StatusCodeSelector, DEFAULT_MAX_REDIRECTS, DEFAULT_MAX_RETRIES,
    DEFAULT_RETRY_WAIT_TIME_SECS, DEFAULT_USER_AGENT,
};
use regex::RegexSet;
use serde::Deserialize;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::str::FromStr;
use std::time::Duration;

const CONFIG_FILE_NAME: &str = "lychee.toml";

#[derive(Debug, Default, Clone, Deserialize, PartialEq)]
#[serde(default)]
pub struct RambutanConfig {
    pub exclude: Vec<String>,
    pub include: Vec<String>,
    pub timeout: Option<u64>,
    pub max_redirects: Option<usize>,
    pub max_retries: Option<u64>,
    pub retry_wait_time: Option<u64>,
    pub user_agent: Option<String>,
    pub method: Option<String>,
    pub accept: Option<StatusCodeSelector>,
    pub exclude_all_private: Option<bool>,
    pub exclude_private: Option<bool>,
    pub exclude_link_local: Option<bool>,
    pub exclude_loopback: Option<bool>,
    pub require_https: Option<bool>,
    pub include_mail: Option<bool>,
    pub header: HashMap<String, String>,
}

/// Look for `lychee.toml` in the current working directory and parse it.
/// A missing file is not an error; a malformed one is.
pub fn load_file_config() -> Result<RambutanConfig, String> {
    let path = env::current_dir()
        .map_err(|e| format!("failed to read current directory: {e}"))?
        .join(CONFIG_FILE_NAME);

    if !path.is_file() {
        return Ok(RambutanConfig::default());
    }

    let contents =
        fs::read_to_string(&path).map_err(|e| format!("failed to read {}: {e}", path.display()))?;

    toml::from_str(&contents).map_err(|e| format!("failed to parse {}: {e}", path.display()))
}

/// Merge explicit R-supplied arguments with the auto-discovered file config.
/// `args` takes precedence over `file` for scalar fields; `exclude`/`include`
/// are unioned, and `header` entries from `args` win on key collisions.
pub fn merge(args: RambutanConfig, file: RambutanConfig) -> RambutanConfig {
    let mut header = file.header;
    header.extend(args.header);

    RambutanConfig {
        exclude: args.exclude.into_iter().chain(file.exclude).collect(),
        include: args.include.into_iter().chain(file.include).collect(),
        timeout: args.timeout.or(file.timeout),
        max_redirects: args.max_redirects.or(file.max_redirects),
        max_retries: args.max_retries.or(file.max_retries),
        retry_wait_time: args.retry_wait_time.or(file.retry_wait_time),
        user_agent: args.user_agent.or(file.user_agent),
        method: args.method.or(file.method),
        accept: args.accept.or(file.accept),
        exclude_all_private: args.exclude_all_private.or(file.exclude_all_private),
        exclude_private: args.exclude_private.or(file.exclude_private),
        exclude_link_local: args.exclude_link_local.or(file.exclude_link_local),
        exclude_loopback: args.exclude_loopback.or(file.exclude_loopback),
        require_https: args.require_https.or(file.require_https),
        include_mail: args.include_mail.or(file.include_mail),
        header,
    }
}

/// Build a `lychee_lib::ClientBuilder` from a fully merged config.
///
/// `typed_builder`'s type-state changes with every setter call, so a single
/// builder value can't be conditionally reassigned across `if`/`else`
/// branches. Instead, every field's final value (config override or
/// lychee-lib's own default) is resolved upfront, then applied in one
/// unconditional setter chain.
pub fn apply_to_builder(config: &RambutanConfig) -> Result<ClientBuilder, String> {
    let excludes =
        RegexSet::new(&config.exclude).map_err(|e| format!("invalid exclude pattern: {e}"))?;
    let includes =
        RegexSet::new(&config.include).map_err(|e| format!("invalid include pattern: {e}"))?;

    let method = match &config.method {
        Some(method) => reqwest::Method::from_str(method)
            .map_err(|e| format!("invalid method '{method}': {e}"))?,
        None => reqwest::Method::GET,
    };

    let accepted = config
        .accept
        .clone()
        .unwrap_or_else(StatusCodeSelector::default_accepted);

    let mut headers = HeaderMap::new();
    for (name, value) in &config.header {
        let header_name = HeaderName::from_bytes(name.as_bytes())
            .map_err(|e| format!("invalid header name '{name}': {e}"))?;
        let header_value = HeaderValue::from_str(value)
            .map_err(|e| format!("invalid header value for '{name}': {e}"))?;
        headers.insert(header_name, header_value);
    }

    let builder = ClientBuilder::builder()
        .excludes(excludes)
        .includes(includes)
        .timeout(config.timeout.map(Duration::from_secs))
        .max_redirects(config.max_redirects.unwrap_or(DEFAULT_MAX_REDIRECTS))
        .max_retries(config.max_retries.unwrap_or(DEFAULT_MAX_RETRIES))
        .retry_wait_time(Duration::from_secs(
            config
                .retry_wait_time
                .unwrap_or(DEFAULT_RETRY_WAIT_TIME_SECS),
        ))
        .user_agent(
            config
                .user_agent
                .clone()
                .unwrap_or_else(|| DEFAULT_USER_AGENT.to_string()),
        )
        .method(method)
        .accepted(accepted)
        .exclude_all_private(config.exclude_all_private.unwrap_or(false))
        .exclude_private_ips(config.exclude_private.unwrap_or(false))
        .exclude_link_local_ips(config.exclude_link_local.unwrap_or(false))
        .exclude_loopback_ips(config.exclude_loopback.unwrap_or(false))
        .require_https(config.require_https.unwrap_or(false))
        .include_mail(config.include_mail.unwrap_or(false))
        .custom_headers(headers)
        .build();

    Ok(builder)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_core_fields_from_toml() {
        let toml = r#"
            exclude = ["foo\\.example"]
            include = ["bar\\.example"]
            timeout = 10
            max_redirects = 5
            max_retries = 2
            retry_wait_time = 3
            user_agent = "rambutan-test"
            method = "head"
            accept = "200..=204,429"
            exclude_all_private = true
            require_https = true
            include_mail = true

            [header]
            Accept = "text/html"
        "#;

        let config: RambutanConfig = toml::from_str(toml).unwrap();

        assert_eq!(config.exclude, vec!["foo\\.example".to_string()]);
        assert_eq!(config.include, vec!["bar\\.example".to_string()]);
        assert_eq!(config.timeout, Some(10));
        assert_eq!(config.max_redirects, Some(5));
        assert_eq!(config.max_retries, Some(2));
        assert_eq!(config.retry_wait_time, Some(3));
        assert_eq!(config.user_agent, Some("rambutan-test".to_string()));
        assert_eq!(config.method, Some("head".to_string()));
        assert!(config.accept.as_ref().unwrap().contains(200));
        assert!(!config.accept.as_ref().unwrap().contains(404));
        assert_eq!(config.exclude_all_private, Some(true));
        assert_eq!(config.require_https, Some(true));
        assert_eq!(config.include_mail, Some(true));
        assert_eq!(config.header.get("Accept"), Some(&"text/html".to_string()));
    }

    #[test]
    fn unknown_fields_are_ignored() {
        let toml = r#"
            exclude = ["foo"]
            dump = true
            archive = "wayback"
        "#;

        let config: RambutanConfig = toml::from_str(toml).unwrap();
        assert_eq!(config.exclude, vec!["foo".to_string()]);
    }

    #[test]
    fn malformed_toml_is_an_error() {
        let toml = "exclude = not a valid value +++";
        assert!(toml::from_str::<RambutanConfig>(toml).is_err());
    }

    #[test]
    fn args_scalars_override_file_scalars() {
        let args = RambutanConfig {
            timeout: Some(5),
            ..Default::default()
        };
        let file = RambutanConfig {
            timeout: Some(20),
            max_retries: Some(1),
            ..Default::default()
        };

        let merged = merge(args, file);
        assert_eq!(merged.timeout, Some(5));
        assert_eq!(merged.max_retries, Some(1));
    }

    #[test]
    fn file_scalar_used_when_args_absent() {
        let args = RambutanConfig::default();
        let file = RambutanConfig {
            user_agent: Some("file-agent".to_string()),
            ..Default::default()
        };

        let merged = merge(args, file);
        assert_eq!(merged.user_agent, Some("file-agent".to_string()));
    }

    #[test]
    fn exclude_and_include_are_unioned() {
        let args = RambutanConfig {
            exclude: vec!["from-args".to_string()],
            ..Default::default()
        };
        let file = RambutanConfig {
            exclude: vec!["from-file".to_string()],
            ..Default::default()
        };

        let merged = merge(args, file);
        assert_eq!(
            merged.exclude,
            vec!["from-args".to_string(), "from-file".to_string()]
        );
    }

    #[test]
    fn header_collisions_favour_args() {
        let mut args_header = HashMap::new();
        args_header.insert("X-Test".to_string(), "from-args".to_string());
        let mut file_header = HashMap::new();
        file_header.insert("X-Test".to_string(), "from-file".to_string());
        file_header.insert("Accept".to_string(), "text/html".to_string());

        let args = RambutanConfig {
            header: args_header,
            ..Default::default()
        };
        let file = RambutanConfig {
            header: file_header,
            ..Default::default()
        };

        let merged = merge(args, file);
        assert_eq!(merged.header.get("X-Test"), Some(&"from-args".to_string()));
        assert_eq!(merged.header.get("Accept"), Some(&"text/html".to_string()));
    }

    #[test]
    fn apply_to_builder_builds_successfully_with_core_fields_set() {
        let config = RambutanConfig {
            exclude: vec!["example\\.com".to_string()],
            timeout: Some(5),
            max_redirects: Some(3),
            max_retries: Some(1),
            retry_wait_time: Some(1),
            user_agent: Some("rambutan-test".to_string()),
            method: Some("head".to_string()),
            accept: Some(StatusCodeSelector::from_str("200..=204,429").unwrap()),
            exclude_all_private: Some(true),
            require_https: Some(false),
            include_mail: Some(true),
            ..Default::default()
        };

        assert!(apply_to_builder(&config).is_ok());
    }

    #[test]
    fn apply_to_builder_rejects_invalid_method() {
        let config = RambutanConfig {
            method: Some("not a method".to_string()),
            ..Default::default()
        };

        assert!(apply_to_builder(&config).is_err());
    }
}
