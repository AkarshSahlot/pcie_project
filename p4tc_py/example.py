import p4tc

# Constants
PNAME = "myprog"
TNAME = "cb/nh_table"
TMPL_DIR = "/path/to/tmpl/"

def main():
    try:
        # 1. Provisioning
        p4tc.provision(
            pipeline_name=PNAME, 
            template_dir=TMPL_DIR
        )

        # 2. Context Creation (with automatic cleanup)
        with p4tc.context(transport="netlink") as ctx:
            
            # 3. Create the Table/Transaction Object
            table = ctx.table(pipeline=PNAME, table_path=TNAME)

            # 4. Create Entry and Action
            # Action parameters are passed as native Python dictionaries.
            table.entry(
                key="10.10.10.1",
                action = {
                    "name": "cb/send_nh",
                    "params": {
                        "port_id": "eth0",
                        "dmac": "01:02:03:04:05:06",
                        "smac": "07:08:09:0A:0B:0C"
                    }
                }
            )

            # 5. Submit (Create)
            ctx.create(table)

            # 6. Handle Response
            ctx.process_responses(count=1)

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
