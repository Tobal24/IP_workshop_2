`timescale 1ns / 1ps

module Display_logic(
    input  logic        clk,
    input  logic        rst,
    input  logic        result_valid,
    input  logic        is_man_dist,
    input  logic        is_euc_dist,
    input  logic        is_dot_prod,
    input  logic [31:0] result_data,
    
    output logic [6:0]  cathodes,
    output logic [7:0]  anodes
);

    logic is_scalar;
    assign is_scalar = is_man_dist || is_euc_dist || is_dot_prod;

    // Conversión Binario a BCD (usando módulo unsigned_to_bcd de ELO212)
    logic        display_en;
    logic        dd_idle;
    logic [31:0] bcd_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            display_en <= 1'b0;
        end else if (result_valid) begin
            display_en <= is_scalar;
        end
    end

    unsigned_to_bcd u32_to_bcd_inst (
        .clk     (clk),
        .reset   (rst),
        .trigger (result_valid && is_scalar),
        .in      (result_data),
        .idle    (dd_idle),
        .bcd     (bcd_reg)
    );

    // Contador para multiplexación por división de tiempo (TDM) de los 8 displays
    logic [19:0] refresh_cnt;
    logic [2:0]  anode_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            refresh_cnt <= 20'd0;
        end else begin
            refresh_cnt <= refresh_cnt + 20'd1;
        end
    end

    assign anode_sel = refresh_cnt[19:17];

    // Decodificador de ánodos usando el módulo bin_deco
    logic [7:0] anodes_deco;
    bin_deco anode_deco_inst (
        .in_deco  (anode_sel),
        .out_deco (anodes_deco)
    );

    assign anodes = display_en ? anodes_deco : 8'b11111111;

    // Selección del dígito BCD activo y decodificación a 7 segmentos usando sevenseg_rom
    logic [3:0] current_digit;
    always_comb begin
        if (!display_en) begin
            current_digit = 4'hF; // Apaga todos los segmentos (default en sevenseg_rom)
        end else begin
            case (anode_sel)
                3'd0:    current_digit = bcd_reg[3:0];
                3'd1:    current_digit = bcd_reg[7:4];
                3'd2:    current_digit = bcd_reg[11:8];
                3'd3:    current_digit = bcd_reg[15:12];
                3'd4:    current_digit = bcd_reg[19:16];
                3'd5:    current_digit = bcd_reg[23:20];
                3'd6:    current_digit = bcd_reg[27:24];
                3'd7:    current_digit = bcd_reg[31:28];
                default: current_digit = 4'hF;
            endcase
        end
    end

    sevenseg_rom sevenseg_inst (
        .in       (current_digit),
        .segments (cathodes)
    );

endmodule
