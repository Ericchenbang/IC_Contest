module LCD_CTRL(cmd, cmd_valid, datain, clk, reset, dataout, output_valid, busy);
input [2:0] cmd;
input cmd_valid;
input [7:0] datain;
input clk;
input reset;
output reg [7:0] dataout;
output reg output_valid;
output reg busy;

reg checkCommand;
reg [2:0] command;
reg [7:0] data[8:0][11:0];
reg [3:0] lOrigin;
reg [3:0] wOrigin;

reg [6:0] inputCount;
reg [4:0] outputCount;

reg state;

parameter   LoadData = 3'd0,
            ZoomIn = 3'd1,
            ZoomFit = 3'd2,
            ShiftRight = 3'd3,
            ShiftLeft = 3'd4,
            ShiftUp = 3'd5,
            ShiftDown = 3'd6,
            DoNothing = 3'd7,
            ZoomInState = 1,
            ZoomFitState = 0;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        command <= DoNothing;
        checkCommand <= 0;
        busy <= 0;
        output_valid <= 0;
        inputCount <= 0;
        outputCount <= 0;
        state <= ZoomFitState;
    end
    else if (cmd_valid && busy == 0) begin
        checkCommand <= 1;
        command <= cmd;
        busy <= 1;
    end
    else if (checkCommand) begin
        case(command)
            LoadData: begin
                if (inputCount < 7'd108) begin
                    data[inputCount / 12][inputCount % 12] <= datain;
                    inputCount <= inputCount + 1;
                end
                else begin
                    inputCount <= 0;
                    command <= ZoomFit;
                end
            end
            ZoomIn: begin
                state <= ZoomInState;
                if (outputCount < 5'd16) begin
                    output_valid <= 1;
                    dataout <= data[wOrigin-4'd2 + (outputCount >> 2)][lOrigin-4'd2 + outputCount%4];
                    outputCount <= outputCount + 1;
                end
                else begin
                    //command <= DoNothing;
                    checkCommand <= 0;
                    outputCount <= 0;
                    output_valid <= 0;
                    busy <= 0;
                end
            end
            ZoomFit: begin
                state <= ZoomFitState;
                if (outputCount < 5'd16) begin 
                    output_valid <= 1;
                    dataout <= data[((outputCount >> 2) << 1) + 1][(outputCount%4)*3 + 1];
                    outputCount <= outputCount + 1;
                end
                else begin
                    //command <= DoNothing;
                    checkCommand <= 0;
                    outputCount <= 0;
                    output_valid <= 0;
                    busy <= 0;
                    lOrigin <= 4'd6;
                    wOrigin <= 4'd5;
                end
            end
            ShiftRight: begin
                if (state == ZoomInState) begin
                    if (lOrigin < 4'ha)
                        lOrigin <= lOrigin + 4'd1;
                    else
                        lOrigin <= lOrigin;
                    command <= ZoomIn;
                end
                else begin
                    command <= ZoomFit;
                end
            end
            ShiftLeft: begin
                if (state == ZoomInState) begin
                    if (lOrigin > 4'h2)
                        lOrigin <= lOrigin - 4'd1;
                    else
                        lOrigin <= lOrigin;
                    command <= ZoomIn;
                end
                else begin
                    command <= ZoomFit;
                end
            end
            ShiftUp: begin
                if (state == ZoomInState) begin
                    if (wOrigin > 4'h2)
                        wOrigin <= wOrigin - 4'd1;
                    else
                        wOrigin <= wOrigin;
                    command <= ZoomIn;
                end
                else begin
                    command <= ZoomFit;
                end
            end
            ShiftDown: begin
                if (state == ZoomInState) begin
                    if (wOrigin < 4'h7)
                        wOrigin <= wOrigin + 4'd1;
                    else
                        wOrigin <= wOrigin;
                    command <= ZoomIn;
                end
                else begin
                    command <= ZoomFit;
                end
            end
            /*default: begin
                output_valid <= 0;
                busy <= 0;
            end*/
        endcase
    end
    else 
        output_valid <= 0;
end
endmodule