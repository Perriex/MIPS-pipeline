`timescale 1ns/1ns
module IsEqual(reg1,reg2,equal);
	input[4:0] reg1,reg2;
	output equal;
	assign equal = reg1 == reg2 ? 1 : 0;
	
endmodule