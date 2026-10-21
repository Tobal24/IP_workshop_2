`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2025 04:34:17 PM
// Design Name: 
// Module Name: FSM_RX_ctrl
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


module FSM_RX_ctrl#(
    parameter MEMORY_DEPTH = 1024
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       rx_ready,
    input  logic [7:0] rx_data,
    input  logic       last_address, 
    output logic       enable,
    output logic       write_enable,
    output logic       save_header,        
    output logic       save_lsb,
    output logic       rx_busy
);
    
    typedef enum logic [1:0] {WAIT_ADDR, READ_BYTE_1, READ_BYTE_2, WRITE_BYTE} state_t;
    state_t state, state_next;
    
    always_ff @(posedge clk) begin   
        if (rst) begin
            state <= WAIT_ADDR;
        end
        else begin
            state <= state_next;
        end 
    end

    always_comb begin
        state_next = state;      
        case(state)
            // Espera el byte de cabecera: 0 (BRAM A) o 1 (BRAM B)
            WAIT_ADDR: begin
                if (rx_ready && (rx_data == 8'b0 || rx_data == 8'b1)) begin
                    state_next = READ_BYTE_1;
                end
            end
            // recibe lsb
            READ_BYTE_1: begin
                if (rx_ready) begin
                    state_next = READ_BYTE_2;
                end
            end
            // recibe msb
            READ_BYTE_2: begin
                if (rx_ready) begin
                    state_next = WRITE_BYTE;
                end
            end
            // escritura
            WRITE_BYTE: begin
                if (last_address) //fin de la memoria
                    state_next = WAIT_ADDR;   
                else
                    state_next = READ_BYTE_1; 
            end
            default: begin
                state_next = WAIT_ADDR;
            end
        endcase
    end
    
    assign save_header  = (state == WAIT_ADDR)   && rx_ready && (rx_data == 8'b0 || rx_data == 8'b1);
    assign save_lsb     = (state == READ_BYTE_1) && rx_ready;
    assign enable       = (state == WRITE_BYTE);
    assign write_enable = (state == WRITE_BYTE);
    assign rx_busy      = (state != WAIT_ADDR);
endmodule