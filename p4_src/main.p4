/*
 * Vitis Networking P4 - PCIe TLP Processing Pipeline
 * 
 * This P4-16 program identifies Memory Read and Memory Write requests 
 * from 96-bit (3DW) and 128-bit (4DW) PCIe TLP headers.
 */

#include <core.p4>

/* 
 * PCIe TLP Header DW0 (32 bits)
 * Bit positions (Big Endian):
 * [31:29] Fmt
 * [28:24] Type
 * [23]    TC[2]
 * [22:21] Reserved
 * [20:19] TC[1:0]
 * [18]    Attr[2] (TH)
 * [17]    TD
 * [16]    EP
 * [15:14] Attr[1:0]
 * [13:12] AT
 * [11:10] Length[9:8]
 * [9:0]   Length[7:0]
 * Note: Mapping can vary by implementation. Below is a common P4 mapping.
 */
header tlp_dw0_h {
    bit<3>  fmt;
    bit<5>  type;
    bit<3>  tc;
    bit<1>  rsvd1;
    bit<1>  attr_hi; // TH
    bit<1>  td;
    bit<1>  ep;
    bit<2>  attr_lo;
    bit<2>  at;
    bit<10> length;
}

header tlp_dw1_h {
    bit<16> requester_id;
    bit<8>  tag;
    bit<4>  last_dw_be;
    bit<4>  first_dw_be;
}

/* 32-bit address for 3DW TLPs */
header tlp_3dw_addr_h {
    bit<32> address;
}

/* 64-bit address for 4DW TLPs */
header tlp_4dw_addr_h {
    bit<64> address;
}

struct headers {
    tlp_dw0_h      dw0;
    tlp_dw1_h      dw1;
    tlp_3dw_addr_h addr32;
    tlp_4dw_addr_h addr64;
}

struct metadata {
    bool is_mem_read;
    bool is_mem_write;
}

/*
 * Parser: Extracts PCIe TLP headers
 */
parser TopParser(packet_in packet, 
                 out headers hdr, 
                 inout metadata meta, 
                 inout standard_metadata_t std_meta) {
    state start {
        packet.extract(hdr.dw0);
        packet.extract(hdr.dw1);
        transition select(hdr.dw0.fmt) {
            3'b000: parse_3dw; // 3DW, No Data (e.g., Mem Read)
            3'b010: parse_3dw; // 3DW, With Data (e.g., Mem Write)
            3'b001: parse_4dw; // 4DW, No Data
            3'b011: parse_4dw; // 4DW, With Data
            default: accept;
        }
    }

    state parse_3dw {
        packet.extract(hdr.addr32);
        transition accept;
    }

    state parse_4dw {
        packet.extract(hdr.addr64);
        transition accept;
    }
}

/*
 * Ingress Control: Identifies Memory Read/Write requests
 */
control TopIngress(inout headers hdr, 
                   inout metadata meta, 
                   inout standard_metadata_t std_meta) {
    apply {
        if (hdr.dw0.isValid()) {
            // Memory requests have Type = 5'b00000
            if (hdr.dw0.type == 5'b00000) {
                // fmt[1] (bit 30 in DW0) indicates data presence
                // Fmt 00x: Read (No data), 01x: Write (With data)
                if (hdr.dw0.fmt[1:1] == 1'b1) {
                    meta.is_mem_write = true;
                    meta.is_mem_read  = false;
                } else {
                    meta.is_mem_write = false;
                    meta.is_mem_read  = true;
                }
            }
        }
    }
}

/*
 * Deparser: Reconstructs the PCIe TLP
 */
control TopDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.dw0);
        packet.emit(hdr.dw1);
        packet.emit(hdr.addr32);
        packet.emit(hdr.addr64);
    }
}

/*
 * Checksum controls (unused in this pipeline)
 */
control VerifyChecksum(inout headers hdr, inout metadata meta) { apply { } }
control ComputeChecksum(inout headers hdr, inout metadata meta) { apply { } }

/*
 * Top-level Switch Declaration
 * Note: Vitis Networking P4 uses specific architecture names (e.g., VitisNetP4).
 * This structure follows the standard V1Model for compatibility.
 */
#include <v1model.p4>
V1Model(
    TopParser(),
    VerifyChecksum(),
    TopIngress(),
    ComputeChecksum(),
    TopDeparser()
)
