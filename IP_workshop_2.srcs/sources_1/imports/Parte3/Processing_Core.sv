`timescale 1ns / 1ps

module Processing_Core#(
    parameter MEMORY_DEPTH = 1024
)(
    input  logic                            clk,
    input  logic                            rst,
    input  logic                            start_op,
    input  logic [2:0]                      op_mode,
    input  logic                            is_man_dist,
    input  logic                            is_euc_dist,
    input  logic                            is_dot_prod,
    input  logic [10:0]                     doutb_A,
    input  logic [10:0]                     doutb_B,
    input  logic                            tx_word_done,
    
    output logic [$clog2(MEMORY_DEPTH)-1:0] read_address,
    output logic                            read_enable,
    output logic [31:0]                     result_data,
    output logic                            result_valid
);

    logic is_scalar;
    assign is_scalar = is_man_dist || is_euc_dist || is_dot_prod;

    // Datapath Etapa 1: operaciones previas al multiplicador y registro de operandos
    logic [11:0] sum_vec;
    assign sum_vec = {1'b0, doutb_A} + {1'b0, doutb_B};

    logic [11:0] avg_vec;
    assign avg_vec = sum_vec >> 1; // bitshift en vez de /2

    logic signed [11:0] diff_ab;
    logic [11:0]        man_dist_vec;
    assign diff_ab      = signed'({1'b0, doutb_A}) - signed'({1'b0, doutb_B});
    assign man_dist_vec = diff_ab[11] ? -diff_ab : diff_ab;

    // Registros de pipeline Etapa 1 (registran salidas de BRAM y operaciones previas al multiplicador)
    logic [10:0] douta_reg, doutb_reg;
    logic [11:0] sum_vec_reg, avg_vec_reg, man_dist_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            douta_reg    <= 11'd0;
            doutb_reg    <= 11'd0;
            sum_vec_reg  <= 12'd0;
            avg_vec_reg  <= 12'd0;
            man_dist_reg <= 12'd0;
        end else begin
            douta_reg    <= doutb_A;
            doutb_reg    <= doutb_B;
            sum_vec_reg  <= sum_vec;
            avg_vec_reg  <= avg_vec;
            man_dist_reg <= man_dist_vec;
        end
    end

    // Datapath Etapa 2: multiplicaciones (DSP48E1) y selector de la ALU registrado
    logic [21:0] euc_dist_vec;
    assign euc_dist_vec = man_dist_reg * man_dist_reg; // (A - B)^2, luego se calcula sqrt en CORDIC

    logic [21:0] dot_prod_vec;
    assign dot_prod_vec = {10'd0, douta_reg} * {10'd0, doutb_reg}; // A * B

    logic [21:0] alu_out;
    logic [21:0] alu_out_reg;
    always_comb begin
        case (op_mode)
            3'b000:  alu_out = {11'b0, douta_reg};    // Lectura BRAM A
            3'b001:  alu_out = {11'b0, doutb_reg};    // Lectura BRAM B
            3'b010:  alu_out = {10'b0, sum_vec_reg};  // SumVec (A + B)
            3'b011:  alu_out = {10'b0, avg_vec_reg};  // AvgVec (A + B) / 2
            3'b100:  alu_out = {10'b0, man_dist_reg}; // ManDist |A - B|
            3'b101:  alu_out = euc_dist_vec;          // EucDist (A - B)^2
            3'b110:  alu_out = dot_prod_vec;          // DotProd (A . B)
            default: alu_out = 22'd0;
        endcase
    end

    // Registro de pipeline Etapa 2 (salida del selector de la ALU)
    always_ff @(posedge clk) begin
        if (rst) begin
            alu_out_reg <= 22'd0;
        end else begin
            alu_out_reg <= alu_out;
        end
    end

    // Señales internas de control y datapath secuencial
    logic        addr_inc;
    logic        addr_rst;
    logic        acc_en;
    logic        last_address;
    logic        cordic_valid;
    logic        cordic_ready;
    logic [15:0] cordic_dout;
    logic        save_cordic;
    logic [31:0] data_reg;

    // IP CORDIC para raíz cuadrada (EucDist)
    //cordic_0 cordic_inst (
    //    .aclk                    (clk),
    //    .s_axis_cartesian_tvalid (cordic_valid),
    //    .s_axis_cartesian_tdata  (data_reg),
    //    .m_axis_dout_tvalid      (cordic_ready),
    //    .m_axis_dout_tdata       (cordic_dout)
    //);
       sqrt raiz (
        .clk          (clk),
        .rst          (rst),
        .cordic_valid (cordic_valid),
        .data_reg     (data_reg),
        .cordic_ready (cordic_ready),
        .cordic_dout  (cordic_dout)
    );
    // Contador de direcciones de lectura (Puerto B de las BRAM)
    always_ff @(posedge clk) begin
        if (rst || addr_rst) begin
            read_address <= '0;
        end else if (addr_inc) begin
            read_address <= read_address + 1'b1;
        end
    end

    assign last_address = (read_address == (MEMORY_DEPTH - 1));

    // Datapath Etapa 3: Registro de resultado / acumulador de 32 bits
    always_ff @(posedge clk) begin
        if (rst || addr_rst) begin
            data_reg <= 32'd0;
        end else if (save_cordic) begin
            data_reg <= {16'd0, cordic_dout};
        end else if (is_scalar && acc_en) begin
            data_reg <= data_reg + {10'd0, alu_out_reg};
        end else if (!is_scalar && acc_en) begin
            data_reg <= {10'd0, alu_out_reg};
        end
    end

    assign result_data = data_reg;

    // FSM de control del Processing Core
    typedef enum logic [3:0] {
        IDLE,
        READ_MEM,
        WAIT_MEM_1,
        WAIT_MEM_2,
        CALC_ALU,
        ACCUMULATE,
        START_CORDIC,
        WAIT_CORDIC,
        SEND_RESULT,
        WAIT_TX_DONE
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
        read_enable  = 1'b0;
        addr_inc     = 1'b0;
        addr_rst     = 1'b0;
        acc_en       = 1'b0;
        cordic_valid = 1'b0;
        save_cordic  = 1'b0;
        result_valid = 1'b0;

        case (state)
            IDLE: begin
                if (start_op) begin
                    addr_rst   = 1'b1;
                    state_next = READ_MEM;
                end
            end

            READ_MEM: begin
                read_enable = 1'b1;
                state_next  = WAIT_MEM_1;
            end

            WAIT_MEM_1: begin
                read_enable = 1'b1;
                state_next  = WAIT_MEM_2;
            end

            WAIT_MEM_2: begin
                read_enable = 1'b1;
                state_next  = CALC_ALU;
            end

            CALC_ALU: begin
                state_next = ACCUMULATE;
            end

            ACCUMULATE: begin
                acc_en = 1'b1;
                if (is_scalar) begin
                    if (!last_address) begin
                        addr_inc   = 1'b1;
                        state_next = READ_MEM;
                    end else if (is_euc_dist) begin
                        state_next = START_CORDIC;
                    end else begin
                        state_next = SEND_RESULT;
                    end
                end else begin
                    state_next = SEND_RESULT;
                end
            end

            START_CORDIC: begin
                cordic_valid = 1'b1;
                state_next   = WAIT_CORDIC;
            end

            WAIT_CORDIC: begin
                if (cordic_ready) begin
                    save_cordic = 1'b1;
                    state_next  = SEND_RESULT;
                end
            end

            SEND_RESULT: begin
                result_valid = 1'b1;
                state_next   = WAIT_TX_DONE;
            end

            WAIT_TX_DONE: begin
                if (tx_word_done) begin
                    if (is_scalar || last_address) begin
                        state_next = IDLE;
                    end else begin
                        addr_inc   = 1'b1;
                        state_next = READ_MEM;
                    end
                end
            end

            default: state_next = IDLE;
        endcase
    end

endmodule
