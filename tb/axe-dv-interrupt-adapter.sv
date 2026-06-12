module axe_dv_interrupt_adapter (
    input bit clk,
    input bit rst_n,
    input string server_name,
    input bit [63:0] interrupts,
    output bit interrupt_pending
);

    bit data_rdy;
    bit[63:0] interrupts_prev;

    initial begin
        interrupt_pending = 1'b0;
    end

    multisim_server_push #(
        .DATA_WIDTH(1)
    ) i_multisim_server_push_test_interrupt (
        .clk        (clk),
        .server_name($sformatf("%s_interrupts", server_name)),
        .data_rdy   (data_rdy),
        .data_vld   (interrupt_pending),
        .data       (interrupts)
    );

    always @(posedge clk) begin
        interrupts_prev <= interrupts;
        if (interrupts != interrupts_prev) begin
            interrupt_pending <= 1'b1;
            $display("Sending interrupts=%0h", interrupts);
            @(posedge clk);
            while (!data_rdy) begin
                @(posedge clk);
            end
            interrupt_pending <= 1'b0;
        end
    end
endmodule
