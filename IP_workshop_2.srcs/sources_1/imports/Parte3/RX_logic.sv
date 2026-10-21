`timescale 1ns / 1ps

module RX_Logic#(
    parameter MEMORY_DEPTH = 1024
)(
    input  logic clk,
    input  logic rst,
    input  logic rx_ready,
    input  logic [7:0] rx_data,
    
    // Bram write
    output logic enable,
    output logic write_enable,
    output logic [$clog2(MEMORY_DEPTH)-1:0] write_address,
    output logic [10:0] write_data,
    output logic rx_bram_sel, 
    
    // Estado hacia Command_Decoder
    output logic rx_busy
);

    logic save_header;
    logic save_lsb;
    logic last_address;
    logic [7:0] lsb_reg;


    FSM_RX_ctrl #(
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) FSM_RX_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .rx_ready(rx_ready),
        .rx_data(rx_data),
        .last_address(last_address),
        .enable(enable),
        .write_enable(write_enable),
        .save_header(save_header),
        .save_lsb(save_lsb),
        .rx_busy(rx_busy)
    );

    // guardar lsb
    always_ff @(posedge clk) begin
        if (rst) begin
            lsb_reg <= 8'd0;
        end else if (save_lsb) begin
            lsb_reg <= rx_data;
        end
    end

    // Bram write select
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_bram_sel <= 1'b0;
        end else if (save_header) begin
            rx_bram_sel <= rx_data[0];
        end
    end

    //armar palabras
    assign write_data = {rx_data[2:0], lsb_reg};
    assign last_address = (write_address == (MEMORY_DEPTH - 1));

    //registro de dirección
    always_ff @(posedge clk) begin   
        if (rst || save_header) begin
            write_address <= '0;
        end else if (write_enable) begin
            if (last_address)
                write_address <= '0;
            else
                write_address <= write_address + 1'b1;
        end 
    end
        
endmodule
