module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

// They are between 0~9
reg [3:0] ax, ay, bx, by;
// r must be less than 12
reg [3:0] ar, br;

// let state has 8 options
reg [1:0] state;

// Let x and y between 1~8
reg signed [4:0] x, y;

wire signed [4:0] axDelta, ayDelta, bxDelta, byDelta;
assign axDelta = x - ax;
assign ayDelta = y - ay;
assign bxDelta = x - bx;
assign byDelta = y - by;


wire [6:0] axx, ayy, bxx, byy;
assign axx = axDelta * axDelta;
assign ayy = ayDelta * ayDelta;
assign bxx = bxDelta * bxDelta;
assign byy = byDelta * byDelta;

wire [7:0] arr, brr;
assign arr = ar * ar;
assign brr = br * br;

wire insideA, insideB;
assign insideA = (axx + ayy <= arr);
assign insideB = (bxx + byy <= brr);

always@(posedge clk, posedge rst)begin
    if (rst) begin
        x <= 1;
        y <= 1;

        busy <= 0;
        valid <= 0;
        candidate <= 0;
    end
    else if (en == 1 && busy == 0) begin
        ax <= central[23:20];
        ay <= central[19:16];
        bx <= central[15:12];
        by <= central[11:8];
        ar <= radius[11:8];
        br <= radius[7:4];
        
        state <= mode;

        candidate <= 0;
        busy <= 1;
    end
    else if (busy == 1) begin
        case(state) 
            2'b00: begin
                if (insideA) begin
                    candidate <= candidate + 1;
                end
            end
            2'b01: begin
                if (insideA && insideB) begin
                    candidate <= candidate + 1;
                end
            end
            2'b10: begin
                if (insideA && !insideB) begin
                    candidate <= candidate + 1;
                end
                else if (!insideA && insideB) begin
                    candidate <= candidate + 1;
                end
            end
            default: begin
                valid <= 0;
                busy <= 0;
            end
        endcase

        if (state != 3) begin
            // go through the points
            if (y < 8) begin
                y <= y + 1;
            end
            else begin
                if (x < 8) begin
                    y <= 1;
                    x <= x + 1;
                end
                else begin
                    state <= 3;
                    valid <= 1;
                end
            end
        end
        else begin
            x <= 1;
            y <= 1;
        end
    end
    else begin
        valid <= 0;
        candidate <= 0;
    end
end

endmodule