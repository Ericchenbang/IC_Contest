module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  reg [7:0]   dataout;
output  reg       output_valid;
output  reg        busy;
initial busy = 0;


reg [7:0] data [35:0];
reg [5:0] inputCount;
reg [3:0] outputCount;
reg [2:0] doCmd;
reg checkCmd;
initial checkCmd <= 0;
reg [1:0] origin [1:0];

parameter   Output = 3'd0,
            LoadData = 3'd1,
            ShiftRight = 3'd2,
            ShiftLeft = 3'd3,
            ShiftUp = 3'd4,
            ShiftDown = 3'd5;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        checkCmd <= 0;
        inputCount <= 0;
        outputCount <= 0;
        origin[0] <= 0;
        origin[1] <= 0;
        busy <= 0;
        output_valid <= 0;

    end
    else if (cmd_valid && busy == 0) begin
        doCmd <= cmd;
        checkCmd <= 1;
        busy <= 1;
    end
    else begin
        if (checkCmd) begin
            case(doCmd)
                Output: begin
                    output_valid <= 1;
                    dataout <= data[(origin[1] + outputCount/3)*6 + (origin[0] + outputCount%3)];
                    outputCount <= outputCount + 4'd1;

                    if (outputCount == 4'd9) begin
                        output_valid <= 0;
                        outputCount <= 0;
                        checkCmd <= 0;
                        busy <= 0;
                    end
                end
                LoadData: begin
                    data[inputCount] <= datain;
                    inputCount <= inputCount + 6'd1;

                    if (inputCount == 6'd36) begin
                        doCmd <= Output;
                        inputCount <= 6'd0;
                        origin[0] <= 2'd2;
                        origin[1] <= 2'd2;
                    end
                end
                ShiftRight: begin
                    if (origin[0] == 2'd3)
                        doCmd <= Output;
                    else
                        origin[0] <= origin[0] + 2'd1;
                    doCmd <= Output;
                end
                ShiftLeft: begin
                    if (origin[0] == 2'd0)
                        doCmd <= Output;
                    else
                        origin[0] <= origin[0] - 2'd1;
                    doCmd <= Output;

                end
                ShiftUp: begin
                    if (origin[1] == 2'd0)
                        doCmd <= Output;
                    else
                        origin[1] <= origin[1] - 2'd1;
                    doCmd <= Output;

                end
                ShiftDown: begin
                    if (origin[1] == 2'd3)
                        doCmd <= Output;
                    else
                        origin[1] <= origin[1] + 2'd1;
                    doCmd <= Output;

                end
                default: begin
                    output_valid <= 0;
                end
            endcase
        end
        else
            busy <= 0;
    end

end



endmodule