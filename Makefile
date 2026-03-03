# Polyglot P4TC - Project Automation Makefile

CC = gcc
CFLAGS = -shared -fPIC
LIB_NAME = libp4tc.so
C_SRC = p4tc_src/libp4tc.c
PYTHON = python3
RUST_DIR = p4tc_rs

.PHONY: all lib python rust test clean help

all: lib python rust test

help:
	@echo "Polyglot P4TC Build System"
	@echo "Available targets:"
	@echo "  lib     : Build the mock C runtime library"
	@echo "  python  : Run the Python API demonstration"
	@echo "  rust    : Build and run the Rust API demonstration"
	@echo "  test    : Run automated tests for both Python and Rust wrappers"
	@echo "  clean   : Remove build artifacts"
	@echo "  all     : Build and test everything"

# 1. Build Mock C Library
lib: $(LIB_NAME)

$(LIB_NAME): $(C_SRC)
	$(CC) $(CFLAGS) $(C_SRC) -o $(LIB_NAME)
	@echo "Mock C library built: $(LIB_NAME)"

# 2. Test Python API
python: lib
	@echo "Running Python API Demonstration..."
	@export LIB_P4TC_PATH=$(PWD)/$(LIB_NAME) && \
	export LD_LIBRARY_PATH=$(PWD):$$LD_LIBRARY_PATH && \
	$(PYTHON) p4tc_py/example.py

# 3. Test Rust API
rust: lib
	@echo "Building and Running Rust API Demonstration..."
	@if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
	cd $(RUST_DIR) && cargo run --example demo

# 4. Automated Testing
test: lib
	@echo "Running Python Unit Tests..."
	@export LIB_P4TC_PATH=$(PWD)/$(LIB_NAME) && \
	export LD_LIBRARY_PATH=$(PWD):$$LD_LIBRARY_PATH && \
	$(PYTHON) -m unittest discover -s p4tc_py
	@echo "Running Rust Unit and Integration Tests..."
	@if [ -f $$HOME/.cargo/env ]; then . $$HOME/.cargo/env; fi; \
	cd $(RUST_DIR) && cargo test

# 5. Cleanup
clean:
	rm -f $(LIB_NAME)
	cd $(RUST_DIR) && cargo clean
	@echo "Cleanup complete."
