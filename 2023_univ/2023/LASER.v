module LASER (
    input CLK,
    input RST,
    input [3:0] X,
    input [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
);


parameter ReadData = 2'd0, CountData = 2'd1, NextCenter = 2'd2, Output = 2'd3;
reg [1:0] state;


// ReadData
reg data [15:0] [15:0];
reg [5:0] dataCount;


// FindCircle
reg [5:0] maxDataCount;
reg [3:0] centerX, centerY;     // center traversal
reg [3:0] x, y;                 // data traversal


wire [3:0] xUpperBound, xLowerBound;
assign xUpperBound = (centerX > 11) ? 15 : centerX + 4;
assign xLowerBound = (centerX < 4) ? 0 : centerX - 4;

wire [3:0] yUpperBound, yLowerBound;
assign yUpperBound = (centerY > 11) ? 15 : centerY + 4;
assign yLowerBound = (centerY < 4) ? 0 : centerY - 4;


wire [2:0] xMinusCenterX, yMinusCenterY;
assign xMinusCenterX = (centerX > x) ? (centerX - x) : (x - centerX);
assign yMinusCenterY = (centerY > y) ? (centerY - y) : (y - centerY);

wire [4:0] powerXMC, powerYMC;
assign powerXMC = (xMinusCenterX == 0) ? 0 : ((xMinusCenterX == 1) ? xMinusCenterX : ((xMinusCenterX == 2) ? xMinusCenterX << 1 : ((xMinusCenterX == 3) ? (xMinusCenterX << 1) + xMinusCenterX : xMinusCenterX << 2)));
assign powerYMC = (yMinusCenterY == 0) ? 0 : ((yMinusCenterY == 1) ? yMinusCenterY : ((yMinusCenterY == 2) ? yMinusCenterY << 1 : ((yMinusCenterY == 3) ? (yMinusCenterY << 1) + yMinusCenterY : yMinusCenterY << 2)));

wire [5:0] distance;
assign distance = powerXMC + powerYMC;

wire inCircle;
assign inCircle = (distance <= 16);

// 0: first find c1 center; 1: find c1 center; 2: find c2 center;
reg [1:0] findState;

wire [2:0] xMinusC1X, yMinusC1Y;
assign xMinusC1X = (C1X > x) ? (C1X - x) : (x - C1X);
assign yMinusC1Y = (C1Y > y) ? (C1Y - y) : (y - C1Y);

wire [4:0] powerXMC1X, powerYMC1Y;
assign powerXMC1X = (xMinusC1X == 0) ? 0 : ((xMinusC1X == 1) ? xMinusC1X : ((xMinusC1X == 2) ? xMinusC1X << 1 : ((xMinusC1X == 3) ? (xMinusC1X << 1) + xMinusC1X : xMinusC1X << 2)));
assign powerYMC1Y = (yMinusC1Y == 0) ? 0 : ((yMinusC1Y == 1) ? yMinusC1Y : ((yMinusC1Y == 2) ? yMinusC1Y << 1 : ((yMinusC1Y == 3) ? (yMinusC1Y << 1) + yMinusC1Y : yMinusC1Y << 2)));

wire [5:0] distanceC1;
assign distanceC1 = powerXMC1X + powerYMC1Y;

wire inCircleC1;
assign inCircleC1 = (distanceC1 <= 16);

wire [2:0] xMinusC2X, yMinusC2Y;
assign xMinusC2X = (C2X > x) ? (C2X - x) : (x - C2X);
assign yMinusC2Y = (C2Y > y) ? (C2Y - y) : (y - C2Y);

wire [4:0] powerXMC2X, powerYMC2Y;
assign powerXMC2X = (xMinusC2X == 0) ? 0 : ((xMinusC2X == 1) ? xMinusC2X : ((xMinusC2X == 2) ? xMinusC2X << 1 : ((xMinusC2X == 3) ? (xMinusC2X << 1) + xMinusC2X : xMinusC2X << 2)));
assign powerYMC2Y = (yMinusC2Y == 0) ? 0 : ((yMinusC2Y == 1) ? yMinusC2Y : ((yMinusC2Y == 2) ? yMinusC2Y << 1 : ((yMinusC2Y == 3) ? (yMinusC2Y << 1) + yMinusC2Y : yMinusC2Y << 2)));

wire [5:0] distanceC2;
assign distanceC2 = powerXMC2X + powerYMC2Y;

wire inCircleC2;
assign inCircleC2 = (distanceC2 <= 16);


reg [3:0] lastC1X, lastC1Y;
reg [3:0] lastC2X, lastC2Y;

wire hasData;
assign hasData = (data[x][y] == 1);

integer i, j;
always@(posedge CLK or posedge RST) begin
    if (RST) begin
        state <= ReadData;

        for (i = 0; i <= 15; i = i + 1) begin
            for (j = 0; j <= 15; j = j + 1) begin
                data[i][j] <= 0;
            end
        end

        dataCount <= 0;
        findState <= 0;

        DONE <= 0;
    end
    else if (state == ReadData) begin
        if (dataCount == 40) begin
            state <= CountData;
            dataCount <= 0;
            maxDataCount <= 0;

            centerX <= 0;
            centerY <= 0;
            x <= 0;
            y <= 0;
        end
        else begin
            dataCount <= dataCount + 1;
        end
            
        data[X][Y] <= 1;
    end
    else if (state == CountData) begin
        if (y == yUpperBound) begin
            if (x == xUpperBound) begin
                state <= NextCenter;
            end 
            else begin
                x <= x + 1;
                y <= yLowerBound;
            end
        end
        else begin
            y <= y + 1;
        end

        if (findState == 0) begin
            if (inCircle && hasData) begin
                dataCount <= dataCount + 1;
            end
        end
        else if (findState == 1) begin
            if ((inCircle && !inCircleC2) && hasData) begin
                dataCount <= dataCount + 1;
            end
        end
        else begin
            if ((inCircle && !inCircleC1) && hasData) begin
                dataCount <= dataCount + 1;
            end 
        end
    end
    else if (state == NextCenter) begin
        if (centerY == 4'hd && centerX == 4'hd) begin
            /** Choose c1/c2 initial center logic can be modified later*/
            dataCount <= 0;
            maxDataCount <= 0;
            
            
            centerX <= 2;
            centerY <= 2;
            x <= 0;
            y <= 0;

            if (findState == 0) begin
                state <= CountData;
                findState <= 2;    // find c2 based on c1

                lastC1X <= C1X;
                lastC1Y <= C1Y;
                lastC2X <= C1X;     // since next c2 center definitely not be the same with c1 center
                lastC2Y <= C1Y; 
            end
            else if (findState == 1) begin
                if ((lastC1X == C1X) && (lastC1Y == C1Y)) begin
                    state <= Output;
                    DONE <= 1;
                end
                else begin
                    state <= CountData;
                    findState <= 2;    // find c2 based on c1

                    lastC1X <= C1X;
                    lastC1Y <= C1Y;
                end
            end
            else begin
                if ((lastC2X == C2X) && (lastC2Y == C2Y)) begin
                    state <= Output;
                    DONE <= 1;
                end
                else begin
                    state <= CountData;
                    findState <= 1;    // find c1 based on c2

                    lastC2X <= C2X;
                    lastC2Y <= C2Y;
                end
            end
        end
        else begin
            state <= CountData;
            dataCount <= 0;

            if (dataCount > maxDataCount) begin
                if (findState == 0 || findState == 1) begin
                    C1X <= centerX;
                    C1Y <= centerY;   
                end
                else begin
                    C2X <= centerX;
                    C2Y <= centerY;
                end
                
                maxDataCount <= dataCount;
            end

            if (centerY == 4'hd) begin
                centerX <= centerX + 1;   
                centerY <= 2;  
                
                x <= xLowerBound + 1;
                y <= 0;         
            end
            else begin
                centerY <= centerY + 1;
            
                x <= xLowerBound;
                y <= yLowerBound + 1;
            end
        end
    end
    else if (state == Output) begin
        state <= ReadData;
        DONE <= 0;

        dataCount <= 0;
        findState <= 0;

        for (i = 0; i <= 15; i++) begin
            for (j = 0; j <= 15; j++) begin
                data[i][j] <= 0;
            end
        end
    end
end




endmodule