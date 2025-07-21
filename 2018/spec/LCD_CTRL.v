module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

reg [3:0] doCmd;
parameter StandBy = 4'd12, finishOutput = 4'd13;

reg [7:0] data [0:7][0:7];
reg [5:0] count;
assign IROM_A = count;

wire [2:0] row, col;
assign row = count >> 3;
assign col = count & 3'b111;

reg [2:0] currRow, currCol;

reg [7:0] max, min, one, two;
reg [10:0] average;

always@(*) begin
	if (doCmd == 5) begin
		one = (data[currRow][currCol] > data[currRow][currCol + 1]) ? data[currRow][currCol] : data[currRow][currCol + 1];
		two = (data[currRow + 1][currCol] > data[currRow + 1][currCol + 1]) ? data[currRow + 1][currCol] : data[currRow + 1][currCol + 1];
		max = one > two ? one : two;
		min = 0;
		average = 0;
	end
	else if (doCmd == 6) begin
		one = (data[currRow][currCol] < data[currRow][currCol + 1]) ? data[currRow][currCol] : data[currRow][currCol + 1];
		two = (data[currRow + 1][currCol] < data[currRow + 1][currCol + 1]) ? data[currRow + 1][currCol] : data[currRow + 1][currCol + 1];
		min = one < two ? one : two;
		max = 0;
		average = 0;
	end
	else if (doCmd == 7) begin
		average = (data[currRow][currCol] + data[currRow][currCol + 1] + data[currRow + 1][currCol] + data[currRow + 1][currCol + 1]) >> 2;
		one = 0;
		two = 0;
		max = 0;
		min = 0;
	end
	else begin
		one = 0;
		two = 0;
		max = 0;
		min = 0;
		average = 0;
	end
end

always@(posedge clk, posedge reset) begin
    if (reset) begin
        count <= 0;

        IROM_rd <= 1;
        IRAM_valid <= 0;
        busy <= 1;
        done <= 0;
    end
    else if (IROM_rd) begin
        data[row][col] <= IROM_Q;

        if (count != 6'h3f) begin
            count <= count + 1;
        end
        else begin
            doCmd <= StandBy;
            count <= 0;

            currRow <= 3;
            currCol <= 3;

            IROM_rd <= 0;
            busy <= 0;
        end
    end
    else if (busy == 0 && cmd_valid == 1) begin
        doCmd <= cmd;
        if (cmd == 0) begin
            IRAM_valid <= 1;
            IRAM_A <= count;
            IRAM_D <= data[row][col];
        end
        else begin
            IRAM_valid <= 0;
            IRAM_A <= 0;
            IRAM_D <= 0;
        end

        busy <= 1;
    end
    else begin
        case(doCmd) 
            0: begin
                IRAM_A <= count;
                IRAM_D <= data[row][col];

                if (count != 6'h3f) begin
                    count <= count + 1;
                end
                else begin
                    doCmd <= finishOutput;
                end
            end
            // ShiftUp
            1: begin
                if (currRow == 0) 
                    currRow <= currRow + 0;
                else 
                    currRow <= currRow - 1;
                doCmd <= StandBy;
                busy <= 0;
            end
            // ShiftDown
            2: begin
                if (currRow == 6) 
                    currRow <= currRow + 0;
                else
                    currRow <= currRow + 1;
                doCmd <= StandBy;
                busy <= 0;
            end
            // Shift Left
            3: begin
                if (currCol == 0) 
                    currCol <= currCol + 0;
                else 
                    currCol <= currCol - 1;
                doCmd <= StandBy;
                busy <= 0;
            end
            // Shift Right
            4: begin
                if (currCol == 6) 
                    currCol <= currCol + 0;
                else
                    currCol <= currCol + 1;
                doCmd <= StandBy;
                busy <= 0;
            end
            // Max
            5: begin
                data[currRow][currCol] <= max;
                data[currRow][currCol + 1] <= max;
                data[currRow + 1][currCol] <= max;
                data[currRow + 1][currCol + 1] <= max;
                doCmd <= StandBy;
                busy <= 0;
            end
            // Min
            6: begin
                data[currRow][currCol] <= min;
                data[currRow][currCol + 1] <= min;
                data[currRow + 1][currCol] <= min;
                data[currRow + 1][currCol + 1] <= min;
                doCmd <= StandBy;
                busy <= 0;
            end
            // Average
            7: begin
                data[currRow][currCol] <= average;
                data[currRow][currCol + 1] <= average;
                data[currRow + 1][currCol] <= average;
                data[currRow + 1][currCol + 1] <= average;
                doCmd <= StandBy;
                busy <= 0;
            end
            // counterclockwise
            8: begin
                data[currRow][currCol] <= data[currRow][currCol + 1];
                data[currRow][currCol + 1] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol] <= data[currRow][currCol];
                data[currRow + 1][currCol + 1] <= data[currRow + 1][currCol];
                doCmd <= StandBy;
                busy <= 0;
            end
            // clockwise
            9: begin
                data[currRow][currCol] <= data[currRow + 1][currCol];
                data[currRow][currCol + 1] <= data[currRow][currCol];
                data[currRow + 1][currCol] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol + 1] <= data[currRow][currCol + 1];
                doCmd <= StandBy;
                busy <= 0;
            end
            // mirrow x
            10: begin
                data[currRow][currCol] <= data[currRow + 1][currCol];
                data[currRow][currCol + 1] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol] <= data[currRow][currCol];
                data[currRow + 1][currCol + 1] <= data[currRow][currCol + 1];
                doCmd <= StandBy;
                busy <= 0;
            end
            // mirrow y
            11: begin
                data[currRow][currCol] <= data[currRow][currCol + 1];
                data[currRow][currCol + 1] <= data[currRow][currCol];
                data[currRow + 1][currCol] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol + 1] <= data[currRow + 1][currCol];
                doCmd <= StandBy;
                busy <= 0;
            end
            StandBy: begin
                busy <= 0;
            end
            finishOutput: begin
                IRAM_valid <= 0;
                busy <= 0;
                done <= 1;
            end
            default: begin
                busy <= 1;
            end
        endcase
    end
end



endmodule
