`timescale 1ns / 1ps

module TX_logic(
    input  logic        clk,
    input  logic        rst,
    input  logic        tx_busy,
    input  logic        send_word,
    input  logic        is_man_dist,
    input  logic        is_euc_dist,
    input  logic        is_dot_prod,
    input  logic [31:0] word_data,
    
    output logic [7:0]  tx_data,
    output logic        tx_start,
    output logic        tx_word_done
);
    logic [1:0]  byte_sel;
    logic [31:0] tx_word_reg;

    FSM_TX_ctrl FSM_TX_ctrl_inst (
        .clk          (clk),
        .rst          (rst),
        .tx_busy      (tx_busy),
        .send_word    (send_word),
        .is_man_dist  (is_man_dist),
        .is_euc_dist  (is_euc_dist),
        .is_dot_prod  (is_dot_prod),
        .tx_start     (tx_start),
        .byte_sel     (byte_sel),
        .tx_word_done (tx_word_done)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_word_reg <= 32'd0;
        end else if (send_word) begin
            tx_word_reg <= word_data;
        end
    end

    always_comb begin
        case (byte_sel)
            2'd0:    tx_data = tx_word_reg[7:0];
            2'd1:    tx_data = tx_word_reg[15:8];
            2'd2:    tx_data = tx_word_reg[23:16];
            2'd3:    tx_data = tx_word_reg[31:24];
            default: tx_data = 8'd0;
        endcase
    end

endmodule
