`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [ 2:0] func3,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**7-1];  // 0x00 ~ 0x0f => 0x10 * 4 => 0x40

    always_ff @(posedge clk) begin
        if (we)
            case (func3)
                3'b000: mem[addr[31:2]][7:0] <= wData[7:0];
                3'b001: mem[addr[31:2]][15:0] <= wData[15:0];
                3'b010: mem[addr[31:2]] <= wData;
            endcase
    end

    // 읽기는 콤비네이셔널(동기 X)
    always_comb begin
        unique case (func3)
            3'b000:
            rData = {{24{mem[addr[31:2]][7]}}, mem[addr[31:2]][7:0]};  // LB
            3'b001:
            rData = {{16{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:0]};  // LH
            3'b010: rData = mem[addr[31:2]];  // LW
            3'b100: rData = {24'b0, mem[addr[31:2]][7:0]};  // LBU
            3'b101: rData = {16'b0, mem[addr[31:2]][15:0]};  // LHU
            default: rData = mem[addr[31:2]];
        endcase
    end
    /*
    initial begin
        for (int i = 0; i < 128; i++) mem[i] = 32'b0;
    end
*/

endmodule
