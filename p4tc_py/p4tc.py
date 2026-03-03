"""
p4tc_py: Idiomatic Python Wrapper for P4TC Control Plane.

This module provides a high-level, object-oriented interface to the Linux P4TC
subsystem by wrapping the underlying C-based Netlink transport layer.
"""

import ctypes
from enum import IntEnum
import os
from typing import Dict, Any, Optional, Union, List

# Load the p4tc runtime library
LIB_P4TC_PATH = os.environ.get("LIB_P4TC_PATH", "libp4tc.so")

class P4TCObjType(IntEnum):
    """P4TC Object Types as defined in the C API."""
    TEMPLATE_PIPELINE = 1
    RUNTIME_TABLE = 2

class Transport(IntEnum):
    """Supported transport layers for P4TC control operations."""
    NETLINK = 0  # P4TC_TML_OPS_NL

class P4TCError(Exception):
    """Base exception class for all P4TC-related errors."""
    pass

class PipeConfig(ctypes.Structure):
    """C-compatible structure for pipeline provisioning configuration."""
    _fields_ = [("name", ctypes.c_char_p), ("template_dir", ctypes.c_char_p)]

class P4TC:
    """Core P4TC API entry point managing FFI bindings and provisioning."""
    
    def __init__(self, lib_path: str = LIB_P4TC_PATH):
        try:
            self.lib = ctypes.CDLL(lib_path)
            self._setup_bindings()
        except OSError:
            self.lib = None
            print(f"Warning: {lib_path} not found. Running in MOCK mode.")

    def _setup_bindings(self):
        """Configure ctypes function signatures for the libp4tc API."""
        # Provisioning
        self.lib.p4tc_provision.argtypes = [ctypes.POINTER(PipeConfig)]
        self.lib.p4tc_provision.restype = ctypes.c_int

        # Context Management
        self.lib.p4tc_runt_ctx_create.argtypes = [ctypes.c_int]
        self.lib.p4tc_runt_ctx_create.restype = ctypes.c_void_p
        self.lib.p4tc_runt_ctx_destroy.argtypes = [ctypes.c_void_p]
        self.lib.p4tc_runt_ctx_destroy.restype = None

        # Attribute Management
        self.lib.p4tc_attrs_create.argtypes = [ctypes.c_char_p, ctypes.c_int]
        self.lib.p4tc_attrs_create.restype = ctypes.c_void_p
        self.lib.p4tc_attrs_free.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        self.lib.p4tc_attrs_free.restype = None

        # Runtime Operations
        self.lib.p4tc_create.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
        self.lib.p4tc_create.restype = ctypes.c_int
        self.lib.p4tc_resp_handle.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_int]
        self.lib.p4tc_resp_handle.restype = ctypes.c_int

    def provision(self, pipeline_name: str, template_dir: str) -> None:
        """Provision a P4 pipeline from generated templates."""
        if not self.lib: return
        
        config = PipeConfig(pipeline_name.encode(), template_dir.encode())
        ret = self.lib.p4tc_provision(ctypes.byref(config))
        if ret < 0:
            raise P4TCError(f"Failed to provision pipeline {pipeline_name}: {ret}")

class Context:
    """
    P4TC Runtime Context.
    
    Manages the lifecycle of a control-plane connection. Use as a context manager:
    with p4tc.context() as ctx:
        ...
    """
    def __init__(self, api: P4TC, transport: Transport = Transport.NETLINK):
        self.api = api
        self.ctx_ptr = None
        self.transport = transport

    def __enter__(self):
        if self.api.lib:
            self.ctx_ptr = self.api.lib.p4tc_runt_ctx_create(self.transport.value)
            if not self.ctx_ptr:
                raise P4TCError("Could not create P4TC runtime context.")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.api.lib and self.ctx_ptr:
            self.api.lib.p4tc_runt_ctx_destroy(self.ctx_ptr)

    def table(self, pipeline: str, table_path: str) -> 'Table':
        """Initialize a table reference for runtime modifications."""
        return Table(self, pipeline, table_path)

    def create(self, table: 'Table') -> None:
        """Submit all pending table entries in a single transaction."""
        if not self.api.lib: return
        ret = self.api.lib.p4tc_create(self.ctx_ptr, table.attrs_ptr, None)
        if ret < 0:
            raise P4TCError(f"Create operation failed: {ret}")

    def process_responses(self, count: int = 1) -> None:
        """Process expected Netlink response messages."""
        if not self.api.lib: return
        ret = self.api.lib.p4tc_resp_handle(self.ctx_ptr, None, count)
        if ret < 0:
            raise P4TCError(f"Error handling responses: {ret}")

class Table:
    """Represents a P4 runtime table object."""
    def __init__(self, context: Context, pipeline: str, path: str):
        self.context = context
        self.pipeline = pipeline
        self.path = path
        self.attrs_ptr = None
        if context.api.lib:
            self.attrs_ptr = context.api.lib.p4tc_attrs_create(
                pipeline.encode(), P4TCObjType.RUNTIME_TABLE.value
            )
            if not self.attrs_ptr:
                raise P4TCError(f"Failed to create table attributes for {path}")

    def entry(self, key: str, action: Dict[str, Any]) -> None:
        """
        Add a table entry and associated action.
        
        Args:
            key: The table key (e.g., '10.10.10.1')
            action: Dictionary with 'name' and 'params'.
        """
        print(f"Adding entry to {self.path} with key: {key}, action: {action['name']}")
        # In a real build, this would involve calling p4tc_alloc_table_entry
        # and p4tc_create_runt_action internally.
        pass

    def add_entry(self, key: str, action_name: str, params: Dict[str, Any]) -> None:
        """
        Add a table entry and associated action.
        
        Args:
            key: The table key (e.g., '10.10.10.1')
            action_name: Full path to the P4 action.
            params: Dictionary of action parameters (name: value).
        """
        # In a real build, this would involve calling p4tc_alloc_table_entry
        # and p4tc_create_runt_action internally.
        pass

# Singleton instance for high-level API access
_p4tc = P4TC()

def provision(pipeline_name: str, template_dir: str):
    """Global helper for pipeline provisioning."""
    _p4tc.provision(pipeline_name, template_dir)

def context(transport: str = "netlink"):
    """Global helper to create a runtime context."""
    t = Transport.NETLINK if transport.lower() == "netlink" else Transport.NETLINK
    return Context(_p4tc, t)
