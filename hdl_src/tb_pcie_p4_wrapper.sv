/**
 * tb_pcie_p4_wrapper.sv
 * 
 * Testbench for pcie_p4_wrapper.
 * Verifies the AXI4-Stream path by injecting a mocked PCIe Memory Write TLP.
 */

`timescale 1ns / 1ps

module tb_pcie_p4_wrapper();

    parameter integer DATA_WIDTH = 256;
    parameter integer KEEP_WIDTH = DATA_WIDTH / 8;
    parameter integer CQ_USER_WIDTH = 85;
    parameter integer RQ_USER_WIDTH = 62;

    logic                   clk;
    logic                   reset_n;

    /* CQ Interface (Input to Wrapper) */
    logic [DATA_WIDTH-1:0]  s_axis_cq_tdata;
    logic [KEEP_WIDTH-1:0]  s_axis_cq_tkeep;
    logic                   s_axis_cq_tlast;
    logic [CQ_USER_WIDTH-1:0] s_axis_cq_tuser;
    logic                   s_axis_cq_tvalid;
    logic                   s_axis_cq_tready;

    /* RQ Interface (Output from Wrapper) */
    logic [DATA_WIDTH-1:0]  m_axis_rq_tdata;
    logic [KEEP_WIDTH-1:0]  m_axis_rq_tkeep;
    logic                   m_axis_rq_tlast;
    logic [RQ_USER_WIDTH-1:0] m_axis_rq_tuser;
    logic                   m_axis_rq_tvalid;
    logic                   m_axis_rq_tready;

    /* 250MHz Clock Generation */
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    /* Reset Logic */
    initial begin
        reset_n = 0;
        #100;
        reset_n = 1;
    end

    /* Instantiate the Wrapper */
    pcie_p4_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .CQ_USER_WIDTH(CQ_USER_WIDTH),
        .RQ_USER_WIDTH(RQ_USER_WIDTH)
    ) dut (
        .user_clk(clk),
        .user_reset_n(reset_n),

        .s_axis_cq_tdata(s_axis_cq_tdata),
        .s_axis_cq_tkeep(s_axis_cq_tkeep),
        .s_axis_cq_tlast(s_axis_cq_tlast),
        .s_axis_cq_tuser(s_axis_cq_tuser),
        .s_axis_cq_tvalid(s_axis_cq_tvalid),
        .s_axis_cq_tready(s_axis_cq_tready),

        .m_axis_rq_tdata(m_axis_rq_tdata),
        .m_axis_rq_tkeep(m_axis_rq_tkeep),
        .m_axis_rq_tlast(m_axis_rq_tlast),
        .m_axis_rq_tuser(m_axis_rq_tuser),
        .m_axis_rq_tvalid(m_axis_rq_tvalid),
        .m_axis_rq_tready(m_axis_rq_tready)
    );

    /* 
     * Mocked PCIe Memory Write TLP (3-DW Header + 1-DW Data)
     * DW0: 0x40000001 (Fmt: 3DW with data, Type: Mem, Length: 1)
     * DW1: 0x00000F0F (ReqID: 0, Tag: 0, BE: 0xF)
     * DW2: 0x12345678 (Address)
     * Data: 0xDEADBEEF
     */
    logic [127:0] mock_tlp = {32'hDEADBEEF, 32'h12345678, 32'h00000F0F, 32'h40000001};

    /* Stimulus Process */
    initial begin
        // Initialize signals
        s_axis_cq_tdata  = 0;
        s_axis_cq_tkeep  = 0;
        s_axis_cq_tlast  = 0;
        s_axis_cq_tuser  = 0;
        s_axis_cq_tvalid = 0;
        m_axis_rq_tready = 1; // Always ready to receive from P4

        wait(reset_n == 1);
        @(posedge clk);

        /* Inject 3-DW Memory Write TLP */
        $display("[%0t] Injecting PCIe Memory Write TLP...", $time);
        s_axis_cq_tdata  = { {(DATA_WIDTH-128){1'b0}}, mock_tlp };
        s_axis_cq_tkeep  = { {(KEEP_WIDTH-16){1'b0}}, 16'hFFFF };
        s_axis_cq_tlast  = 1;
        s_axis_cq_tvalid = 1;

        // Wait for handshaking
        do begin
            @(posedge clk);
        end while (!s_axis_cq_tready);

        s_axis_cq_tvalid = 0;
        s_axis_cq_tlast  = 0;
        $display("[%0t] Injection complete.", $time);
    end

    /* Monitor Process */
    initial begin
        wait(reset_n == 1);
        forever begin
            @(posedge clk);
            if (m_axis_rq_tvalid && m_axis_rq_tready) begin
                $display("[%0t] SUCCESS: Packet detected on RQ output interface!", $time);
                $display("[%0t] Data: 0x%h", $time, m_axis_rq_tdata);
                #100;
                $finish;
            end
        end
    end

    /* Timeout */
    initial begin
        #5000;
        $display("[%0t] ERROR: Simulation timed out!", $time);
        $finish;
    end

endmodule

/**
 * Dummy module for vitis_net_p4_0 to allow simulation without the actual IP
 */
module vitis_net_p4_0 (
    input  logic         s_axis_aclk,
    input  logic         s_axis_aresetn,
    input  logic [255:0] s_axis_tdata,
    input  logic [31:0]  s_axis_tkeep,
    input  logic         s_axis_tlast,
    input  logic [84:0]  s_axis_tuser,
    input  logic         s_axis_tvalid,
    output logic         s_axis_tready,
    output logic [255:0] m_axis_tdata,
    output logic [31:0]  m_axis_tkeep,
    output logic         m_axis_tlast,
    output logic [61:0]  m_axis_tuser,
    output logic         m_axis_tvalid,
    input  logic         m_axis_tready
);
    // Simple passthrough for simulation purposes
    assign m_axis_tdata  = s_axis_tdata;
    assign m_axis_tkeep  = s_axis_tkeep;
    assign m_axis_tlast  = s_axis_tlast;
    assign m_axis_tuser  = s_axis_tuser[61:0]; // Truncate user bits for dummy
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
endmodule
