`timescale 1ns / 1ps

module FSM_TX_ctrl(
    input  logic       clk,
    input  logic       rst,
    input  logic       tx_busy,
    input  logic       send_word,         
    input  logic       is_man_dist,
    input  logic       is_euc_dist,
    input  logic       is_dot_prod,
    
    output logic       tx_start,           
    output logic [1:0] byte_sel,     
    output logic       tx_word_done
);
    
    typedef enum logic [3:0] {
        IDLE,
        SEND_LSB,    WAIT_LSB,
        SEND_MSB,    WAIT_MSB,
        SEND_BYTE_3, WAIT_BYTE_3,
        SEND_BYTE_4, WAIT_BYTE_4
    } state_t;

    state_t state, state_next;

    always_ff @(posedge clk) begin   
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end 
    end

    always_comb begin
        state_next   = state;
        tx_start     = 1'b0;
        byte_sel     = 2'd0;
        tx_word_done = 1'b0;

        case(state)
            IDLE: begin
                if (send_word && !tx_busy) begin
                    state_next = SEND_LSB;
                end
            end

            SEND_LSB: begin
                byte_sel   = 2'd0;
                tx_start   = 1'b1;
                state_next = WAIT_LSB;
            end

            WAIT_LSB: begin
                byte_sel = 2'd0;
                if (!tx_busy) begin
                    state_next = SEND_MSB;
                end
            end

            SEND_MSB: begin
                byte_sel   = 2'd1;
                tx_start   = 1'b1;
                state_next = WAIT_MSB;
            end

            WAIT_MSB: begin
                byte_sel = 2'd1;
                if (!tx_busy) begin
                    if (is_man_dist || is_euc_dist || is_dot_prod) begin
                        state_next = SEND_BYTE_3;
                    end else begin
                        tx_word_done = 1'b1;
                        state_next   = IDLE;
                    end
                end
            end

            SEND_BYTE_3: begin
                byte_sel   = 2'd2;
                tx_start   = 1'b1;
                state_next = WAIT_BYTE_3;
            end

            WAIT_BYTE_3: begin
                byte_sel = 2'd2;
                if (!tx_busy) begin
                    if (is_dot_prod) begin
                        state_next = SEND_BYTE_4;
                    end else begin
                        tx_word_done = 1'b1;
                        state_next   = IDLE;
                    end
                end
            end

            SEND_BYTE_4: begin
                byte_sel   = 2'd3;
                tx_start   = 1'b1;
                state_next = WAIT_BYTE_4;
            end

            WAIT_BYTE_4: begin
                byte_sel = 2'd3;
                if (!tx_busy) begin
                    tx_word_done = 1'b1;
                    state_next   = IDLE;
                end
            end

            default: state_next = IDLE;
        endcase
    end
        
endmodule
