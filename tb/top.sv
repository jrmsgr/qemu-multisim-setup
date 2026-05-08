`timescale 1ns / 1ps

module top;

  reg clk;
  static string server_name = "multisim_server";

  // tbx clkgen
  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  bit [63:0] mem[1<<8];

  //-----------------------------------------------------------
  // exit
  //-----------------------------------------------------------
  bit exit;

  multisim_server_pull #(
      .DATA_WIDTH(1),
      .DPI_DELAY_CYCLES_INACTIVE(10000)
  ) i_multisim_server_pull_exit (
      .clk        (clk),
      .server_name($sformatf("%s_exit", server_name)),
      .data_rdy   (1),
      .data_vld   (exit),
      .data       (  /*unused*/)
  );

  always @(posedge clk) begin
    if (exit) begin
      $display("exit");
      $finish;
    end
  end

  //-----------------------------------------------------------
  // read/write
  //-----------------------------------------------------------
  import axi_pkg::*;

  bit      rst_n;

  axi_aw_t o_axi_m_aw;
  bit      i_axi_m_awready;
  bit      o_axi_m_awvalid;

  axi_w_t  o_axi_m_w;
  bit      i_axi_m_wready;
  bit      o_axi_m_wvalid;

  axi_b_t  i_axi_m_b;
  bit      o_axi_m_bready;
  bit      i_axi_m_bvalid;

  axi_ar_t o_axi_m_ar;
  bit      i_axi_m_arready;
  bit      o_axi_m_arvalid;

  axi_r_t  i_axi_m_r;
  bit      o_axi_m_rready;
  bit      i_axi_m_rvalid;
  axe_dv_axi_adapter i_axi_adapter(
    .clk(clk),
    .rst_n(rst_n),
    .server_name(server_name),

    .o_axi_m_aw(o_axi_m_aw),
    .i_axi_m_awready(i_axi_m_awready),
    .o_axi_m_awvalid(o_axi_m_awvalid),

    .o_axi_m_w(o_axi_m_w),
    .i_axi_m_wready(i_axi_m_wready),
    .o_axi_m_wvalid(o_axi_m_wvalid),

    .i_axi_m_b(i_axi_m_b),
    .o_axi_m_bready(o_axi_m_bready),
    .i_axi_m_bvalid(i_axi_m_bvalid),

    .o_axi_m_ar(o_axi_m_ar),
    .i_axi_m_arready(i_axi_m_arready),
    .o_axi_m_arvalid(o_axi_m_arvalid),

    .i_axi_m_r(i_axi_m_r),
    .o_axi_m_rready(o_axi_m_rready),
    .i_axi_m_rvalid(i_axi_m_rvalid)
  );

  dv_axi_ram #(
      .ADDR_WIDTH(AXI_ADDR_WIDTH),
      .DATA_WIDTH(AXI_DATA_WIDTH),
      .ID_WIDTH  (AXI_ID_WIDTH)
  ) i_dv_axi_ram (
      .clk          (clk),
      .rst          (~rst_n),
      .s_axi_awid   (o_axi_m_aw.id),
      .s_axi_awaddr (o_axi_m_aw.addr),
      .s_axi_awlen  (o_axi_m_aw.len),
      .s_axi_awsize (o_axi_m_aw.size),
      .s_axi_awburst(o_axi_m_aw.burst),
      .s_axi_awlock (o_axi_m_aw.lock),
      .s_axi_awcache(o_axi_m_aw.cache),
      .s_axi_awprot (o_axi_m_aw.prot),
      .s_axi_awvalid(o_axi_m_awvalid),
      .s_axi_awready(i_axi_m_awready),
      .s_axi_wdata  (o_axi_m_w.data),
      .s_axi_wstrb  (o_axi_m_w.strb),
      .s_axi_wlast  (o_axi_m_w.last),
      .s_axi_wvalid (o_axi_m_wvalid),
      .s_axi_wready (i_axi_m_wready),
      .s_axi_bid    (i_axi_m_b.id),
      .s_axi_bresp  (i_axi_m_b.resp),
      .s_axi_bvalid (i_axi_m_bvalid),
      .s_axi_bready (o_axi_m_bready),
      .s_axi_arid   (o_axi_m_ar.id),
      .s_axi_araddr (o_axi_m_ar.addr),
      .s_axi_arlen  (o_axi_m_ar.len),
      .s_axi_arsize (o_axi_m_ar.size),
      .s_axi_arburst(o_axi_m_ar.burst),
      .s_axi_arlock (o_axi_m_ar.lock),
      .s_axi_arcache(o_axi_m_ar.cache),
      .s_axi_arprot (o_axi_m_ar.prot),
      .s_axi_arvalid(o_axi_m_arvalid),
      .s_axi_arready(i_axi_m_arready),
      .s_axi_rid    (i_axi_m_r.id),
      .s_axi_rdata  (i_axi_m_r.data),
      .s_axi_rresp  (i_axi_m_r.resp),
      .s_axi_rlast  (i_axi_m_r.last),
      .s_axi_rvalid (i_axi_m_rvalid),
      .s_axi_rready (o_axi_m_rready)
  );

  initial begin
    $dumpfile("trace.vcd");
    $dumpvars();
    rst_n = 1'b0;
    repeat(100) begin
      @(posedge clk);
    end
    rst_n = 1'b1;
  end

  wire [63:0] axi_mem_0;
  assign axi_mem_0 = i_dv_axi_ram.mem[0];

endmodule
