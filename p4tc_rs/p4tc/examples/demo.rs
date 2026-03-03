use p4tc::{Action, Config, Context, ObjType, Transport, Key, P4TCError};
use std::path::Path;

const PNAME: &str = "myprog";
const TNAME: &str = "cb/nh_table";
const TMPL_DIR: &str = "/path/to/tmpl/";

fn main() -> Result<(), P4TCError> {
    // 1. Provisioning
    let config = Config::builder()
        .name(PNAME)
        .template_dir(Path::new(TMPL_DIR))
        .build()?;

    p4tc::provision(&config)?;

    // 2. Context Creation (Safe Drop handled)
    let mut ctx = Context::new(Transport::Netlink)?;

    // 3. Prepare Table Reference
    let table_path = format!("{}/table/{}", PNAME, TNAME);
    let mut table = ctx.table(PNAME, ObjType::RuntimeTable);

    // 4. Create Entry & Action (Fluent Interface)
    let action = Action::new("cb/send_nh")
        .param("port_id", "eth0")
        .param("dmac", "01:02:03:04:05:06")
        .param("smac", "07:08:09:0A:0B:0C");

    table
        .add_entry(Key::new(&table_path, "10.10.10.1"))
        .with_action(action);

    // 5. Submit
    ctx.create(table)?;

    // 6. Handle Response
    ctx.handle_responses(1)?;

    Ok(())
}
