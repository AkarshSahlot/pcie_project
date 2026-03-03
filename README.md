# 🚀 Project 2.3: PCIe TLP Communication Framework using P4

This project demonstrates the versatility of the **P4 language** by applying it to low-layer device interconnect protocols, specifically **PCIe (Peripheral Component Interconnect Express)**. 

By combining **AMD Xilinx PCIe UltraScale+ IP** and **Vitis Networking P4 IP**, we enable high-speed analysis, control, and forwarding of **Transaction Layer Packets (TLPs)** directly in the FPGA hardware.

---

## 🏗️ System Architecture

The framework consists of three primary layers:

### 1. Hardware Logic (`hdl_src/`)
- **PCIe Bridge:** A SystemVerilog wrapper (`pcie_p4_wrapper.sv`) that connects the PCIe IP's AXI-Stream interfaces (CQ, RQ, RC, CC) to the P4 processing engine.
- **Data Flow:** 
    - **CQ (Completer Request):** Inbound TLPs from the Host.
    - **RQ (Requester Request):** Outbound TLPs to the Host (DMA).

### 2. P4 Datapath (`p4_src/`)
- **TLP Parsing:** A P4-16 program (`main.p4`) that understands PCIe header structures:
    - **DW0/DW1:** Basic TLP attributes (Type, Format, Length).
    - **3DW/4DW:** Address parsing for Memory Read/Write operations.
- **Logic:** Enables runtime decisions based on TLP headers, such as routing, security filtering, or protocol translation.

### 3. Control Plane Wrappers (`p4tc_py/` & `p4tc_rs/`)
To manage the hardware, we provide **Polyglot P4TC** wrappers that interface with the Linux P4TC (Traffic Control) subsystem:
- **C-API (`libp4tc`)**: The low-level bridge using Netlink to communicate with the kernel/hardware.
- **Python API:** Idiomatic wrapper for rapid prototyping and scripting.
- **Rust API:** Memory-safe, high-performance API for systems-level integration.

---

## 🎯 Project Goals

### Phase 1: Basic TLP Processing (Current Focus)
- Parse and Deparse 128-bit/96-bit PCIe descriptors.
- Implement a demo where a register write (CQ) triggers a P4-controlled DMA write (RQ).
- Enable the PCIe device to be recognized by Linux with custom **Class Codes** (e.g., NVMe, GPU) instead of a standard NIC.

### Phase 2: Peer-to-Peer (P2P) Communication
- Direct TLP exchange between multiple Alveo FPGAs.
- Implement PCIe Switch routing control using P4 Match-Action tables.
- Bypass host memory to reduce latency and CPU overhead.

---

## 🛠️ Implementation Details

This repository provides a complete vertical slice of the **Project 2.3** framework, from hardware wires to high-level software APIs.

### 1. Hardware Layer: The Bridge (`hdl_src/`)
This is the physical connection between the **PCIe bus** and the **P4 engine**.
*   **`pcie_p4_wrapper.sv`**: Acts as the "glue" logic. It captures the **Completer Request (CQ)** stream from the Xilinx PCIe IP and feeds it into the **Vitis Networking P4 IP**.
*   It also maps the P4 output to the **Requester Request (RQ)** interface, enabling the FPGA to perform DMA operations.

### 2. Datapath Layer: The P4 Logic (`p4_src/`)
The "brain" of the TLP processing pipeline.
*   **`main.p4`**: Implements **Phase 1** by defining headers for PCIe TLPs instead of standard network protocols.
    *   **Parser:** A state machine that identifies **3DW (32-bit)** and **4DW (64-bit)** TLP headers.
    *   **Ingress Control:** Logic that distinguishes between **Memory Reads** and **Memory Writes** based on the TLP `type` and `fmt` fields.

### 3. Control Plane: API Wrappers (`p4tc_py/`, `p4tc_rs/`, `p4tc_src/`)
Provides the programmability required by the P4 ecosystem.
*   **`p4tc_src/libp4tc.c`**: A C-based runtime library that simulates the **Linux P4TC (Traffic Control)** subsystem.
*   **`p4tc_py/`**: A Python wrapper using `ctypes` for rapid prototyping and scripting of TLP filtering rules.
*   **`p4tc_rs/`**: A memory-safe Rust wrapper for high-performance, production-grade driver integration.

### 4. Automation & Validation (`Makefile`, `run_sim.sh`)
*   **`Makefile`**: Automates the compilation of the C library, Python environment, and Rust crates.
*   **`run_sim.sh`**: Triggers a **Vivado simulation** using the scripts in `scripts/` to verify that the Verilog wrapper and P4 logic correctly parse PCIe packets.

---

## 🛠️ Getting Started

### Prerequisites
- **Vivado Design Suite 2024.2+**
- **Vitis Networking P4 IP License**
- **Ubuntu 22.04 LTS**
- GCC, Python 3, and Rust/Cargo.

### Build Instructions
```bash
# Build the C library and run all tests (Python & Rust)
make all
```

### Running Simulation
The simulation environment uses a mock PCIe root complex to verify TLP parsing:
```bash
./run_sim.sh
```

---

## 🤝 Acknowledgments
- **Mentor:** Takeoki Oura (@iHalt10)
- **Support:** Ali Imran
- **Resources:** [VNP4 Framework](https://github.com/iHalt10/vnp4_framework), [PCIe Subsystem](https://github.com/iHalt10/pcie_subsystem).
