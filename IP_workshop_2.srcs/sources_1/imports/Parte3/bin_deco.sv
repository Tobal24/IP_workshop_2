`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2026 20:16:00
// Design Name: 
// Module Name: bin_deco
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


module bin_deco(
    input logic [2:0] in_deco,                  // entrada {in_n,in_n-1...)
    output logic [7:0] out_deco                 // salida {out_n,out_n-1...)
    );
    
    always_comb begin
        case(in_deco)                           // no colocamos default pues se definió salida para todos los casos
            3'b000:  out_deco = 8'b11111110;
            3'b001:  out_deco = 8'b11111101;
            3'b010:  out_deco = 8'b11111011;
            3'b011:  out_deco = 8'b11110111;
            3'b100:  out_deco = 8'b11101111;
            3'b101:  out_deco = 8'b11011111;
            3'b110:  out_deco = 8'b10111111;
            3'b111:  out_deco = 8'b01111111;
        endcase
    end
endmodule
