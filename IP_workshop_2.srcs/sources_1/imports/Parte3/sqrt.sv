`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2026 22:30:59
// Design Name: 
// Module Name: sqrt
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

module sqrt(
    input  logic        clk,
    input  logic        rst,
    input  logic        cordic_valid,
    input  logic [31:0] data_reg,
    output logic        cordic_ready,
    output logic [15:0] cordic_dout
);
    logic [31:0] start_val;
    logic [31:0] current_result;
    logic [31:0] next_result;
    logic [31:0] heron_step;

    typedef enum logic [1:0] {IDLE, ITERATE, STOP} state_t;
    state_t current_state, next_state;
    always_ff @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else     current_state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            current_result <= 32'd0;
            start_val      <= 32'd0;
        end else begin
            current_result <= next_result;
            if (current_state == IDLE && cordic_valid)
                start_val <= data_reg;
        end
    end


    always_comb begin
        next_state = IDLE;
        case (current_state)
            IDLE: begin
                if (cordic_valid) begin
                    if (data_reg <= 32'd1) next_state = STOP;
                    else next_state = ITERATE;
                end
            end
            ITERATE: begin
                if (heron_step >= current_result)
                    next_state = STOP;
                else
                    next_state = ITERATE;
            end
            STOP: begin
                next_state = IDLE;
            end
        endcase
    end
    always_comb begin
        cordic_dout  = 16'd0;
        cordic_ready = 1'b0;
        next_result  = current_result; 
        heron_step   = 32'd0;
        case (current_state)
            IDLE: begin
                if (data_reg <= 32'd1) next_result = data_reg;
                else next_result = (data_reg >> 1);
            end
            ITERATE: begin
                heron_step = (current_result + (start_val / current_result)) >> 1;
                if (heron_step < current_result)
                    next_result = heron_step; 
            end
            STOP: begin
                cordic_dout  = current_result[15:0];
                cordic_ready = 1'b1;
            end
        endcase
    end
endmodule