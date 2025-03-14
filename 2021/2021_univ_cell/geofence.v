module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg signed [10:0] test [1:0];
reg signed [10:0] receiver [5:0] [1:0];
reg [2:0] inputCount;

reg [2:0] state;
parameter   LoadData = 3'd0,
            Findsq1 = 3'd1,
            Findsq2 = 3'd2,
            Findsq3 = 3'd3,
            Findsq4 = 3'd4,
            Count = 3'd5,
            Output = 3'd6;

reg in;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        valid <= 0;
        state <= 0;
        inputCount <= 0;
    end
    else begin
        case(state)
            LoadData: begin
                case(inputCount)
                    3'd0: begin
                        test[0] <= X;
                        test[1] <= Y;
                        inputCount <= inputCount + 1;
                    end
                    default: begin
                        receiver[inputCount - 1][0] <= X;
                        receiver[inputCount - 1][1] <= Y;

                        if (inputCount == 3'd6) begin
                            inputCount <= 0;
                            state <= Findsq1;
                        end
                        else
                            inputCount <= inputCount + 1;
                    end
                endcase
            end
            Findsq1: state <= Findsq2;
            Findsq2: state <= Findsq3;
            Findsq3: state <= Findsq4;
            Findsq4: state <= Count;
            Count: begin
                state <= Output;
                is_inside <= in;
                valid <= 1;
            end
            default: begin
                valid <= 0;
                state <= LoadData;
            end
        endcase
    end
end




reg [2:0] sq [5:0];
reg signedBit;
reg lastSignedBit;
reg signed [10:0] Ax, By, Ay, Bx;
reg findsqLayer1;
reg findsqLayer2;
reg layer2FirstTime;
reg completeCount;
reg signed [20:0] outProduct;
reg [2:0] i;
reg [2:0] j;
reg [2:0] k;

always@(state) begin
    if ((state == Findsq1 || state == Findsq2) || (state == Findsq3 || state == Findsq4)) begin      
        sq[0] = 0;
        sq[1] = sq[1] + 0;
        sq[2] = sq[2] + 0;
        sq[3] = sq[3] + 0;
        sq[4] = sq[4] + 0;
        sq[5] = sq[5] + 0;
        
        in = 0;
        
        signedBit = signedBit + 0;
        if (state == Findsq1) begin
            signedBit = 0;
            lastSignedBit = 0;
        end
        else begin
            signedBit = signedBit + 0;
            lastSignedBit = lastSignedBit + 0;
        end

        findsqLayer1 = 0;
        for (i = 1; i < 3'd6; i = i + 1) begin
            if ((i != sq[1] && i != sq[2]) && (i != sq[3] && ~findsqLayer1)) begin
                findsqLayer2 = 1;
                
                sq[state] = i;
                Ax = receiver[i][0] - receiver[0][0];
                Ay = receiver[i][1] - receiver[0][1];
                
                for (j = 1; j < 3'd6; j = j + 1) begin
                    if ((j != i && findsqLayer2) && (j != sq[1] && (j != sq[2] && j != sq[3]))) begin
                        lastSignedBit = signedBit;

                        Bx = receiver[j][0] - receiver[0][0];
                        By = receiver[j][1] - receiver[0][1];
                        outProduct = Ax * By - Bx * Ay;
                        signedBit = outProduct[20];

                        if (signedBit != lastSignedBit) begin
                                signedBit = ~signedBit;
                                findsqLayer2 = 0;
                        end
                        else begin
                            findsqLayer2 = 1;
                        end
                    end
                    else begin
                        Bx = 0;
                        By = 0;
                    end
                end

                if (state == Findsq4) begin
                    if (findsqLayer2) begin
                        findsqLayer1 = 1;
                        for (k = 1; k <= 3'd5; k = k + 1)
                            if ((k != sq[1] && k != sq[2]) && (k != sq[3] && k != sq[4]))
                                sq[5] = k;
                            else
                                Ax = 0;
                    end
                    else
                        findsqLayer1 = 0;
                end
                else begin
                    if (findsqLayer2) 
                        findsqLayer1 = 1;
                    else
                        findsqLayer1 = 0;
                end
            end
            else begin
                Ax = 0;
                Ay = 0;
            end
        end
    end













    /*    



        case(state)
            Findsq1: begin
                // Set receiver[0] as origin, find sq 1
                sq[0] = 3'd0;
                signedBit = 0;
                lastSignedBit = 0;

                for (i = 1; i < 3'd6; i = i + 1) begin
                    if (~findsqLayer1) begin
                        findsqLayer2 = 1;
                        layer2FirstTime = 1;

                        sq[1] = i;
                        Ax = receiver[i][0] - receiver[0][0];
                        Ay = receiver[i][1] - receiver[0][1];
                        
                        for (j = 1; j < 3'd6; j = j + 1) begin
                            if (j != i && findsqLayer2) begin
                                lastSignedBit = signedBit;

                                Bx = receiver[j][0] - receiver[0][0];
                                By = receiver[j][1] - receiver[0][1];
                                outProduct = Ax * By - Bx * Ay;
                                signedBit = outProduct[20];

                                if (layer2FirstTime)
                                    layer2FirstTime = 0;                 
                                else if (signedBit != lastSignedBit) begin
                                    signedBit = ~signedBit;
                                    findsqLayer2 = 0;
                                end
                                else 
                                    findsqLayer2 = 1;
                            end
                            else begin
                                Bx = 0;
                                By = 0;
                            end
                        end
                        if (findsqLayer2) 
                            findsqLayer1 = 1;
                        else
                            findsqLayer1 = 0;
                    end
                    else begin
                        Ax = 0;
                        Ay = 0;
                    end
                end
            end
            Findsq2: begin
                // We find sq[1], and then find sq 2
                for (i = 1; i < 3'd6; i = i + 1) begin
                    if (i != sq[1] && ~findsqLayer1) begin
                        findsqLayer2 = 1;

                        sq[2] = i;
                        Ax = receiver[i][0] - receiver[0][0];
                        Ay = receiver[i][1] - receiver[0][1];

                        for (j = 1; j < 3'd6; j = j + 1) begin
                            if ((j != i && j != sq[1]) && findsqLayer2) begin
                                lastSignedBit = signedBit;

                                Bx = receiver[j][0] - receiver[0][0];
                                By = receiver[j][1] - receiver[0][1];
                                outProduct = Ax * By - Bx * Ay;
                                signedBit = outProduct[20];

                                if (signedBit != lastSignedBit) begin
                                    signedBit = ~signedBit;
                                    findsqLayer2 = 0;
                                end
                                else begin
                                    findsqLayer2 = 1;
                                end
                            end
                            else begin
                                Bx = 0;
                                By = 0;
                            end
                        end
                        if (findsqLayer2) 
                            findsqLayer1 = 1;
                        else
                            findsqLayer1 = 0;
                                    
                    end
                    else begin
                        Ax = 0;
                        Ay = 0;
                    end
                end
            end
            Findsq3: begin
                // We find sq1 and sq2, and then find sq 3
                for (i = 1; i < 3'd6; i = i + 1) begin
                    if ((i != sq[1] && i != sq[2]) && ~findsqLayer1) begin
                        findsqLayer2 = 1;

                        sq[3] = i;
                        Ax = receiver[i][0] - receiver[0][0];
                        Ay = receiver[i][1] - receiver[0][1];

                        for (j = 1; j < 3'd6; j = j + 1) begin
                            if ((j != i && j != sq[1]) && (j != sq[2] && findsqLayer2)) begin
                                lastSignedBit = signedBit;

                                Bx = receiver[j][0] - receiver[0][0];
                                By = receiver[j][1] - receiver[0][1];
                                outProduct = Ax * By - Bx * Ay;
                                signedBit = outProduct[20];

                                if (signedBit != lastSignedBit) begin
                                    signedBit = ~signedBit;
                                    findsqLayer2 = 0;
                                end
                                else 
                                    findsqLayer2 = 1;
                            end
                            else begin
                                Bx = 0;
                                By = 0;
                            end
                        end
                        if (findsqLayer2) 
                            findsqLayer1 = 1;
                        else
                            findsqLayer1 = 0;
                    end
                    else begin
                        Ax = 0;
                        Ay = 0;
                    end
                end
            end
            default: begin
                // We find sq1, sq2 and sq3, and then find sq4 and sq5
                for (i = 1; i < 3'd6; i = i + 1) begin
                    if ((i != sq[1] && i != sq[2]) && (i != sq[3] && ~findsqLayer1)) begin
                        findsqLayer2 = 1;
                        
                        sq[4] = i;
                        Ax = receiver[i][0] - receiver[0][0];
                        Ay = receiver[i][1] - receiver[0][1];
                        for (j = 1; j < 3'd6; j = j + 1) begin
                            if (j != i && (j != sq[1] && (j != sq[2] && j != sq[3]))) begin
                                lastSignedBit = signedBit;

                                Bx = receiver[j][0] - receiver[0][0];
                                By = receiver[j][1] - receiver[0][1];
                                outProduct = Ax * By - Bx * Ay;
                                signedBit = outProduct[20];

                                if (signedBit != lastSignedBit) begin
                                    signedBit = ~signedBit;
                                    findsqLayer2 = 0;
                                end
                                else begin
                                    findsqLayer2 = 1;
                                end
                            end
                            else begin
                                Bx = 0;
                                By = 0;
                            end
                        end
                        if (findsqLayer2) begin
                            findsqLayer1 = 1;
                            for (k = 1; k <= 3'd5; k = k + 1)
                                if ((k != sq[1] && k != sq[2]) && (k != sq[3] && k != sq[4]))
                                    sq[5] = k;
                                else
                                    Ax = 0;
                        end
                        else
                            findsqLayer1 = 0;
                    end
                    else begin
                        Ax = 0;
                        Ay = 0;
                    end
                end
            end
        endcase
    end*/
    else if (state == Count) begin
        in = 0;
        completeCount = 0;
        layer2FirstTime = 1;

        for (i = 0; i < 3'd6; i = i + 1) begin
            if (~completeCount) begin
                lastSignedBit = signedBit;

                Ax = receiver[sq[i]][0] - test[0];
                Ay = receiver[sq[i]][1] - test[1];

                if (i != 3'd5) begin
                    Bx = receiver[sq[i+1]][0] - receiver[sq[i]][0];
                    By = receiver[sq[i+1]][1] - receiver[sq[i]][1];
                    end
                else begin
                    Bx = receiver[sq[0]][0] - receiver[sq[i]][0];
                    By = receiver[sq[0]][1] - receiver[sq[i]][1];
                end

                outProduct = Ax * By - Bx * Ay;
                signedBit = outProduct[20];

                if (layer2FirstTime)
                    layer2FirstTime = 0;
                else if (signedBit != lastSignedBit) begin
                    completeCount = 1;
                end
                else begin
                    completeCount = 0;
                end
            end 
            else
                in = 0;
        end
        if (completeCount)
            in = 0;
        else
            in = 1;

        sq[0] = 3'd0;
        sq[1] = 3'd0;
        sq[2] = 3'd0;
        sq[3] = 3'd0;
        sq[4] = 3'd0;
        sq[5] = 3'd0;
        signedBit = 0;
    end
    else begin
        sq[0] = 3'd0;
        sq[1] = 3'd0;
        sq[2] = 3'd0;
        sq[3] = 3'd0;
        sq[4] = 3'd0;
        sq[5] = 3'd0;

        signedBit = 0;
        findsqLayer1 = 0;
        findsqLayer2 = 0;
        layer2FirstTime = 0;
        completeCount = 0;

        in = 0;
    end
end

endmodule
