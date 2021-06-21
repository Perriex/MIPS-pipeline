`timescale 1ns/1ns
module ForwartingUnit(  id_ex_RegT, id_ex_RegS,
			ex_m_RegD, ex_m_RegWrite,
			ForwardA, ForwardB,
		    mem_wb_RegD, mem_wb_RegWrite);

	input [4:0] id_ex_RegT,id_ex_RegS,ex_m_RegD,mem_wb_RegD;
	input ex_m_RegWrite,mem_wb_RegWrite;

	output [1:0] ForwardA,ForwardB;

	assign ForwardA = ( mem_wb_RegWrite == 1) &&
		 ( mem_wb_RegD == id_ex_RegS ) &&
		 ( mem_wb_RegD != 0) ? 2:  
			( ex_m_RegWrite == 1) &&
		 	( ex_m_RegD == id_ex_RegS ) &&
		 	( ex_m_RegD != 0) ? 1 : 0;

 	assign ForwardB = ( mem_wb_RegWrite == 1) &&
		 ( mem_wb_RegD == id_ex_RegT ) &&
		 ( mem_wb_RegD != 0) ? 2:
			( ex_m_RegWrite == 1) &&
		 	( ex_m_RegD == id_ex_RegT ) &&
		 	( ex_m_RegD != 0) ? 1 : 0;
endmodule