module axe_dv_interrupt_adapter #(
    parameter int IRQ_NUMBER = 64
)
(
    input bit clk,
    input bit rst_n,
    input string server_name,
    input bit [IRQ_NUMBER-1:0] interrupts,
    output bit update_pending
);

    // Max number of interrupts supported by Sifive's PLIC inside QEMU
    localparam int MAX_IRQ_NUMBER=520;

    if (MAX_IRQ_NUMBER < IRQ_NUMBER) begin
        $fatal("Too many interrupts: %0d. Max allowed is: %0d", IRQ_NUMBER, MAX_IRQ_NUMBER);
    end

    bit data_rdy;
    bit[IRQ_NUMBER-1:0] interrupts_prev;

    initial begin
        update_pending = 1'b0;
    end

    multisim_server_push #(
        .DATA_WIDTH(IRQ_NUMBER)
    ) i_multisim_server_push_test_interrupt (
        .clk        (clk),
        .server_name($sformatf("%s_interrupts", server_name)),
        .data_rdy   (data_rdy),
        .data_vld   (update_pending),
        .data       (interrupts)
    );

    always @(posedge clk) begin
        interrupts_prev <= interrupts;
        if (interrupts != interrupts_prev) begin
            update_pending <= 1'b1;
            $display("Sending interrupts=%0h", interrupts);
            @(posedge clk);
            while (!data_rdy) begin
                @(posedge clk);
            end
            update_pending <= 1'b0;
        end
    end
endmodule
