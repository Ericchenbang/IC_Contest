`timescale 1ns/10ps
/*
 * IC Contest Computational System (CS)
*/
module CS(Y, X, reset, clk);

input clk, reset; 
input [7:0] X;
output [9:0] Y;

reg [7:0] recordX [8:0];
wire [10:0] sumX;

wire [9:0] average;
wire [10:0] appAver;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        recordX[0] <= 0;
        recordX[1] <= 0;
        recordX[2] <= 0;
        recordX[3] <= 0;
        recordX[4] <= 0;
        recordX[5] <= 0;
        recordX[6] <= 0;
        recordX[7] <= 0;
        recordX[8] <= 0;

    end
    else begin
        recordX[8] <= X;
        recordX[0] <= recordX[1];
        recordX[1] <= recordX[2];
        recordX[2] <= recordX[3];
        recordX[3] <= recordX[4];
        recordX[4] <= recordX[5];
        recordX[5] <= recordX[6];
        recordX[6] <= recordX[7];
        recordX[7] <= recordX[8];
    end
end
 
assign sumX = recordX[1] + recordX[2] + recordX[3] + recordX[4] + recordX[5] + recordX[6] + recordX[7] + recordX[8] + X

wire [7:0] tempX [8:0];
wire [7:0] compX [7:0];


assign average = sumX / 9;
        
assign tempX[0] = (recordX[0] <= average ? recordX[0] : 0);
assign tempX[1] = (recordX[1] <= average ? recordX[1] : 0);
assign tempX[2] = (recordX[2] <= average ? recordX[2] : 0);
assign tempX[3] = (recordX[3] <= average ? recordX[3] : 0);
assign tempX[4] = (recordX[4] <= average ? recordX[4] : 0);
assign tempX[5] = (recordX[5] <= average ? recordX[5] : 0);
assign tempX[6] = (recordX[6] <= average ? recordX[6] : 0);
assign tempX[7] = (recordX[7] <= average ? recordX[7] : 0);
assign tempX[8] = (recordX[8] <= average ? recordX[8] : 0);

assign compX[0] = (tempX[0] > tempX[1] ? tempX[0] : tempX[1]);
assign compX[1] = (tempX[2] > tempX[3] ? tempX[2] : tempX[3]);
assign compX[2] = (tempX[4] > tempX[5] ? tempX[4] : tempX[5]);
assign compX[3] = (tempX[6] > tempX[7] ? tempX[6] : tempX[7]);
assign compX[4] = (compX[3] > tempX[8] ? compX[3] : tempX[8]);

assign compX[5] = (compX[0] > compX[1] ? compX[0] : compX[1]);
assign compX[6] = (compX[2] > compX[3] ? compX[2] : compX[3]);   
assign compX[7] = (compX[4] > compX[6] ? compX[4] : compX[6]); 
        
assign appAver = (compX[7] > compX[5] ? compX[7] : compX[5]);

        
assign Y = (sumX + {appAver, 3'b0} + appAver) >> 3;
        


endmodule