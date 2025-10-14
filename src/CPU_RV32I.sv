`timescale 1ns / 1ps

module CPU_RV32I (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic        busWe,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    output logic [ 2:0] busFunc3
);
    logic       regFileWe;
    logic [3:0] aluControl;
    logic       aluSrcMuxSel;
    logic [2:0] RFWDSrcMuxSel;
    logic       branch;
    logic       jal;
    logic       jalr;
    logic       PCEn;
    logic       is_load;
    logic       is_store;

    assign busFunc3 = instrCode[14:12];

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);
endmodule
