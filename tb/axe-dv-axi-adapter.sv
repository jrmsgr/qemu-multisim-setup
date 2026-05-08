module axe_dv_axi_adapter import axi_pkg::*; (
    input bit clk,
    input bit rst_n,
    input string server_name,

    output axi_aw_t o_axi_m_aw,
    input  bit      i_axi_m_awready,
    output bit      o_axi_m_awvalid,

    output axi_w_t  o_axi_m_w,
    input  bit      i_axi_m_wready,
    output bit      o_axi_m_wvalid,

    input  axi_b_t  i_axi_m_b,
    output bit      o_axi_m_bready,
    input  bit      i_axi_m_bvalid,

    output axi_ar_t o_axi_m_ar,
    input  bit      i_axi_m_arready,
    output bit      o_axi_m_arvalid,

    input  axi_r_t  i_axi_m_r,
    output bit      o_axi_m_rready,
    input  bit      i_axi_m_rvalid
);
    // command format:
    // [AXI_CMD_WORD_WIDTH-1:0]:                                command (r/w)
    // [AXI_CMD_WORD_WIDTH+:AXI_CMD_WORD_WIDTH]:                size    (8, 4, 2, 1)
    // [AXI_CMD_WORD_WIDTH*2+:AXI_ADDR_WIDTH]:                  address
    // [(AXI_CMD_WORD_WIDTH*2+AXI_ADDR_WIDTH)+:AXI_DATA_WIDTH]: data
    localparam int AXI_CMD_WORD_WIDTH = AXI_DATA_WIDTH/2;
    localparam int AXI_CMD_WIDTH = (AXI_CMD_WORD_WIDTH*2 + AXI_DATA_WIDTH + AXI_ADDR_WIDTH);

    // [AXI_ADDR_WIDTH-1:0]:               AXI  response
    // [AXI_DATA_WIDTH-1+:AXI_DATA_WIDTH]: data (read commands only)
    localparam int AXI_RSP_WIDTH = (2*AXI_DATA_WIDTH);

    task write_data(input bit[AXI_ADDR_WIDTH-1:0] addr, input bit[31:0] size,
                    input bit[AXI_DATA_WIDTH-1:0] data, output bit[AXI_RSP_WIDTH-1:0] resp);
        automatic bit[31:0] size_axi;

        // TODO: Add proper protocol checks
        assert (size <= AXI_DATA_WIDTH) else $display("size must be less than %0d! Got size: %0d", AXI_DATA_WIDTH, size);

        size_axi = $clog2(size/8)-1;

        o_axi_m_aw = axi_aw_t'{
            id: 0,
            addr: addr,
            len: 0,
            size: size_axi[2:0],
            burst: 0,
            lock: 0,
            cache: 0,
            prot: 0,
            qos: 0,
            region: 0
        };

        o_axi_m_awvalid <= 1'b1;
        @(posedge clk);
        while(i_axi_m_awready !== 1'b1) begin
            @(posedge clk);
        end
        o_axi_m_awvalid <= 1'b0;

        o_axi_m_w = axi_w_t'{
            id: 0,
            data: data<<8*(addr%AXI_STRB_WIDTH),
            strb: ((1<<(size/8))-1) << (addr%AXI_STRB_WIDTH),
            last: 1
        };

        o_axi_m_wvalid <= 1'b1;
        @(posedge clk);
        while(i_axi_m_wready !== 1'b1) begin
            @(posedge clk);
        end
        o_axi_m_wvalid <= 1'b0;

        o_axi_m_bready <= 1'b1;
        @(posedge clk);
        while(i_axi_m_bvalid !== 1'b1) begin
            @(posedge clk);
        end
        o_axi_m_bready <= 1'b0;

        resp[0+:AXI_DATA_WIDTH] = {{AXI_DATA_WIDTH-2{1'b0}}, i_axi_m_b.resp};
        resp[AXI_DATA_WIDTH+:AXI_DATA_WIDTH] = 0;
    endtask

    task read_data(input bit[AXI_ADDR_WIDTH-1:0] addr, input bit[31:0] size,
                   output bit[AXI_RSP_WIDTH-1:0] resp);
        automatic bit[31:0] size_axi;

        // TODO: Add proper protocol checks
        assert (size <= AXI_DATA_WIDTH) else $display("size must be less than %0d! Got size: %0d", AXI_DATA_WIDTH, size);

        size_axi = $clog2(size/8)-1;

        o_axi_m_ar = axi_ar_t'{
            id: 0,
            addr: addr,
            len: 0,
            size: size_axi[2:0],
            burst: 0,
            lock: 0,
            cache: 0,
            prot: 0,
            qos: 0,
            region: 0
        };

        o_axi_m_arvalid <= 1'b1;
        @(posedge clk);
        while(i_axi_m_arready !== 1'b1) begin
            @(posedge clk);
        end
        o_axi_m_arvalid <= 1'b0;
        o_axi_m_rready <= 1'b1;
        @(posedge clk);
        while(i_axi_m_rvalid !== 1'b1) begin
            @(posedge clk);
        end
        o_axi_m_rready <= 1'b0;

        resp[0+:AXI_DATA_WIDTH] = {{AXI_DATA_WIDTH-2{1'b0}}, i_axi_m_r.resp};
        resp[AXI_DATA_WIDTH+:AXI_DATA_WIDTH] = (i_axi_m_r.data >> 8*(addr%AXI_STRB_WIDTH)) & ((1<<size)-1);
    endtask

    bit rw_cmd_rdy;
    bit rw_cmd_vld;
    bit [AXI_CMD_WIDTH-1:0] rw_cmd;

    bit [AXI_CMD_WORD_WIDTH-1:0] rw_cmd_rwb;
    bit [AXI_CMD_WORD_WIDTH-1:0] rw_cmd_size;
    bit [AXI_ADDR_WIDTH-1:0] rw_cmd_addr;
    bit [AXI_DATA_WIDTH-1:0] rw_cmd_data;

    always_comb rw_cmd_rwb = rw_cmd[0+:AXI_CMD_WORD_WIDTH];
    always_comb rw_cmd_size = rw_cmd[AXI_CMD_WORD_WIDTH+:AXI_CMD_WORD_WIDTH];
    always_comb rw_cmd_addr = rw_cmd[AXI_CMD_WORD_WIDTH*2 +: AXI_ADDR_WIDTH];
    always_comb rw_cmd_data = rw_cmd[(AXI_CMD_WORD_WIDTH*2+AXI_ADDR_WIDTH) +:AXI_DATA_WIDTH];

    bit rw_rsp_rdy;
    bit rw_rsp_vld;
    bit [AXI_RSP_WIDTH-1:0] rw_rsp;

    multisim_server_pull_then_push #(
        .PULL_DATA_WIDTH(AXI_CMD_WIDTH),
        .PUSH_DATA_WIDTH(AXI_RSP_WIDTH)
    ) i_multisim_server_rw (
        .clk             (clk),
        // pull
        .pull_server_name($sformatf("%s_rw_cmd", server_name)),
        .pull_data_rdy   (rw_cmd_rdy),
        .pull_data_vld   (rw_cmd_vld),
        .pull_data       (rw_cmd),
        // push
        .push_server_name($sformatf("%s_rw_rsp", server_name)),
        .push_data_rdy   (rw_rsp_rdy),
        .push_data_vld   (rw_rsp_vld),
        .push_data       (rw_rsp)
    );

    always @(posedge clk) begin
        rw_cmd_rdy <= 1;
        @(posedge clk);
        while (!rw_cmd_vld) begin
            @(posedge clk);
        end
        rw_cmd_rdy <= 0;

        if (rw_cmd_rwb > 0) begin
            read_data(rw_cmd_addr, rw_cmd_size, rw_rsp);
        end else begin
            write_data(rw_cmd_addr, rw_cmd_size, rw_cmd_data, rw_rsp);
        end
      
        rw_rsp_vld <= 1;
        @(posedge clk);
        while (!rw_rsp_rdy) begin
            @(posedge clk);
        end
        rw_rsp_vld <= 0;
    end
endmodule
