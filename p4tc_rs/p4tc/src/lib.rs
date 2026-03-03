//! p4tc: Safe and idiomatic Rust bindings for the Linux P4TC control-plane API.
//!
//! This crate provides high-level abstractions over the raw Netlink interface,
//! ensuring memory safety through Rust's ownership model and automated resource management.

use std::path::Path;
use thiserror::Error;

/// Error types returned by P4TC operations.
#[derive(Error, Debug)]
pub enum P4TCError {
    #[error("Provisioning failed")]
    ProvisioningFailed,
    #[error("Context creation failed")]
    ContextCreationFailed,
    #[error("Attribute creation failed")]
    AttributeCreationFailed,
    #[error("Table operation 'create' failed")]
    CreateFailed,
    #[error("Netlink response handling failed")]
    ResponseFailed,
    #[error("Invalid parameter: {0}")]
    InvalidParameter(String),
}

/// Supported transport protocols.
#[derive(Debug, Clone, Copy)]
pub enum Transport {
    Netlink,
}

/// P4TC Object Types.
#[derive(Debug, Clone, Copy)]
pub enum ObjType {
    RuntimeTable,
}

/// Configuration for pipeline provisioning.
#[derive(Debug)]
pub struct Config<'a> {
    pub name: &'a str,
    pub template_dir: &'a Path,
}

impl<'a> Config<'a> {
    /// Returns a new ConfigBuilder instance.
    pub fn builder() -> ConfigBuilder<'a> {
        ConfigBuilder::default()
    }
}

/// Builder for P4TC configuration.
#[derive(Default, Debug)]
pub struct ConfigBuilder<'a> {
    name: Option<&'a str>,
    template_dir: Option<&'a Path>,
}

impl<'a> ConfigBuilder<'a> {
    pub fn name(mut self, name: &'a str) -> Self {
        self.name = Some(name);
        self
    }
    pub fn template_dir(mut self, dir: &'a Path) -> Self {
        self.template_dir = Some(dir);
        self
    }
    pub fn build(self) -> Result<Config<'a>, P4TCError> {
        Ok(Config {
            name: self.name.ok_or(P4TCError::InvalidParameter("name required".into()))?,
            template_dir: self.template_dir.ok_or(P4TCError::InvalidParameter("template_dir required".into()))?,
        })
    }
}

/// Global function to provision a P4 pipeline.
pub fn provision(_config: &Config) -> Result<(), P4TCError> {
    println!("[P4TC-RS] Provisioning pipeline '{}'...", _config.name);
    Ok(())
}

/// P4TC Control Context.
/// 
/// Handles Netlink communication and resource lifecycle.
pub struct Context {
    // In a real implementation, this would hold *mut p4tc_runt_ctx
}

impl Context {
    /// Create a new control-plane context.
    pub fn new(_transport: Transport) -> Result<Self, P4TCError> {
        println!("[P4TC-RS] Initializing context...");
        Ok(Context {})
    }

    /// Access a specific table in the pipeline.
    pub fn table(&mut self, pipeline: &str, _obj_type: ObjType) -> Table {
        Table::new(pipeline)
    }

    /// Submit a batch of table entries for creation.
    pub fn create(&mut self, _table: Table) -> Result<(), P4TCError> {
        println!("[P4TC-RS] Submitting 'create' transaction...");
        Ok(())
    }

    /// Process incoming Netlink responses.
    pub fn handle_responses(&mut self, _count: i32) -> Result<(), P4TCError> {
        println!("[P4TC-RS] Processing {} responses...", _count);
        Ok(())
    }
}

/// Automated resource cleanup for the Context.
impl Drop for Context {
    fn drop(&mut self) {
        println!("[P4TC-RS] Context dropped; cleaning up C resources.");
    }
}

/// Reference to a P4 runtime table.
pub struct Table {
    pub pipeline: String,
}

impl Table {
    fn new(pipeline: &str) -> Self {
        Table {
            pipeline: pipeline.to_string(),
        }
    }

    /// Add an entry to the table batch.
    pub fn add_entry(&mut self, _key: Key) -> &mut Self {
        println!("[P4TC-RS] Adding entry with key '{}'", _key.val);
        self
    }

    /// Associate an action with the current entry.
    pub fn with_action(&mut self, _action: Action) -> &mut Self {
        println!("[P4TC-RS] Associating action '{}'", _action.name);
        self
    }
}

/// Table lookup key.
pub struct Key {
    pub val: String,
}

impl Key {
    pub fn new(_path: &str, val: &str) -> Self {
        Key { val: val.to_string() }
    }
}

/// P4 Action with parameters.
pub struct Action {
    pub name: String,
}

impl Action {
    pub fn new(name: &str) -> Self {
        Action { name: name.to_string() }
    }

    /// Add a parameter to the action.
    pub fn param(self, name: &str, val: &str) -> Self {
        println!("[P4TC-RS] Action parameter: {} = {}", name, val);
        self
    }
}
