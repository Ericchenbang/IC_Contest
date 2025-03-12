module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [9:0] test [1:0];
reg signed [10:0] receiver [5:0] [1:0];
reg [2:0] inputCount;

reg [1:0] state;
parameter   LoadData = 2'd0,
            Count = 2'd1,
            Output = 2'd2;

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
                            state <= Count;
                        end
                        else
                            inputCount <= inputCount + 1;
                    end
                endcase
            end
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
reg signed [20:0] outProduct;
reg opSignedBit [5:0];
reg [2:0] opIndex;
reg signed [10:0] Ax, By, Ay, Bx;
reg findsq;

reg [2:0] i;
reg [2:0] j;
reg [2:0] k;

always@(state) begin
    if (state == Count) begin
        sq[0] = 3'd0;
        sq[1] = 3'd0;
        sq[2] = 3'd0;
        sq[3] = 3'd0;
        sq[4] = 3'd0;
        sq[5] = 3'd0;
        in = 0;

        // find sq 1
        for (i = 1; i < 3'd6; i = i + 1) begin
            if (i == 1) findsq = 0;

            if (~findsq) begin
                opIndex = 0;
                sq[1] = i;
                Ax = receiver[sq[1]][0] - receiver[0][0];
                Ay = receiver[sq[1]][1] - receiver[0][1];
                
                for (j = 1; j < 3'd6; j = j + 1) begin
                    if (j != i) begin
                        Bx = receiver[j][0] - receiver[0][0];
                        By = receiver[j][1] - receiver[0][1];
                        outProduct = Ax * By - Bx * Ay;
                        //outProduct = (receiver[sq[1]][0] - receiver[0][0])*(receiver[j][1] - receiver[0][1])-(receiver[j][0] - receiver[0][0])*(receiver[sq[1]][1] - receiver[0][1]);
                        opSignedBit[opIndex] = outProduct[20];

                        if (opIndex == 3'd3) begin
                            if (opSignedBit[0] == opSignedBit[1] &&(opSignedBit[1] == opSignedBit[2] && opSignedBit[2] == opSignedBit[3])) begin
                                findsq = 1;
                            end
                            else
                                findsq = 0;
                        end                 
                        else begin
                            opIndex = opIndex + 1;
                        end
                    end
                    else
                        outProduct = 0;
                end
            end
            else
                opIndex = 0;
        end
    
           
        // find sq 2
        for (i = 1; i < 3'd6; i = i + 1) begin
            if (i == 1) findsq = 0;
            if (i != sq[1]) begin
                if (~findsq) begin
                    opIndex = 0;
                    sq[2] = i;
                    Ax = receiver[sq[2]][0] - receiver[0][0];
                    Ay = receiver[sq[2]][1] - receiver[0][1];
                    for (j = 1; j < 3'd6; j = j + 1) begin
                        if (j != i && j != sq[1]) begin
                            Bx = receiver[j][0] - receiver[0][0];
                            By = receiver[j][1] - receiver[0][1];
                            outProduct = Ax * By - Bx * Ay;    
                            //outProduct = (receiver[sq[2]][0] - receiver[0][0])*(receiver[j][1] - receiver[0][1])-(receiver[j][0] - receiver[0][0])*(receiver[sq[2]][1] - receiver[0][1]);
                            opSignedBit[opIndex] = outProduct[20];
                            if (opIndex == 3'd2) begin
                                if (opSignedBit[0] == opSignedBit[3] && (opSignedBit[0] == opSignedBit[1] && opSignedBit[0] == opSignedBit[2]))
                                    findsq = 1;
                                else
                                    findsq = 0;
                            end 
                            else    
                                opIndex = opIndex + 1;
                        end
                        else
                            outProduct = 0;
                    end
                end
                else
                    opIndex = 0;
            end
            else
                opIndex = 0;
        end

        // find sq 3
        for (i = 1; i < 3'd6; i = i + 1) begin
            if (i == 1) findsq = 0;
            if (i != sq[1] && i != sq[2]) begin
                if (~findsq) begin
                    opIndex = 0;
                    sq[3] = i;
                    Ax = receiver[sq[3]][0] - receiver[0][0];
                    Ay = receiver[sq[3]][1] - receiver[0][1];
                    for (j = 1; j < 3'd6; j = j + 1) begin
                        if (j != i && (j != sq[1] && j != sq[2])) begin
                            Bx = receiver[j][0] - receiver[0][0];
                            By = receiver[j][1] - receiver[0][1];
                            outProduct = Ax * By - Bx * Ay;   
                            //outProduct = (receiver[sq[3]][0] - receiver[0][0])*(receiver[j][1] - receiver[0][1])-(receiver[j][0] - receiver[0][0])*(receiver[sq[3]][1] - receiver[0][1]); 
                            opSignedBit[opIndex] = outProduct[20];
                            if (opIndex == 3'd1) begin
                                if (opSignedBit[0] == opSignedBit[1] && opSignedBit[0] == opSignedBit[2])
                                    findsq = 1;
                                else
                                    findsq = 0;
                            end
                            else
                                opIndex = opIndex + 1;
                        end
                        else
                            outProduct = 0;
                    end
                end
                else
                    opIndex = 0;
            end
            else 
                opIndex = 0;
        end

        // find sq 4
        for (i = 1; i < 3'd6; i = i + 1) begin
            if (i == 1) findsq = 0;
            if (i != sq[1] && (i != sq[2] && i != sq[3])) begin
                if (~findsq) begin
                    opIndex = 0;
                    sq[4] = i;
                    Ax = receiver[sq[4]][0] - receiver[0][0];
                    Ay = receiver[sq[4]][1] - receiver[0][1];
                    for (j = 1; j < 3'd6; j = j + 1) begin
                        if (j != i && (j != sq[1] && (j != sq[2] && j != sq[3]))) begin
                            Bx = receiver[j][0] - receiver[0][0];
                            By = receiver[j][1] - receiver[0][1];
                            outProduct = Ax * By - Bx * Ay;    
                            //outProduct = (receiver[sq[4]][0] - receiver[0][0])*(receiver[j][1] - receiver[0][1])-(receiver[j][0] - receiver[0][0])*(receiver[sq[4]][1] - receiver[0][1]);
                            if (outProduct[20] == opSignedBit[0]) begin
                                findsq = 1;
                                for (k = 1; k <= 3'd5; k = k + 1)
                                    if (k != sq[1] && (k != sq[2] && (k != sq[3] && k != sq[4])))
                                        sq[5] = k;    
                                    else
                                        opIndex = 0;
                            end
                            else
                                findsq = 0;
                        end
                        else
                            outProduct = 0;
                    end
                end
                else
                    opIndex = 0;
            end
            else
                opIndex = 0;
        end

        for (i = 0; i < 3'd6; i = i + 1) begin
            Ax = receiver[sq[i]][0] - test[0];
            Ay = receiver[sq[i]][1] - test[1];
            if (i != 3'd5) begin
                Bx = receiver[sq[i+1]][0] - receiver[sq[i]][0];
                By = receiver[sq[i+1]][1] - receiver[sq[i]][1];
                //outProduct = (receiver[sq[i]][0] - test[0])*(receiver[sq[i+1]][1] - receiver[sq[i]][1])-(receiver[sq[i+1]][0] - receiver[sq[i]][0])*(receiver[sq[i]][1] - test[1]);
            end
            else begin
                Bx = receiver[sq[0]][0] - receiver[sq[i]][0];
                By = receiver[sq[0]][1] - receiver[sq[i]][1];
                //outProduct = (receiver[sq[i]][0] - test[0])*(receiver[sq[0]][1] - receiver[sq[i]][1])-(receiver[sq[0]][0] - receiver[sq[i]][0])*(receiver[sq[i]][1] - test[1]);
            end
            outProduct = Ax * By - Bx * Ay;
            opSignedBit[i] = outProduct[20];

            if (opSignedBit[0] == opSignedBit[1] && opSignedBit[0] == opSignedBit[2])
                if (opSignedBit[0] == opSignedBit[3] && (opSignedBit[0] == opSignedBit[4] && opSignedBit[0] == opSignedBit[5]))
                    in = 1;
                else
                    in = 0;
            else
                in = 0;
        end
    end
    else begin
        sq[0] = 3'd0;
        sq[1] = 3'd0;
        sq[2] = 3'd0;
        sq[3] = 3'd0;
        sq[4] = 3'd0;
        sq[5] = 3'd0;

        opIndex = 0;
        outProduct = 0;
        in = 0;
    end
end

endmodule
