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

// LoadCost
//reg [6:0] workerJob [7:0] [7:0];

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
reg firstCount;
//reg [9:0] totalCost;        //cmb
reg [9:0] eachTotalCost [0:2];
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
        //cIndex <= 0;
        cMinIndex <= 0;

        // Flip
        //fIndex <= 0;

        // Count
        firstCount <= 1;
        totalCost <= 0;
        eachTotalCost[0] <= 0;
        eachTotalCost[1] <= 0;
        eachTotalCost[2] <= 0;
        //eachTotalCost[3] <= 0;
        //eachTotalCost[4] <= 0;

        MinCost <= 10'd1023;
        MatchCount <= 0;

    end
    else if (state == FindPivot) begin
        if (seq[index] > seq[index - 1]) begin
            state <= ChangeNumber;
            pivotIndex <= index - 1;
            cMinIndex <= index - 1;
        end
        else if (index >= 2 && (seq[index - 1] > seq[index - 2])) begin
            state <= ChangeNumber;
            pivotIndex <= index - 2;
            cMinIndex <= index - 1;
        end
        else begin
            // Go through the whole permutation
            if (index == 1) begin
                state <= Output;
                Valid <= 1;
            end
            else 
                index <= index - 1;
        end
    end
    else if (state == ChangeNumber) begin
        if (index <= 4'd7) begin
            if (seq[pivotIndex] < seq[index]) begin
                if (cMinIndex == pivotIndex) begin
                    cMinIndex <= index;
                end
                else if (seq[index] < seq[cMinIndex]) begin
                    cMinIndex <= index;
                end
                /*else begin
                    cMinIndex <= cMinIndex + 0;
                end*/
            end
            /*else 
                cMinIndex <= cMinIndex + 0;*/
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
            if (firstCount)
                index <= 0;
            else 
                index <= (pivotIndex < 4'd2) ? pivotIndex : 4'd3;
            
            totalCost <= 0;
            state <= Count;
        end
    end
    else if (state == Count) begin
        if (index <= 4'd7) begin
            if (index == 0)
                eachTotalCost[index] <= Cost;
            else if (index <= 4'd2)
                eachTotalCost[index] <= eachTotalCost[index - 1] + Cost;
            else if (index == 4'd3) 
                totalCost <= eachTotalCost[index - 1] + Cost;
            else 
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
            /*else begin
                MatchCount <= MatchCount + 0;
            end*/

            state <= FindPivot;
            index <= 4'd7;
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