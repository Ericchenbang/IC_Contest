module JAM (
    input CLK,
    input RST,
    output reg [2:0] W,
    output reg [2:0] J,
    input [6:0] Cost,
    output reg [3:0] MatchCount,
    output reg [9:0] MinCost,
    output reg Valid );

reg [2:0] state;
parameter FindPivot = 0, MinusCost = 1, Change = 2, Flip = 3, CountCost = 4;

// FindPivot
reg [2:0] arrange [0:7];
reg [2:0] findCount;
reg [2:0] pivot;
reg findPivot;

// MinusCost
reg [2:0] minusCount;

// Change
reg [2:0] changeIndex;

// Flip
reg [3:0] flipCount;
wire [2:0] flipBound;
assign flipBound = ((7 - pivot) >> 1) + 1;

// CountCost
reg [9:0] currCost;
reg [3:0] costCount;

always@(*) begin
    if (state == CountCost) begin
        W = costCount;
        J = arrange[costCount];  
    end
    else if (state == MinusCost) begin
        W = minusCount;
        J = arrange[minusCount];  
    end
    else begin
        W = 0;
        J = 0;
    end
end


always@(posedge CLK, posedge RST)begin
    if (RST) begin
        state <= CountCost;
        arrange[0] <= 0;
        arrange[1] <= 1;
        arrange[2] <= 2;
        arrange[3] <= 3;
        arrange[4] <= 4;
        arrange[5] <= 5;
        arrange[6] <= 6;
        arrange[7] <= 7;

        currCost <= 0;
        costCount <= 0;
        pivot <= 0;

        MatchCount <= 0;
        MinCost <= 10'd1023;
        Valid <= 0;
    end
    else if (state == CountCost) begin
        if (costCount <= 7) begin
            currCost <= currCost + Cost;
            costCount <= costCount + 1;
        end
        else begin
            state <= FindPivot;
            findCount <= 7;
            findPivot <= 0;
            
            if (currCost < MinCost) begin
                MinCost <= currCost;
                MatchCount <= 1;
            end
            else if (currCost == MinCost) begin
                MatchCount <= MatchCount + 1;
            end
        end
    end
    else if (state == FindPivot) begin
        if (findCount > 0) begin
            if (arrange[findCount] > arrange[findCount - 1]) begin
                state <= MinusCost;
                minusCount <= findCount - 1;
                pivot <= findCount - 1;
                changeIndex <= findCount;

                findCount <= 7;
            end
            else begin
                findCount <= findCount - 1;
            end
        end
        else begin
            Valid <= 1;
        end
    end 
    else if (state == MinusCost) begin
        if (minusCount < 7) begin
            currCost <= currCost - Cost;
            minusCount <= minusCount + 1;
        end
        else begin
            currCost <= currCost - Cost;
            state <= Change;

        end
    end  
    else if (state == Change) begin
        if (findCount > pivot) begin
            findCount <= findCount - 1;
            if (arrange[findCount] > arrange[pivot] && arrange[findCount] < arrange[changeIndex]) begin
                changeIndex <= findCount;
            end
        end
        else begin
            state <= Flip;
            flipCount <= 1;
            arrange[pivot] <= arrange[changeIndex];
            arrange[changeIndex] <= arrange[pivot];
        end
    end
    else if (state == Flip) begin
        if (flipCount < flipBound) begin
            arrange[pivot + flipCount] <= arrange[7 - flipCount + 1];
            arrange[7 - flipCount + 1] <= arrange[pivot + flipCount];
            flipCount <= flipCount + 1;
        end
        else begin
            state <= CountCost;
            costCount <= pivot;
        end
    end
end


endmodule