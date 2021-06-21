`timescale 1ns/1ns

module DataPath (clk, regSrc, regDst, pcSrc, ALUSrc, ALUOp, regWrite, memWrite, memRead, flush, zero, opCode, func);
    input clk;

    //pc
    wire [31:0] pcCurrAddr;
    wire [31:0] pcNextAddr, pcSelectAddr;
    wire pcWrite;
    input [1:0] pcSrc;

    wire [31:0] pcSrcData[3:0];
    assign pcSrcData[0] = pcCurrAddr + 4;
    Mux #(32, 4) pcSrcMux(pcSrcData, pcSrc, pcSelectAddr);

    wire [31:0] pcHazardSrcData[1:0];
    assign pcHazardSrcData[1] = pcSelectAddr;
    assign pcHazardSrcData[0] = pcCurrAddr;
    Mux pcHazardSrc(pcHazardSrcData, pcWrite, pcNextAddr);
    
    programCounter pc(clk, pcNextAddr, pcCurrAddr);
    //
   
    //Inst Mem
    wire [31:0] instruction;

    MemoryBlock instMem(clk, pcCurrAddr,1'b0,,instruction);
    //

    wire IFIDFlush;
    wire [31:0] IFIDPcAddr, IFIDInstruction;
    EnRegister IFID1 (clk, pcSrcData[0], IFIDPcAddr, pcWrite);
    EnRegister IFID2 (clk, instruction, IFIDInstruction, pcWrite);
    

    //Set Up Controller
    output zero;
    output [5:0] opCode, func;
    assign opCode = IFIDInstruction[31:26];
    assign func = IFIDInstruction[5:0];

    
    //Sign Extend
    wire [31:0] immediate;
    SignExtend signExtend(IFIDInstruction[15:0], immediate);
    //
    
    //Register File
    input [1:0] regDst,regSrc,ALUOp;
    input ALUSrc,regWrite,memWrite,memRead,flush;

    wire WBRegWrite;
    wire [4:0] waddr;
    wire [31:0] regWriteData, regReadData1, regReadData2;

    assign pcSrcData[1] = {immediate[29:0], 2'b00} + IFIDPcAddr;
    assign pcSrcData[2] = {IFIDPcAddr[31:28], IFIDInstruction[25:0], 2'b00};
    assign pcSrcData[3] = regReadData1;
    assign zero = regReadData1 == regReadData2;
    RegisterFile registerFile(clk, IFIDInstruction[25:21], IFIDInstruction[20:16], waddr, WBRegWrite, regWriteData, regReadData1, regReadData2);
    //
    wire [31:0] IDEXregReadData1, IDEXregReadData2, IDEXPcAddr, IDEXImmediate; 
    wire [10:0] IDEXRegWirteAddr;
    wire [4:0] IDEXEX, IDEXS;
    wire [1:0] IDEXM;
    wire [2:0] IDEXWB; 
    Register IDEX1(clk, regReadData1, IDEXregReadData1);
    Register IDEX2(clk, regReadData2, IDEXregReadData2);
    Register IDEX3(clk, IFIDPcAddr, IDEXPcAddr);
    Register IDEX4(clk, immediate, IDEXImmediate);
    Register #(10) IDEX5(clk, {IFIDInstruction[20:16], IFIDInstruction[15:11]}, IDEXRegWirteAddr);
    Register #(5) IDEX6(clk, {ALUOp, ALUSrc, regDst}, IDEXEX);
    Register #(2) IDEX7(clk, {memWrite &~IFIDFlush, memRead}, IDEXM);
    Register #(3) IDEX8(clk, {regSrc, regWrite&~IFIDFlush}, IDEXWB);
    Register #(5) IDEX9(clk, IFIDInstruction[25:21], IDEXS);

    HazardUnit hazardUnit(IFIDInstruction[25:21], IFIDInstruction[20:16], 
		IDEXM[0], IDEXRegWirteAddr[9:5], 
		pcWrite, IFIDFlush);

    //ALU
    wire [31:0] rightOp, ALUResult;
    wire [31:0] ALUSrcData[1:0];
    wire [4:0] EXWaddr;
    wire [1:0] ForwardA, ForwardB;

    wire [31:0] leftForward[2:0], rightForward[2:0];
    wire [31:0] EXMALUResult, leftOp; 

    assign leftForward[2] = regWriteData;
    assign leftForward[1] = EXMALUResult;
    assign leftForward[0] = IDEXregReadData1;
    Mux #(32, 3) LeftOpMux(leftForward, ForwardA, leftOp);

    assign rightForward[2] = regWriteData;
    assign rightForward[1] = EXMALUResult;
    assign rightForward[0] = IDEXregReadData2;
    Mux #(32, 3) RightOpMux(rightForward, ForwardB, ALUSrcData[0]);

    assign ALUSrcData[1] = IDEXImmediate;
    Mux #(32, 2) ALUSrcMux(ALUSrcData, IDEXEX[2], rightOp);

    ALU alu(leftOp, rightOp, IDEXEX[4:3], ALUResult,);

    wire [4:0] regDstData[3:0];
    assign regDstData[0] = IDEXRegWirteAddr[9:5];
    assign regDstData[1] = IDEXRegWirteAddr[4:0];
    assign regDstData[2] = 5'b11111;
    Mux #(5, 4) regWriteDstMux(regDstData, IDEXEX[1:0], EXWaddr);
    //

    wire [31:0] EXMregReadData2;
    wire [4:0] EXMWaddr;
    wire [1:0] EXMM;
    wire [2:0] EXMWB;
    Register EXM1(clk, ALUResult, EXMALUResult);
    Register EXM2(clk, IDEXregReadData2, EXMregReadData2);
    Register EXM3(clk, EXWaddr, EXMWaddr);
    Register #(2) EXM4(clk, IDEXM, EXMM);
    Register #(3) EXM5(clk, IDEXWB, EXMWB);

    //Memory
    wire [31:0] memReadData;
    MemoryBlock RAM(clk, EXMALUResult, EXMM[0], EXMregReadData2, memReadData);
    //

    wire [31:0] MWBMemReadData, MWBALUResult;
    wire [4:0] MWBWaddr;
    wire [2:0] MWBWB;
    Register MWB1(clk, memReadData, MWBMemReadData);
    Register MWB2(clk, EXMALUResult, MWBALUResult);
    Register MWB3(clk, EXMWaddr, MWBWaddr);
    Register #(3) MWB4(clk, EXMWB, MWBWB);


    //Memory Path
    wire [31:0] regSrcData[3:0];    
    assign regSrcData[0] = pcSrcData[0];
    assign regSrcData[1] = MWBMemReadData;
    assign regSrcData[2] = MWBALUResult;
    assign waddr = MWBWaddr;
    assign WBRegWrite = MWBWB[0];
    Mux #(32, 4) regWriteSrcMux(regSrcData, MWBWB[2:1], regWriteData);
    //

    //Forwrd
    ForwartingUnit forwartingUnit(  IDEXRegWirteAddr[9:5], IDEXS,
		 	EXMWaddr, EXMWB[0],
			ForwardA, ForwardB,
		    MWBWaddr, MWBWB[0]);
    //
endmodule