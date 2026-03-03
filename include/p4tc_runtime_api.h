#ifndef P4TC_RUNTIME_API_H
#define P4TC_RUNTIME_API_H

struct pipe_config {
    const char *name;
    const char *template_dir;
};

struct p4tc_runt_ctx;
struct p4tc_attrs;

int p4tc_provision(struct pipe_config *config);
struct p4tc_runt_ctx *p4tc_runt_ctx_create(int transport);
void p4tc_runt_ctx_destroy(struct p4tc_runt_ctx *ctx);
struct p4tc_attrs *p4tc_attrs_create(const char *name, int obj_type);
void p4tc_attrs_free(struct p4tc_attrs *attrs, void *cookie);
int p4tc_create(struct p4tc_runt_ctx *ctx, struct p4tc_attrs *attrs, void *cookie);
int p4tc_resp_handle(struct p4tc_runt_ctx *ctx, void *cb, int count);

#endif
