use p4tc::{Action, Config, Context, Key, ObjType, P4TCError, Transport};
use std::path::Path;

#[test]
fn test_config_builder_success() {
    let config = Config::builder()
        .name("test_pipe")
        .template_dir(Path::new("/tmp/"))
        .build();
    
    assert!(config.is_ok());
    let cfg = config.unwrap();
    assert_eq!(cfg.name, "test_pipe");
    assert_eq!(cfg.template_dir.to_str().unwrap(), "/tmp/");
}

#[test]
fn test_config_builder_failure_missing_name() {
    let config = Config::builder()
        .template_dir(Path::new("/tmp/"))
        .build();
    
    assert!(config.is_err());
    match config.unwrap_err() {
        P4TCError::InvalidParameter(msg) => assert_eq!(msg, "name required"),
        _ => panic!("Expected InvalidParameter error"),
    }
}

#[test]
fn test_context_and_table_lifecycle() {
    // This implicitly tests the Drop implementation when ctx goes out of scope
    let mut ctx = Context::new(Transport::Netlink).expect("Failed to create context");
    
    let mut table = ctx.table("test_pipe", ObjType::RuntimeTable);
    assert_eq!(table.pipeline, "test_pipe");

    let action = Action::new("cb/send_nh")
        .param("port", "1")
        .param("drop", "false");

    assert_eq!(action.name, "cb/send_nh");

    // Test fluent API
    table.add_entry(Key::new("test_pipe/table/nh", "192.168.1.1"))
         .with_action(action);

    assert!(ctx.create(table).is_ok());
    assert!(ctx.handle_responses(1).is_ok());
}

#[test]
fn test_provisioning_call() {
    let config = Config::builder()
        .name("test_pipe")
        .template_dir(Path::new("/tmp/"))
        .build()
        .unwrap();

    let result = p4tc::provision(&config);
    assert!(result.is_ok());
}
