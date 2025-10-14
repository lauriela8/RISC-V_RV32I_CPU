`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instrCode,
    output logic        PCEn,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        busWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        is_load,
    output logic        is_store
);
    wire  [ 6:0] opcode = instrCode[6:0];
    wire  [ 3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [11:0] signals;
    assign {PCEn, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr, is_load, is_store} = signals;

    typedef enum {
        FETCH,
        DECODE,
        R_EXE,
        I_EXE,
        B_EXE,
        LU_EXE,
        AU_EXE,
        J_EXE,
        J_WB,
        JL_EXE,
        JL_WB,
        S_EXE,
        S_MEM,
        L_EXE,
        L_MEM,
        L_WB
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= FETCH;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            FETCH:  next_state = DECODE;
            DECODE: begin
                case (opcode)
                    `OP_TYPE_R:  next_state = R_EXE;
                    `OP_TYPE_I:  next_state = I_EXE;
                    `OP_TYPE_B:  next_state = B_EXE;
                    `OP_TYPE_LU: next_state = LU_EXE;
                    `OP_TYPE_AU: next_state = AU_EXE;
                    `OP_TYPE_J:  next_state = J_EXE;
                    `OP_TYPE_JL: next_state = JL_EXE;
                    `OP_TYPE_S:  next_state = S_EXE;
                    `OP_TYPE_L:  next_state = L_EXE;
                endcase
            end
            R_EXE:  next_state = FETCH;
            I_EXE:  next_state = FETCH;
            B_EXE:  next_state = FETCH;
            LU_EXE: next_state = FETCH;
            AU_EXE: next_state = FETCH;
            J_EXE:  next_state = J_WB;
            J_WB:   next_state = FETCH;
            JL_EXE: next_state = JL_WB;
            JL_WB:  next_state = FETCH;
            S_EXE:  next_state = S_MEM;
            S_MEM:  next_state = FETCH;
            L_EXE:  next_state = L_MEM;
            L_MEM:  next_state = L_WB;
            L_WB:   next_state = FETCH;
        endcase
    end

    always_comb begin
        signals = 12'b0;
        aluControl = `ADD;
        case (state)
            //{PCEn, regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel(3), branch, jal, jalr, is_load, is_store} = signals;
            FETCH: signals = 12'b1_0_0_0_000_0_0_0_0_0;
            DECODE:
            signals = 12'b0_0_0_0_000_0_0_0_0_0;    // next_state가 어디로 갈지만 판단
            R_EXE: begin
                signals = 12'b0_1_0_0_000_0_0_0_0_0;
                aluControl = operator;
            end
            I_EXE: begin
                signals = 12'b0_1_1_0_000_0_0_0_0_0;
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
            B_EXE: begin
                signals = 12'b0_0_0_0_000_1_0_0_0_0;
                aluControl = operator;
            end
            LU_EXE: signals = 12'b0_1_0_0_010_0_0_0_0_0;
            AU_EXE: signals = 12'b0_1_0_0_011_0_0_0_0_0;
            J_EXE: signals = 12'b0_0_0_0_100_0_1_0_0_0;
            J_WB: signals = 12'b0_1_0_0_100_0_0_0_0_0;
            JL_EXE: signals = 12'b0_0_0_0_100_0_1_1_0_0;
            JL_WB: signals = 12'b0_1_0_0_100_0_0_0_0_0;
            S_EXE: signals = 12'b0_0_1_0_000_0_0_0_0_0;
            S_MEM: signals = 12'b0_0_1_1_000_0_0_0_0_1;
            L_EXE: signals = 12'b0_0_1_0_001_0_0_0_0_0;
            L_MEM: signals = 12'b0_0_1_0_001_0_0_0_1_0;
            L_WB: signals = 12'b0_1_1_0_001_0_0_0_1_0;
        endcase
    end
endmodule
