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

// Input data 
reg [7:0] data [5:0] [5:0];
reg [2:0] i;
reg [2:0] j;
initial begin
    for (i = 0; i < 6; i = i + 1)
        for (j = 0; j < 6; j = j + 1)
            data[i][j] = 0;
end

/** Decode */

// Check whether the cmd should be done (3'd7 are do nothing)
reg [2:0] doThisCmd;
initial doThisCmd = 3'd7;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        for (i = 0; i < 6; i = i + 1)
            for (j = 0; j < 6; j = j + 1)
                data[i][j] = 0;   
        doThisCmd <= 3'd7;
        output_valid <= 0;
        busy <= 0;
    end
    else begin
        if (cmd_valid == 1 && busy == 0) begin
            doThisCmd <= cmd;
            busy <= 1;
        end
        else begin
            busy <= busy;
        end
    end

end

/** load data */

// Count the number of input data (should be 36)
reg [5:0] inputCount;

// The origin of x-axis and y-axis
reg [1:0] xOrigin;
reg [1:0] yOrigin;

always@(posedge clk) begin
    if (doThisCmd == 3'd1) begin
        if (inputCount < 6'd36) begin
            data[inputCount / 6][inputCount % 6] <= datain;
            inputCount <= inputCount + 1;
        end
        else begin
            doThisCmd <= 3'd7;
            xOrigin <= 2'd2;
            yOrigin <= 2'd2;
            output_valid <= 1;
        end
    end
    else begin
        inputCount <= 0;
        
    end
end
    
/** Re-calculate origin */

always@(posedge clk) begin
    case(doThisCmd) 
        3'd0: begin
            output_valid <= 1;
        end
        3'd2: begin
            if (xOrigin == 2'd3)
                xOrigin <= xOrigin;
            else
                xOrigin <= xOrigin + 2'd1;
            output_valid <= 1;
        end
        3'd3: begin
            if (xOrigin == 2'd0)
                xOrigin <= xOrigin;
            else
                xOrigin <= xOrigin - 2'd1;
            output_valid <= 1;
        end
        3'd4: begin
            if (yOrigin == 2'd0)
                yOrigin <= yOrigin;
            else
                yOrigin <= yOrigin - 2'd1;
            output_valid <= 1;
        end
        3'd5: begin
            if (yOrigin == 2'd3)
                yOrigin <= yOrigin;
            else
                yOrigin <= yOrigin + 2'd1;
            output_valid <= 1;
        end
        default: begin
            xOrigin <= 2'd2;
            yOrigin <= 2'd2;
        end
    endcase
end

/** Output display */

// Count the number of output data (should be 6)
reg [3:0] outputCount;

always@(posedge clk) begin
    if (output_valid == 1) begin
        if (outputCount < 4'd9) begin
            dataout <= data[outputCount / 3 + xOrigin][outputCount % 3 + yOrigin];
            outputCount <= outputCount + 4'd1;
        end
        else begin
            doThisCmd <= 3'd7;
            output_valid <= 0;
            busy <= 0;
        end
    end
    else begin
        outputCount <= 0;
        doThisCmd <= doThisCmd;
    end
end                                                                          
endmodule
