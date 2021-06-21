`timescale 1ns/1ns
module HazardUnit(RegS, RegT, 
		id_ex_MemRead, id_ex_RegRt, 
		PCWrite, if_id_flush);

	input[4:0] RegS, RegT, id_ex_RegRt;
	input id_ex_MemRead;
	output PCWrite,if_id_flush;

	wire result;

	assign result = (id_ex_MemRead == 1) && 
			( (RegS == id_ex_RegRt || RegT == id_ex_RegRt)) ? 0 : 1;

	assign PCWrite = result;
	assign if_id_flush = ~result;

endmodule