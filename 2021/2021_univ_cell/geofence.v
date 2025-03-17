module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [2:0] state;
parameter  LoadData = 3'd0, Findsq1 = 3'd1, Findsq2 = 3'd2, Findsq3 = 3'd3,
            Findsq4 = 3'd4, CheckObj = 3'd5, Output = 3'd6;
            
reg [2:0] dataCount;
reg signed [10:0] pX [5:0];
reg signed [10:0] pY [5:0];
reg signed [10:0] objX;
reg signed [10:0] objY;


reg [2:0] passSqCount;
reg signedBit;
reg [2:0] fixedIndex;
reg [2:0] movedIndex;

reg signed [10:0] Ax, Ay, Bx, By;

wire signed [20:0] AxBy;
wire signed [20:0] BxAy;
assign AxBy = Ax * By;
assign BxAy = Bx * Ay;
wire currentSignedBit;
assign currentSignedBit = (AxBy >= BxAy ? 0 : 1);


always@(posedge clk, posedge reset) begin
    if (reset) begin
        // initialize reg
        dataCount <= 0;

        passSqCount <= 0;
        fixedIndex <= 0;
        movedIndex <= 0;
        signedBit <= 0;
        state <= LoadData;
    end
    else if (state == LoadData) begin
        case(dataCount)
            3'd0: begin
                objX <= X;
                objY <= Y;
                dataCount <= dataCount + 1;
            end
            3'd6: begin
                pX[dataCount - 1] <= X;
                pY[dataCount - 1] <= Y;
                dataCount <= 0;
                state <= Findsq1;
                fixedIndex <= 1;
                movedIndex <= 3'd2;
            end
            default: begin
                pX[dataCount - 1] <= X;
                pY[dataCount - 1] <= Y;
                dataCount <= dataCount + 1;
            end
        endcase
    end
    else if (state == Findsq1) begin
        if (movedIndex <= 3'd5) begin
            if (movedIndex == 3'd2) begin
                signedBit <= currentSignedBit;
                movedIndex <= movedIndex + 1;
            end
            else if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd1;
                movedIndex <= 3'd2;
                pX[1] <= pX[2];
                pX[2] <= pX[3];
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[1];
                pY[1] <= pY[2];
                pY[2] <= pY[3];
                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[1];
            end
        end
        else begin
            state <= Findsq2;
            fixedIndex <= 3'd2;
            movedIndex <= 3'd3;
        end
    end
    else if (state == Findsq2) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd2;
                movedIndex <= 3'd3;
                pX[2] <= pX[3];
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[2];
                pY[2] <= pY[3];
                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[2];
            end
        end
        else begin
            state <= Findsq3;
            fixedIndex <= 3'd3;
            movedIndex <= 3'd4;
        end
    end
    else if (state == Findsq3) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd3;
                movedIndex <= 3'd4;
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[3];
                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[3];
            end
        end
        else begin
            state <= Findsq4;
            fixedIndex <= 3'd4;
            movedIndex <= 3'd5;
        end
    end
    else if (state == Findsq4) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd4;
                movedIndex <= 3'd5;
                pX[4] <= pX[5];
                pX[5] <= pX[4];
                pY[4] <= pY[5];
                pY[5] <= pY[4];
            end
        end
        else begin
            state <= CheckObj;
            fixedIndex <= 0;
            movedIndex <= 0;
        end
    end
    else if (state == CheckObj) begin
        if (movedIndex <= 3'd5) begin
            if (movedIndex == 0) begin
                movedIndex <= movedIndex + 1;
                signedBit <= currentSignedBit;
            end
            else if (signedBit != currentSignedBit) begin
                is_inside <= 0;
                movedIndex <= 3'd6;
            end
            else begin
                movedIndex <= movedIndex + 1;
                is_inside <= 1;
            end
        end
        else begin
            state <= Output;
            movedIndex <= 0;
            valid <= 1;
        end
    end
    else if (state == Output) begin
        state <= LoadData;
        valid <= 0;
    end
    else begin
        //dataCount <= 0;
    end
end
/*
always@(posedge clk) begin
    if (state == Findsq1) begin
        if (movedIndex <= 3'd5) begin
            if (movedIndex == 3'd2) begin
                signedBit <= currentSignedBit;
                movedIndex <= movedIndex + 1;
            end
            else if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd1;
                movedIndex <= 3'd2;
                pX[1] <= pX[2];
                pX[2] <= pX[3];
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[1];

                pY[1] <= pY[2];
                pY[2] <= pY[3];
                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[1];
            end
        end
        else begin
            state <= Findsq2;
            fixedIndex <= 2;
            movedIndex <= 3'd3;
        end
    end
    else if (state == Findsq2) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd2;
                movedIndex <= 3'd3;
                pX[2] <= pX[3];
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[2];

                pY[2] <= pY[3];
                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[2];
            end
        end
        else begin
            state <= Findsq3;
            fixedIndex <= 3;
            movedIndex <= 3'd4;
        end
    end
    else if (state == Findsq3) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd3;
                movedIndex <= 3'd4;
                pX[3] <= pX[4];
                pX[4] <= pX[5];
                pX[5] <= pX[3];

                pY[3] <= pY[4];
                pY[4] <= pY[5];
                pY[5] <= pY[3];
            end
        end
        else begin
            state <= Findsq4;
            fixedIndex <= 4;
            movedIndex <= 3'd5;
        end

    end
    else if (state == Findsq4) begin
        if (movedIndex <= 3'd5) begin
            if (signedBit == currentSignedBit) begin
                movedIndex <= movedIndex + 1;
            end
            else begin
                fixedIndex <= 3'd4;
                movedIndex <= 3'd5;
                pX[4] <= pX[5];
                pX[5] <= pX[4];
                pY[4] <= pY[5];
                pY[5] <= pY[4];
            end
        end
        else begin
            state <= CheckObj;
            fixedIndex <= 1;
            movedIndex <= 3'd0;
        end
    end
    else if (state == CheckObj) begin
        if (movedIndex < 3'd6) begin
            if (movedIndex == 0) begin
                movedIndex <= movedIndex + 1;
                signedBit <= currentSignedBit;
            end
            else if (signedBit != currentSignedBit) begin
                is_inside <= 0;
                movedIndex <= 3'd6;
            end
            else begin
                movedIndex <= movedIndex + 1;
                is_inside <= 1;
            end
        end
        else begin
            state <= Output;
            movedIndex <= 0;
            valid <= 1;
        end
    end
    else if (state == Output) begin
        state <= LoadData;
        valid <= 0;
    end
    else begin
    
    end
end
*/
always@(*) begin
    if ((state >= Findsq1 && state <= Findsq4) && movedIndex <= 3'd5) begin
        Ax = pX[0] - pX[fixedIndex];
        Ay = pY[0] - pY[fixedIndex];
        Bx = pX[0] - pX[movedIndex];
        By = pY[0] - pY[movedIndex];
    end
    else if (state == CheckObj) begin
        Ax = pX[movedIndex] - objX;
        Ay = pY[movedIndex] - objY;
        if (movedIndex >= 3'd5) begin
            Bx = pX[0] - pX[movedIndex];
            By = pY[0] - pY[movedIndex];
        end
        else begin
            Bx = pX[movedIndex + 1] - pX[movedIndex];
            By = pY[movedIndex + 1] - pY[movedIndex];
        end
    end
    else begin
        Ax = 0;
        Ay = 0;
        Bx = 0;
        By = 0;
    end
end

endmodule
