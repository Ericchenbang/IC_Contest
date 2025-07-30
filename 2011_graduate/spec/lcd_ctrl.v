module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output reg IROM_EN;
output [5:0] IROM_A;
output reg IRB_RW;
output [7:0] IRB_D;
output [5:0] IRB_A;
output reg busy;
output reg done;

reg [1:0] state;
parameter InputData = 0, ReadCmd = 1, DoCmd = 2;

// InputData
reg [7:0] data [0:7][0:7];
reg [6:0] dataIndex;
assign IROM_A = dataIndex;

wire [2:0] inputRow, inputCol;
assign inputRow = (dataIndex - 1) >> 3;
assign inputCol = (dataIndex - 1) & 3'b111;

// DoCmd
reg [2:0] currRow, currCol;

assign IRB_A = dataIndex;
wire [2:0] outputRow, outputCol;
assign outputRow = dataIndex >> 3;
assign outputCol = dataIndex & 3'b111;
assign IRB_D = data[outputRow][outputCol];

wire [9:0] average;
assign average = (data[currRow][currCol] + data[currRow][currCol + 1] + data[currRow + 1][currCol] + data[currRow + 1][currCol + 1]) >> 2;


always@(posedge clk, posedge reset) begin
    if (reset) begin
        state <= InputData;
        dataIndex <= 0;
        
        currRow <= 3;
        currCol <= 3;

        IROM_EN <= 0;
    end
    else if (state == InputData) begin
        if (dataIndex == 0) begin
            dataIndex <= dataIndex + 1;
        end
        else if (dataIndex < 64) begin
            data[inputRow][inputCol] <= IROM_Q;
            dataIndex <= dataIndex + 1;
        end
        else begin
            state <= ReadCmd;
            data[inputRow][inputCol] <= IROM_Q;
            dataIndex <= 0;
            busy <= 0;
        end
    end
    else if (state == ReadCmd) begin
        if (cmd_valid) begin
            state <= DoCmd;
            if (cmd == 0) begin
                IRB_RW <= 0;
            end
            busy <= 1;
        end
    end
    else if (state == DoCmd) begin
        case(cmd)
            0: begin
                if (dataIndex != 63) begin
                    dataIndex <= dataIndex + 1;
                end
                else begin
                    dataIndex <= 0;
                    IRB_RW <= 1;
                    busy <= 0;
                    done <= 1;
                end
            end
            1: begin
                if (currRow != 0)
                    currRow <= currRow - 1;
            end
            2: begin
                if (currRow != 6)
                    currRow <= currRow + 1;
            end
            3: begin
                if (currCol != 0) 
                    currCol <= currCol - 1;
            end
            4: begin
                if (currCol != 6) 
                    currCol <= currCol + 1;
            end
            5: begin
                data[currRow][currCol] <= average;
                data[currRow][currCol + 1] <= average;
                data[currRow + 1][currCol] <= average;
                data[currRow + 1][currCol + 1] <= average;
            end
            6: begin
                data[currRow][currCol] <= data[currRow + 1][currCol];
                data[currRow][currCol + 1] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol] <= data[currRow][currCol];
                data[currRow + 1][currCol + 1] <= data[currRow][currCol + 1];
            end
            7: begin
                data[currRow][currCol] <= data[currRow][currCol + 1];
                data[currRow][currCol + 1] <= data[currRow][currCol];
                data[currRow + 1][currCol] <= data[currRow + 1][currCol + 1];
                data[currRow + 1][currCol + 1] <= data[currRow + 1][currCol];
            end
            default: begin
                state <= ReadCmd;
                busy <= 0;
            end
        endcase

        if (cmd != 0) begin
            state <= ReadCmd;
            busy <= 0;
        end
    end
    else begin
        IROM_EN <= 1;
        IRB_RW <= 1;
        busy <= 1;
        done <= 0;
    end
end
endmodule