`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 16:22:03
// Design Name: 
// Module Name: sevenseg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module sevenseg_rom(
    input logic [3:0]in,
    output logic [6:0]segments
    );
    always_comb begin
        case(in)
            4'd0: segments =7'b0000001;
            4'd1: segments =7'b1001111;
            4'd2: segments =7'b0010010;
            4'd3: segments =7'b0000110;
            4'd4: segments =7'b1001100;
            4'd5: segments =7'b0100100;
            4'd6: segments =7'b1100000;
            4'd7: segments =7'b0001111;
            4'd8: segments =7'b0000000;
            4'd9: segments =7'b0001100;
            default: segments =7'b1111111;
        endcase
    end
endmodule