`timescale 1ns / 1ps

module top(
    input  logic       clk,
    input  logic       resetN,
    input  logic       rx,
    output logic       tx,
    output logic       rx_pmod,
    output logic       tx_pmod,
    output logic [6:0] cathodes,
    output logic [7:0] anodes
);

    logic reset;
    logic clk_out1;
    logic locked;

    assign reset = ~resetN;

    clk_wiz_0 clk_i (
        .clk_in1  (clk),
        .reset    (reset),
        .clk_out1 (clk_out1),
        .locked   (locked)
    );

    logic       rx_in;
    logic       tx_in;
    logic [7:0] rx_data;
    logic       rx_ready;
    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;

    assign rx_in   = rx;
    assign tx      = tx_in;
    assign rx_pmod = rx;
    assign tx_pmod = tx_in;

    uart_basic uart (
        .clk      (clk_out1),
        .reset    (reset),
        .rx       (rx_in),
        .rx_data  (rx_data),
        .rx_ready (rx_ready),
        .tx       (tx_in),
        .tx_data  (tx_data),
        .tx_start (tx_start),
        .tx_busy  (tx_busy)
    );

    // Señales de escritura desde RX_Logic hacia las BRAM
    logic        ena;
    logic        wea;
    logic [9:0]  addra;
    logic [10:0] dina;
    logic        rx_bram_sel; 
    logic        rx_busy;

    // Señales desde Command_Decoder hacia Processing_Core, TX_logic y Display_logic
    logic        start_op;
    logic [2:0]  op_mode;
    logic        is_man_dist;
    logic        is_euc_dist;
    logic        is_dot_prod;

    // Señales de lectura (manejadas por Processing_Core) y resultados
    logic        enb;
    logic [9:0]  addrb;
    logic [31:0] result_data;
    logic        result_valid;
    logic        tx_word_done;

    // BRAM_A write (Puerto A)
    logic        ena_A;
    logic        wea_A;
    logic [9:0]  addra_A;
    logic [10:0] dina_A;
    logic [10:0] douta_A;

    // BRAM_A read (Puerto B)
    logic        enb_A;
    logic        web_A;
    logic [9:0]  addrb_A;
    logic [10:0] dinb_A;
    logic [10:0] doutb_A;

    // BRAM_B write (Puerto A)
    logic        ena_B;
    logic        wea_B;
    logic [9:0]  addra_B;
    logic [10:0] dina_B;
    logic [10:0] douta_B; 

    // BRAM_B read (Puerto B)
    logic        enb_B;
    logic        web_B;
    logic [9:0]  addrb_B;
    logic [10:0] dinb_B;
    logic [10:0] doutb_B;

    assign addra_A = addra;
    assign addra_B = addra;
    assign dina_A  = dina;
    assign dina_B  = dina;

    assign ena_A   = (rx_bram_sel == 1'b0) ? ena : 1'b0;
    assign ena_B   = (rx_bram_sel == 1'b1) ? ena : 1'b0;
    assign wea_A   = (rx_bram_sel == 1'b0) ? wea : 1'b0;
    assign wea_B   = (rx_bram_sel == 1'b1) ? wea : 1'b0;

    assign web_A   = 1'b0;
    assign dinb_A  = 11'd0;
    assign web_B   = 1'b0;
    assign dinb_B  = 11'd0;

    assign enb_A   = enb;
    assign enb_B   = enb;
    assign addrb_A = addrb;
    assign addrb_B = addrb;

    blk_mem_gen_0 BRAM_A (
        .clka  (clk_out1),
        .ena   (ena_A),
        .wea   (wea_A),
        .addra (addra_A),
        .dina  (dina_A),
        .douta (douta_A),
        .clkb  (clk_out1),
        .enb   (enb_A),
        .web   (web_A),
        .addrb (addrb_A),
        .dinb  (dinb_A),
        .doutb (doutb_A)
    );

    blk_mem_gen_0 BRAM_B (
        .clka  (clk_out1),
        .ena   (ena_B),
        .wea   (wea_B),
        .addra (addra_B),
        .dina  (dina_B),
        .douta (douta_B),
        .clkb  (clk_out1),
        .enb   (enb_B),
        .web   (web_B),
        .addrb (addrb_B),
        .dinb  (dinb_B),
        .doutb (doutb_B)
    );

    RX_Logic #(
        .MEMORY_DEPTH(1024)
    ) FSM_RX (
        .clk           (clk_out1),
        .rst           (reset),
        .rx_ready      (rx_ready),
        .rx_data       (rx_data),
        .enable        (ena),
        .write_enable  (wea),
        .write_address (addra),
        .write_data    (dina),
        .rx_bram_sel   (rx_bram_sel),
        .rx_busy       (rx_busy)
    );

    Command_Decoder cmd_decoder (
        .clk         (clk_out1),
        .rst         (reset),
        .rx_ready    (rx_ready),
        .rx_data     (rx_data),
        .rx_busy     (rx_busy),
        .start_op    (start_op),
        .op_mode     (op_mode),
        .is_man_dist (is_man_dist),
        .is_euc_dist (is_euc_dist),
        .is_dot_prod (is_dot_prod)
    );

    Processing_Core #(
        .MEMORY_DEPTH(1024)
    ) proc_core (
        .clk          (clk_out1),
        .rst          (reset),
        .start_op     (start_op),
        .op_mode      (op_mode),
        .is_man_dist  (is_man_dist),
        .is_euc_dist  (is_euc_dist),
        .is_dot_prod  (is_dot_prod),
        .doutb_A      (doutb_A),
        .doutb_B      (doutb_B),
        .tx_word_done (tx_word_done),
        .read_address (addrb),
        .read_enable  (enb),
        .result_data  (result_data),
        .result_valid (result_valid)
    );

    TX_logic FSM_TX (
        .clk          (clk_out1),
        .rst          (reset),
        .tx_busy      (tx_busy),
        .send_word    (result_valid),
        .is_man_dist  (is_man_dist),
        .is_euc_dist  (is_euc_dist),
        .is_dot_prod  (is_dot_prod),
        .word_data    (result_data),
        .tx_data      (tx_data),
        .tx_start     (tx_start),
        .tx_word_done (tx_word_done)
    );

    Display_logic display_logic_inst (
        .clk          (clk_out1),
        .rst          (reset),
        .result_valid (result_valid),
        .is_man_dist  (is_man_dist),
        .is_euc_dist  (is_euc_dist),
        .is_dot_prod  (is_dot_prod),
        .result_data  (result_data),
        .cathodes     (cathodes),
        .anodes       (anodes)
    );

endmodule
