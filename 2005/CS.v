`timescale 1ns/10ps
/*
 * IC Contest Computational System (CS)
*/
module CS(Y, X, reset, clk);

input clk, reset; 
input [7:0] X;
output [9:0] Y;

reg [9:0] YReg;
assign Y = YReg;

reg [7:0] recordX [8:0];
reg [3:0] countX;
reg firstNine;
initial firstNine = 1;
reg [10:0] sumX;
reg startCount;
initial startCount = 0;

integer i;
always@(posedge clk, posedge reset) begin
    if (reset) begin
        for (i = 0; i < 9; i=i+1) begin
            recordX[i] <= 0;
        end
        countX <= 0;
        firstNine = 1;
        sumX <= 0;
        startCount <= 0;
    end
    else begin
        if (countX < 4'h8) begin
            recordX[countX] <= X;
            sumX <= sumX + X;
            countX <= countX + 1;
            startCount <= 0;
        end
        else begin
            if (firstNine) begin
                sumX <= sumX + X;
                recordX[8] <= X;
                firstNine <= 0;
            end
            else begin
                sumX <= sumX + X;
                for (i = 0; i < 8; i=i+1) begin
                    recordX[i] <= recordX[i + 1];
                end
                recordX[8] <= X;
            end
            startCount <= 1;
        end    
    end
end
 

reg [9:0] average;
reg [9:0] appAver;
always@(*) begin
    if (startCount == 0) begin
        average = 0;
        appAver = 0;
    end
    else begin
        average = sumX / 9;
        appAver = 0;
        
        for (i = 0; i < 9; i=i+1) begin
            if (recordX[i] <= average && recordX[i] > appAver) begin
                appAver = recordX[i];
            end
        end

        YReg = (sumX + 9 * appAver) / (9 - 1);
        sumX = sumX - recordX[0];

        startCount = 0;
    end
end

endmodule

