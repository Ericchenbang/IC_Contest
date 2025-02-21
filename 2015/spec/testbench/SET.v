module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate;

// Origin of A and B.
reg [8:0] aOrigin [1:0];
reg [8:0] bOrigin [1:0];
// Radius of A and B.
reg [8:0] aRadius;
reg [8:0] bRadius;
// Record whether this point is in A or B.
reg  aPoints [7:0] [7:0];
reg  bPoints [7:0] [7:0];
// Points in A, B relatively.
reg [7:0] aCount;
reg [7:0] bCount;
reg [7:0] aAndBCount;

reg [3:0] i;
reg [3:0] j;

reg countPoints;

always@(posedge clk, posedge rst) begin
    if (rst) begin
        valid <= 0;
        busy <= 0;
        aCount = 0;
        bCount = 0;
        aAndBCount = 0;
        countPoints <= 0;
    end
    else if (en && busy == 0) begin
        busy <= 1;
        aOrigin[0] <= central[23:20];
        aOrigin[1] <= central[19:16];
        bOrigin[0] <= central[15:12];
        bOrigin[1] <= central[11:8];
        aRadius <= radius[11:8];
        bRadius <= radius[7:4];
        aCount <= 0;
        bCount <= 0;
        aAndBCount <= 0;
        countPoints <= 1;
    end
    else begin
        case(mode)
            2'b00: begin
                valid <= 1;
                candidate <= aCount;
                busy <= 0;
                countPoints <= 0;
            end
            2'b01: begin
                valid <= 1;
                candidate <= aAndBCount;
                busy <= 0;
                countPoints <= 0;
            end
            2'b10: begin
                valid <= 1;
                candidate <= aCount - aAndBCount + bCount - aAndBCount;
                busy <= 0;
                countPoints <= 0;
            end
            default: begin
                busy <= 0;
            end
        endcase
    end
end

reg [8:0] ax;
reg [8:0] ay;
// Go through each points in 8*8 space.
// ax = AX - PX, y = AY - PY. A(AX, AY), Point(PX, PY)
// If ax^2 + ay ^2 <= r^2, then the point is in this set.
always@(posedge countPoints) begin
    for (i = 1; i < 9; i = i + 1) begin
        ax = aOrigin[0] - i;
        for (j = 1; j < 9; j = j + 1) begin
            ay = aOrigin[1] - j;
            if (ax * ax + ay * ay <= aRadius * aRadius) begin
                aPoints[i - 1][j - 1] = 1;
                aCount = aCount + 1;
            end
            else begin
                aPoints[i - 1][j - 1] = 0;
            end
        end
    end
end

reg [8:0] bx;
reg [8:0] by;
always@(posedge countPoints) begin
    for (i = 1; i < 9; i = i + 1) begin
        bx = bOrigin[0] - i;
        for (j = 1; j < 9; j = j + 1) begin
            by = bOrigin[1] - j;
            if (bx * bx + by * by <= bRadius * bRadius) begin
                bPoints[i - 1][j - 1] = 1;
                bCount = bCount + 1;
                if (aPoints[i - 1][j - 1] == 1)
                    aAndBCount = aAndBCount + 1;
            end
            else begin
                bPoints[i - 1][j - 1] = 1;
            end
        end
    end
end

endmodule