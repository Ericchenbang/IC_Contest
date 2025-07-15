module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output  reg [7:0]   dataout;
output  reg       output_valid;
output  reg        busy;

parameter Reflash = 0, LoadData = 1, Right = 2, Left = 3, Up = 4, Down = 5;
reg [2:0] state;

reg [7:0] data [0:5][0:5];
reg [3:0] count;
reg [2:0] row;
reg [2:0] col;


always@(posedge clk, posedge reset) begin
    if (reset) begin
        row <= 3'd0;
        col <= 3'd0;
        count <= 0;

        output_valid <= 0;
        busy <= 0;
    end
    else if (cmd_valid && !busy)begin
        busy <= 1;
        state <= cmd;
        
        if (cmd == Reflash) begin
            output_valid <= 1;
        end
        else if (cmd == LoadData) begin
            output_valid <= 0;
            row <= 0;
            col <= 0;
        end
        else begin
            output_valid <= 0;
        end
    end
    else if (busy) begin
        case (state)
            Reflash: begin
                if (count <= 4'd8) begin
                    if (count == 4'd2 || count == 4'd5) begin
                        row <= row + 1;
                        col <= col - 2;
                        count <= count + 1;
                    end
                    else if (count == 4'd8) begin
                        row <= row - 2;
                        col <= col - 2;
                        count <= 0;
                        output_valid <= 0;
                        busy <= 0;
                    end
                    else begin
                        col <= col + 1;
                        count <= count + 1;
                    end
                end
                else begin
                    count <= 0;
                end
            end
            LoadData: begin
                if (row < 3'd6) begin
                    data[row][col] <= datain;

                    if (col == 3'd5) begin
                        row <= row + 1;
                        col <= 0;
                    end
                    else begin
                        col <= col + 1;
                    end
                end
                else begin
                    state <= Reflash;
                    output_valid <= 1;
                    row <= 2;
                    col <= 2;
                end
            end
            Right: begin
                if (col < 3) begin
                    col <= col + 1;
                end
                else begin
                    col <= col + 0;
                end
                state <= Reflash;
                output_valid <= 1;
            end
            Left: begin
                if (col > 0) begin
                    col <= col - 1;
                end
                else begin
                    col <= col - 0;
                end
                state <= Reflash;
                output_valid <= 1;
            end
            Up: begin
                if (row > 0) begin
                    row <= row - 1;
                end
                else begin
                    row <= row - 0;
                end
                state <= Reflash;
                output_valid <= 1;
            end
            Down: begin
                if (row < 3) begin
                    row <= row + 1;
                end
                else begin
                    row <= row + 0;
                end
                state <= Reflash;
                output_valid <= 1;
            end
            default: begin
                busy <= 0;
            end
        endcase
    end
    else begin
        busy <= 0;
        //output_valid <= 0;
    end
end


always@(*) begin
    if (state == Reflash && output_valid)begin
        dataout = data[row][col];
    end
    else begin

    end
end


endmodule