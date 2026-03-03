#include <stdio.h>
#include <stdlib.h>
#include "../include/p4tc_runtime_api.h"

int p4tc_provision(struct pipe_config *config) {
    printf("[C-API] Provisioning pipeline '%s' from '%s'\n", config->name, config->template_dir);
    return 0;
}

struct p4tc_runt_ctx *p4tc_runt_ctx_create(int transport) {
    printf("[C-API] Creating runtime context (transport: %d)\n", transport);
    return (struct p4tc_runt_ctx *)malloc(1);
}

void p4tc_runt_ctx_destroy(struct p4tc_runt_ctx *ctx) {
    printf("[C-API] Destroying runtime context\n");
    free(ctx);
}

struct p4tc_attrs *p4tc_attrs_create(const char *name, int obj_type) {
    printf("[C-API] Creating attributes for '%s' (type: %d)\n", name, obj_type);
    return (struct p4tc_attrs *)malloc(1);
}

void p4tc_attrs_free(struct p4tc_attrs *attrs, void *cookie) {
    printf("[C-API] Freeing attributes\n");
    free(attrs);
}

int p4tc_create(struct p4tc_runt_ctx *ctx, struct p4tc_attrs *attrs, void *cookie) {
    printf("[C-API] Executing 'create' operation\n");
    return 0;
}

int p4tc_resp_handle(struct p4tc_runt_ctx *ctx, void *cb, int count) {
    printf("[C-API] Handling %d response(s)\n", count);
    return 0;
}
