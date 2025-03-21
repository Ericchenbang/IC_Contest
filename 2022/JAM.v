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
parameter FindPivot = 3'd0, ChangeNumber = 3'd1, Flip = 3'd2, Count = 3'd3,  Output = 3'd5;


// StartJAM
// FindPivot
reg [2:0] seq [0:7];
reg [3:0] index;
reg [2:0] pivotIndex;

// ChangeNumber
reg [2:0] cMinIndex;

// Flip
reg [1:0] flipUpperBound;   //cmb

// Count
//reg firstCount;
//reg [9:0] totalCost;        //cmb
//reg [9:0] eachTotalCost [0:2];
reg [9:0] totalCost;

always@(posedge CLK, posedge RST) begin
    if (RST) begin 
        state <= Count;

        seq[0] <= 3'd0;
        seq[1] <= 3'd1;
        seq[2] <= 3'd2;
        seq[3] <= 3'd3;
        seq[4] <= 3'd4;
        seq[5] <= 3'd5;
        seq[6] <= 3'd6;
        seq[7] <= 3'd7;

        //FindPivot
        index <= 0;
        pivotIndex <= 0;

        // ChangeNumber
        cMinIndex <= 0;

        // Count
        //firstCount <= 1;
        totalCost <= 0;
        //eachTotalCost[0] <= 0;
        //eachTotalCost[1] <= 0;
        //eachTotalCost[2] <= 0;

        MinCost <= 10'd1023;
        MatchCount <= 0;
    end
    else if (state == FindPivot) begin
        if (seq[7] > seq[6]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd6;
            cMinIndex <= 3'd6;
            index <= 4'd7;
        end
        else if (seq[6] > seq[5]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd5;
            cMinIndex <= 3'd5;
            index <= 4'd6;
        end
        else if (seq[5] > seq[4]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd4;
            cMinIndex <= 3'd4;
            index <= 4'd5;
        end
        else if (seq[4] > seq[3]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd3;
            cMinIndex <= 3'd3;
            index <= 4'd4;
        end
        else if (seq[3] > seq[2]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd2;
            cMinIndex <= 3'd2;
            index <= 4'd3;
        end
        else if (seq[2] > seq[1]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd1;
            cMinIndex <= 3'd1;
            index <= 4'd2;
        end
        else if (seq[1] > seq[0]) begin
            state <= ChangeNumber;
            pivotIndex <= 3'd0;
            cMinIndex <= 3'd0;
            index <= 4'd1;
        end
        else begin
            state <= Output;
            Valid <= 1;
        end
    end
    else if (state == ChangeNumber) begin
        if (index <= 4'd7) begin
            if (seq[pivotIndex] < seq[index] && (cMinIndex == pivotIndex || seq[index] < seq[cMinIndex]))     
                cMinIndex <= index;
            index <= index + 1;
        end
        else begin
            state <= Flip;
            index <= pivotIndex + 1;
            seq[cMinIndex] <= seq[pivotIndex];
            seq[pivotIndex] <= seq[cMinIndex];
        end
    end
    else if (state == Flip) begin
        if (index < pivotIndex + 1 + flipUpperBound) begin
            seq[index] <= seq[3'd7 - (index - (pivotIndex + 1))];
            seq[3'd7 - (index - (pivotIndex + 1))] <= seq[index];
            index <= index + 1;
        end
        else begin
            index <= 0;
            totalCost <= 0;
            state <= Count;
        end
    end
    else if (state == Count) begin
        if (index <= 4'd7) begin
            totalCost <= totalCost + Cost;
            index <= index + 1;
        end
        else begin
            if (totalCost < MinCost) begin
                MinCost <= totalCost;
                MatchCount <= 1;
            end
            else if (totalCost == MinCost) begin
                MatchCount <= MatchCount + 1;
            end
            state <= FindPivot;
        end
    end
    else begin
        Valid <= 0;
    end
end




always@(*) begin
    if (state == Flip) begin
        W = 0;
        J = 0;
        flipUpperBound = (3'd7 - pivotIndex) >> 1;
        //flipIndex = ;
    end
    else if (state == Count) begin
        W = index;
        J = seq[index];
        flipUpperBound = 0;
        //flipIndex = 0;
    end
    else begin
        W = 0;
        J = 0;
        flipUpperBound = 0;
        //flipIndex = 0;
    end

end

endmodule