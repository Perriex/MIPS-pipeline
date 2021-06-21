module Register (clk, pi, po);
parameter size = 32;
input clk;
input [size-1:0] pi;
output reg [size-1:0] po = 0;

always @(posedge clk) begin
    po <= pi;
end
    
endmodule