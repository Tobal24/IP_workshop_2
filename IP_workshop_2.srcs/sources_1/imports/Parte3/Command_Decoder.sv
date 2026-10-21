`timescale 1ns / 1ps

module Command_Decoder(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx_ready,
    input  logic [7:0] rx_data,
    input  logic       rx_busy,
    
    output logic       start_op,
    output logic [2:0] op_mode,
    output logic       is_man_dist,
    output logic       is_euc_dist,
    output logic       is_dot_prod
);

    logic cmd_valid;
    assign cmd_valid = rx_ready && !rx_busy && (rx_data >= 8'd2 && rx_data <= 8'd8);

    always_ff @(posedge clk) begin
        if (rst) begin
            op_mode  <= 3'b000;
            start_op <= 1'b0;
        end else begin
            start_op <= cmd_valid;
            if (cmd_valid) begin
                case (rx_data)
                    8'd2:    op_mode <= 3'b000; // Comando 2: Leer BRAM A
                    8'd3:    op_mode <= 3'b001; // Comando 3: Leer BRAM B
                    8'd4:    op_mode <= 3'b010; // Comando 4: SumVec (A + B)
                    8'd5:    op_mode <= 3'b011; // Comando 5: AvgVec (A + B) / 2
                    8'd6:    op_mode <= 3'b100; // Comando 6: ManDist |A - B|
                    8'd7:    op_mode <= 3'b101; // Comando 7: EucDist sqrt(sum((A - B)^2))
                    8'd8:    op_mode <= 3'b110; // Comando 8: DotProd (A . B)
                    default: op_mode <= 3'b000;
                endcase
            end
        end
    end

    assign is_man_dist = (op_mode == 3'b100);
    assign is_euc_dist = (op_mode == 3'b101);
    assign is_dot_prod = (op_mode == 3'b110);

endmodule
