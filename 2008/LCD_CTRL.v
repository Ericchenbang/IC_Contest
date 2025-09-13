module LCD_CTRL(cmd, cmd_valid, datain, clk, reset, dataout, output_valid, busy);
input [2:0] cmd;
input cmd_valid;
input [7:0] datain;
input clk;
input reset;
output reg [7:0] dataout;
output reg output_valid;
output reg busy;

parameter ReceiveCmd = 0, LoadData = 1, ZoomFitOutput = 2, ZoomInOutput = 3, ShiftRight = 4, ShiftLeft = 5, ShiftUp = 6, ShiftDown = 7;
reg [2:0] state;
reg zoomFit;

// LoadData
reg [7:0] data [0:8][0:11];
reg [3:0] dataRow;
reg [3:0] dataCol;

// Output
reg [4:0] outputCount;
reg [4:0] originRow;
reg [4:0] originCol;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        state <= ReceiveCmd;

        
        outputCount <= 0;
        originRow <= 3;
        originCol <= 4;

        busy <= 0;
        output_valid <= 0;
    end
    else if (state == ReceiveCmd) begin
        if (cmd_valid) begin
            busy <= 1;
            case(cmd)
                0: begin
                    state <= LoadData;
                    dataRow <= 0;
                    dataCol <= 0;
                    zoomFit <= 1;
                    originRow <= 3;
                    originCol <= 4;
                end
                2: begin
                    state <= ZoomFitOutput;
                    dataRow <= 1;
                    dataCol <= 1;
                    originRow <= 3;
                    originCol <= 4;
                end
                1: begin
                    state <= ZoomInOutput;
                    zoomFit <= 0;
                    if (zoomFit) begin
                        dataRow <= 3;
                        dataCol <= 4;
                    end
                    else begin
                        dataRow <= originRow;
                        dataCol <= originCol;
                    end
                end
                3, 4, 5, 6: begin
                    if (zoomFit) begin
                        state <= ZoomFitOutput;
                        dataRow <= 1;
                        dataCol <= 1;
                    end
                    else begin
                        state <= cmd + 1;
                    end
                end
                default: begin
                    state <= ReceiveCmd;
                end
            endcase
        end
    end
    else if (state == LoadData) begin
        data[dataRow][dataCol] <= datain;

        if (dataCol == 11) begin
            if (dataRow == 8) begin
                state <= ZoomFitOutput;
                dataRow <= 1;
                dataCol <= 1;
            end
            else begin
                dataRow <= dataRow + 1;
                dataCol <= 0;
            end
        end
        else begin
            dataCol <= dataCol + 1;
        end

    end
    else if (state == ZoomFitOutput) begin
        if (outputCount <= 15) begin
            if (outputCount == 0) begin
                output_valid <= 1;
            end

            dataout <= data[dataRow][dataCol];

            outputCount <= outputCount + 1;

            if (dataCol == 10) begin
                if (dataRow != 7) begin
                    dataCol <= 1;
                    dataRow <= dataRow + 2;
                end
            end
            else begin
                dataCol <= dataCol + 3;
            end
        end
        else begin
            busy <= 0;
            output_valid <= 0;
            state <= ReceiveCmd;
            outputCount <= 0;

        end
    end
    else if (state == ZoomInOutput) begin
        if (outputCount <= 15) begin
            if (outputCount == 0) begin
                output_valid <= 1;
            end

            dataout <= data[dataRow][dataCol];

            outputCount <= outputCount + 1;

            if (dataCol == originCol + 3) begin
                if (dataRow != originRow + 3) begin
                    dataCol <= originCol;
                    dataRow <= dataRow + 1;
                end
            end
            else begin
                dataCol <= dataCol + 1;
            end
        end
        else begin
            busy <= 0;
            output_valid <= 0;
            state <= ReceiveCmd;
            outputCount <= 0;
        end
    end
    else if (state == ShiftRight) begin
        state <= ZoomInOutput;
        
        if (originCol < 8) begin
            originCol <= originCol + 1;
            dataCol <= originCol + 1;
        end
        else begin
            dataCol <= originCol;
        end
        dataRow <= originRow;
    end
    else if (state == ShiftLeft) begin
        state <= ZoomInOutput;
        
        if (originCol > 0) begin
            originCol <= originCol - 1;
            dataCol <= originCol - 1;
        end
        else begin
            dataCol <= originCol;
        end
        dataRow <= originRow;
    end
    else if (state == ShiftUp) begin
        state <= ZoomInOutput;
        
        if (originRow > 0) begin
            originRow <= originRow - 1;
            dataRow <= originRow - 1;
        end
        else begin
            dataRow <= originRow;
        end
        dataCol <= originCol;
    end
    else if (state == ShiftDown) begin
        state <= ZoomInOutput;
        
        if (originRow < 5) begin
            originRow <= originRow + 1;
            dataRow <= originRow + 1;
        end
        else begin
            dataRow <= originRow;
        end
        dataCol <= originCol;
    end
end






endmodule