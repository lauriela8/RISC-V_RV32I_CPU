`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    // global signals
    input  logic        clk,
    input  logic        rst,
    // instruction memory side port
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    // control unit side port
    input  logic        PCEn,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic [ 2:0] RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic        is_load,
    input  logic        is_store,
    // data memory side port
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    output logic        busWe,          // ★ 추가
    output logic [ 2:0] busFunc3

);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCOutData, PC_Imm_AdderSrcMuxOut;
    logic [31:0] aluSrcMuxOut, immExt, RFWDSrcMuxOut;
    logic [31:0] PC_4_AdderResult, PC_Imm_AdderResult, PCSrcMuxOut;
    logic PCSrcMuxSel;
    logic btaken;
    // Decode_Register
    logic [31:0] DecReg_RFData1, DecReg_RFData2, DecReg_immExt;
    // Excute_Register
    logic [31:0] ExeReg_aluResult, ExeReg_RFData2, ExeReg_PCSrcMuxOut;
    // MemAccess_Register
    logic [31:0] MemAccReg_busRData, LengthData, MemAccReg_RFData2;
    logic [2:0] MemAccReg_func3;
    logic MemAccReg_is_load, MemAccReg_is_store;
    // WB_Register
    logic [31:0] WbReg_LengthData;

    assign instrMemAddr = PCOutData;
    assign busAddr = ExeReg_aluResult;
    assign busWData = ExeReg_RFData2;
    assign busWe    = MemAccReg_is_store;
    assign busFunc3 = MemAccReg_func3;

    // 1) 컨트롤 딜레이 (Decode→Execute)
    logic DecReg_branch, DecReg_jal, DecReg_jalr;
    register #(1) U_DecReg_branch (
        .clk(clk),
        .rst(rst),
        .d  (branch),
        .q  (DecReg_branch)
    );
    register #(1) U_DecReg_jal (
        .clk(clk),
        .rst(rst),
        .d  (jal),
        .q  (DecReg_jal)
    );
    register #(1) U_DecReg_jalr (
        .clk(clk),
        .rst(rst),
        .d  (jalr),
        .q  (DecReg_jalr)
    );
    assign PCSrcMuxSel = DecReg_jal | DecReg_jalr | (btaken & DecReg_branch);

    // 2) JALR 소스도 딜레이된 sel 사용
    mux_2x1 U_PC_Imm_AdderSrcMux (
        .sel(DecReg_jalr),
        .x0 (PCOutData),
        .x1 (DecReg_RFData1),
        .y  (PC_Imm_AdderSrcMuxOut)
    );

    // ID → EX 딜레이

    logic [4:0] DecReg_WA, ExeReg_WA;
    logic       ExeReg_regFileWe;
    logic [2:0] ExeReg_RFWDSrcMuxSel;

    register #(5) U_DecReg_WA (
        .clk(clk),
        .rst(rst),
        .d  (instrCode[11:7]),
        .q  (DecReg_WA)
    );
    register #(1) U_ExeReg_WE (
        .clk(clk),
        .rst(rst),
        .d  (regFileWe),
        .q  (ExeReg_regFileWe)
    );
    register #(3) U_ExeReg_RFSel (
        .clk(clk),
        .rst(rst),
        .d  (RFWDSrcMuxSel),
        .q  (ExeReg_RFWDSrcMuxSel)
    );
    register #(5) U_ExeReg_WA (
        .clk(clk),
        .rst(rst),
        .d  (DecReg_WA),
        .q  (ExeReg_WA)
    );

    // JAL/JALR 타겟을 EX에서 한 번 잡아두자 (이미 있다면 생략)
    logic [31:0] ExeReg_PCImmResult, ExeReg_PC4;
    register U_ExeReg_PCImm (
        .clk(clk),
        .rst(rst),
        .d  (PC_Imm_AdderResult),
        .q  (ExeReg_PCImmResult)
    );
    register U_ExeReg_PC4 (
        .clk(clk),
        .rst(rst),
        .d  (PC_4_AdderResult),
        .q  (ExeReg_PC4)
    );

    // ★ RFWDSrcMux는 EX 타이밍 데이터 위주로
    mux_5x1 U_RFWDSrcMux (
        .sel(ExeReg_RFWDSrcMuxSel),  // ★ 수정: 선택도 EX 타이밍
        .x0(ExeReg_aluResult),  // ★ 수정: ALU → EX 결과
        .x1 (WbReg_LengthData),       // LOAD는 메모리 레이턴시 때문에 WB 단계 값 유지
        .x2(DecReg_immExt),  // LUI는 ID에서도 OK (상관없음)
        .x3(ExeReg_PCImmResult),  // ★ AUIPC/JALR/브랜치 타겟 등 EX 값
        .x4(ExeReg_PC4),  // ★ JAL 링크값(PC+4)도 EX로 맞춤
        .y(RFWDSrcMuxOut)
    );

    ////////////////////////////////////////////////

    RegisterFile U_RegFile (
        .clk(clk),
        .we (ExeReg_regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (ExeReg_WA),
        .WD (RFWDSrcMuxOut),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    register U_DecReg_RFRD1 (
        .clk(clk),
        .rst(rst),
        .d  (RFData1),
        .q  (DecReg_RFData1)
    );

    register U_DecReg_RFRD2 (
        .clk(clk),
        .rst(rst),
        .d  (RFData2),
        .q  (DecReg_RFData2)
    );

    register U_ExeReg_RFRD2 (
        .clk(clk),
        .rst(rst),
        .d  (DecReg_RFData2),
        .q  (ExeReg_RFData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (DecReg_RFData2),
        .x1 (DecReg_immExt),
        .y  (aluSrcMuxOut)
    );

    register U_MemAccReg_ReadData (
        .clk(clk),
        .rst(rst),
        .d  (busRData),
        .q  (MemAccReg_busRData)
    );

    register U_MemAccReg_RFData2 (
        .clk(clk),
        .rst(rst),
        .d  (ExeReg_RFData2),
        .q  (MemAccReg_RFData2)
    );

    register #(3) U_MemAccReg_func3 (
        .clk(clk),
        .rst(rst),
        .d  (instrCode[14:12]),
        .q  (MemAccReg_func3)
    );

    registerEn U_MemAccReg_ctrl (
        .clk(clk),
        .rst(rst),
        .en (1'b1),
        .d  ({is_load, is_store}),
        .q  ({MemAccReg_is_load, MemAccReg_is_store})
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (DecReg_RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );

    register U_ExeReg_ALU (
        .clk(clk),
        .rst(rst),
        .d  (aluResult),
        .q  (ExeReg_aluResult)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );

    register U_DecReg_ImmExtend (
        .clk(clk),
        .rst(rst),
        .d  (immExt),
        .q  (DecReg_immExt)
    );
    adder U_PC_Imm_Adder (
        .a(DecReg_immExt),
        .b(PC_Imm_AdderSrcMuxOut),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    assign PCSrcMuxSel = jal | jalr | (btaken & branch);

    length_proc U_LengthProc (
        .instrCode({
            {20{1'b0}}, MemAccReg_func3, 12'b0
        }),  // func3만 쓰니 instrCode 재구성
        .ram_data(MemAccReg_busRData),
        .rf_data(MemAccReg_RFData2),
        .is_load(MemAccReg_is_load),
        .is_store(MemAccReg_is_store),
        .out_data(LengthData)
    );

    register U_WbReg_LengthData (
        .clk(clk),
        .rst(rst),
        .d  (LengthData),
        .q  (WbReg_LengthData)
    );

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_ExeReg_PCSrcMux (
        .clk(clk),
        .rst(rst),
        .d  (PCSrcMuxOut),
        .q  (ExeReg_PCSrcMuxOut)
    );

    registerEn U_PC (
        .clk(clk),
        .rst(rst),
        .en (PCEn),
        .d  (ExeReg_PCSrcMuxOut),
        .q  (PCOutData)
    );

endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b;
            `SRL:  result = a >> b;
            `SRA:  result = $signed(a) >>> b;
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin : branch
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ:  btaken = (a == b);
            `BNE:  btaken = (a != b);
            `BLT:  btaken = ($signed(a) < $signed(b));
            `BGE:  btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    initial begin  // for simulation test
        for (int i = 0; i < 32; i++) begin
            mem[i] = 10 + i;
        end
    end


    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    //assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    //assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;

    assign RD1 =
    (RA1 == 5'd0) ? 32'b0 :
    (we && (WA == RA1) && (WA != 0)) ? WD : mem[RA1];

    assign RD2 =
    (RA2 == 5'd0) ? 32'b0 :
    (we && (WA == RA2) && (WA != 0)) ? WD : mem[RA2];
endmodule

module registerEn (
    input  logic        clk,
    input  logic        rst,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module register (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            q <= 0;
        end else begin
            q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;  // R-Type
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
            immExt = {
                {20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]
            };  // S-Type
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};  // SLLI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};  // SRLI, SRAI
                    3'b011:  immExt = {20'b0, instrCode[31:20]};  // SLTIU
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {
                {12{instrCode[31]}},
                instrCode[19:12],
                instrCode[20],
                instrCode[30:21],
                1'b0
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
        endcase
    end
endmodule

// Length Processor (Load / Store 공용)
module length_proc (
    input logic [31:0] instrCode,
    input logic [31:0] ram_data,  // RAM에서 읽은 word (load일 때 사용)
    input  logic [31:0] rf_data,    // 레지스터 파일 값 (store일 때 사용)
    input logic is_load,
    input logic is_store,
    output logic [31:0] out_data    // load이면 확장된 값, store이면 mask된 값
);

    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        out_data = 32'b0;

        if (is_load) begin
            // L-Type 처리
            case (func3)
                3'b000:  out_data = {{24{ram_data[7]}}, ram_data[7:0]};  // LB
                3'b001:  out_data = {{16{ram_data[15]}}, ram_data[15:0]};  // LH
                3'b010:  out_data = ram_data;  // LW
                3'b100:  out_data = {24'b0, ram_data[7:0]};  // LBU
                3'b101:  out_data = {16'b0, ram_data[15:0]};  // LHU
                default: out_data = ram_data;
            endcase
        end else begin
            // S-Type 처리
            out_data = rf_data;
        end
    end
endmodule
