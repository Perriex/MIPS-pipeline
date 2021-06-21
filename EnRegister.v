module EnRegister (clk, pi, po, en);
parameter size = 32;
input clk, en;
input [size-1:0] pi;
output reg [size-1:0] po;

always @(posedge clk) begin
    if (en)
        po <= pi;
end
    
endmodule