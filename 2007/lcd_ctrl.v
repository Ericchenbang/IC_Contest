module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  reg [7:0]   dataout;
output  reg       output_valid;
output  reg        busy;


reg [7:0] data [35:0];
reg [5:0] inputCount;
reg [3:0] outputCount;
reg [2:0] doCmd;
reg [1:0] origin [1:0];

parameter   Output = 3'd0,
            LoadData = 3'd1,
            ShiftRight = 3'd2,
            ShiftLeft = 3'd3,
            ShiftUp = 3'd4,
            ShiftDown = 3'd5;

wire [1:0] ocDivideThree, ocModThree;
assign ocDivideThree = outputCount/3;
assign ocModThree = outputCount%3;

wire [3:0] oIplusY;
assign oIplusY = (origin[1] + ocDivideThree) << 1;

wire [5:0] outputIndexOne, outputIndexTwo;
wire [5:0] outputIndex; 
assign outputIndexOne = oIplusY * 3;
assign outputIndexTwo = (origin[0] + ocModThree);
assign outputIndex = outputIndexOne + outputIndexTwo;


always@(posedge clk, posedge reset) begin
    if (reset) begin
        inputCount <= 0;
        outputCount <= 0;
        origin[0] <= 0;
        origin[1] <= 0;

        busy <= 0;
        output_valid <= 0;

    end
    else if (cmd_valid && busy == 0) begin
        doCmd <= cmd;

        busy <= 1;
    end
    else begin
            case(doCmd)
                Output: begin
                    output_valid <= 1;
                    dataout <= data[outputIndex];

                    if (outputCount == 4'd9) begin
                        outputCount <= 0;
                        
                        output_valid <= 0;
                        busy <= 0;
                    end
                    else
                        outputCount <= outputCount + 4'd1;
                end
                LoadData: begin
                    data[inputCount] <= datain;

                    if (inputCount == 6'd35) begin
                        doCmd <= Output;
                        inputCount <= 6'd0;
                        origin[0] <= 2'd2;
                        origin[1] <= 2'd2;
                    end
                    else 
                        inputCount <= inputCount + 6'd1;
                end
                ShiftRight: begin
                    if (origin[0] == 2'd3)
                        doCmd <= Output;
                    else begin
                        origin[0] <= origin[0] + 2'd1;
                        doCmd <= Output;
                    end
                end
                ShiftLeft: begin
                    if (origin[0] == 2'd0)
                        doCmd <= Output;
                    else begin
                        origin[0] <= origin[0] - 2'd1;
                        doCmd <= Output;
                    end
                end
                ShiftUp: begin
                    if (origin[1] == 2'd0)
                        doCmd <= Output;
                    else begin
                        origin[1] <= origin[1] - 2'd1;
                        doCmd <= Output;
                    end
                end
                ShiftDown: begin
                    if (origin[1] == 2'd3)
                        doCmd <= Output;
                    else begin
                        origin[1] <= origin[1] + 2'd1;
                        doCmd <= Output;
                    end
                end
                default: begin
                    output_valid <= 0;
                end
            endcase
    end
end

endmodule