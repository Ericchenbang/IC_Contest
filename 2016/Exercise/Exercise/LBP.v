
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	        clk;
input   	        reset;
output  reg [14:0] 	gray_addr;
output  reg     	gray_req;
input   	        gray_ready;
input   [7:0] 	    gray_data;
output  reg [14:0] 	lbp_addr;
output  reg 	    lbp_valid;
output  reg [7:0] 	lbp_data;
output  reg	        finish;


//====================================================================

// 129~16254
reg [13:0] lbpIndex;
// 0~8
reg [3:0] lbpCounter;
reg [3:0] localCounter;
// record the nine data
reg [7:0] data [0:8];

reg [7:0] lbpData;
reg [7:0] tempLbpData;

reg [1:0] state;
parameter   LoadData = 2'd0,
            CountLbp = 2'd1,
            OutputLbp = 2'd2,
            Restore = 2'd3;
reg passIndex;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        gray_req <= 0;
        lbp_valid <= 0;
        finish <= 0;

        lbpCounter <= 0;
        state <= LoadData;

        passIndex <= 1;
    end
    else if ((gray_ready && gray_req == 0) && state == LoadData) begin
        gray_req <= 1;
        state <= LoadData;

        lbpIndex <= 14'd129;
        lbpCounter <= 0;

        passIndex <= 1;
    end
    else if (lbpIndex < 14'd16255) begin
        if (state == LoadData) begin
            gray_req <= 1;
            lbp_valid <= 0;

            if (lbpCounter < 4'd9) begin
                if (passIndex) begin
                    case (lbpCounter)
                        4'd0: gray_addr <= lbpIndex - 14'd129;
                        4'd1: gray_addr <= lbpIndex - 14'd128;
                        4'd2: gray_addr <= lbpIndex - 14'd127;
                        4'd3: gray_addr <= lbpIndex - 14'd1;
                        4'd4: gray_addr <= lbpIndex;
                        4'd5: gray_addr <= lbpIndex + 14'd1;
                        4'd6: gray_addr <= lbpIndex + 14'd127;
                        4'd7: gray_addr <= lbpIndex + 14'd128;
                        4'd8: gray_addr <= lbpIndex + 14'd129;
                        default: gray_addr <= 0;
                    endcase
                    localCounter <= lbpCounter;
                    data[localCounter] <= gray_data;
                    lbpCounter <= lbpCounter + 1;
                end
                else begin
                    case (lbpCounter)
                        4'd2: begin
                            gray_addr <= lbpIndex - 14'd127;
                            data[0] <= data[1];
                            data[1] <= data[2];
                            data[3] <= data[4];
                            data[4] <= data[5];
                            data[6] <= data[7];
                            data[7] <= data[8];
                        end
                        4'd5: gray_addr <= lbpIndex + 14'd1;
                        4'd8: gray_addr <= lbpIndex + 14'd129;
                        default: gray_addr <= 0;
                    endcase
                    localCounter <= lbpCounter;
                    data[localCounter] <= gray_data;
                    lbpCounter <= lbpCounter + 3;
                end
            end
            else begin
                localCounter <= lbpCounter;
                data[localCounter] <= gray_data;
                gray_req <= 0;
                state <= OutputLbp;
            end         
        end
        else if (state == OutputLbp) begin
            if (lbp_valid == 0) begin
                lbpData <= tempLbpData;
                lbp_valid <= 1;
            end
            else begin
                lbp_addr <= lbpIndex;
                lbp_data <= lbpData;

                lbpCounter <= 0;
                        
                if ((lbpIndex + 14'd2) % 14'd128 == 0)
                    lbpIndex <= lbpIndex + 14'd3;
                else 
                    lbpIndex <= lbpIndex + 14'd1;
                state <= Restore;
            end
        end
        else begin
            state <= LoadData;
            
            if ((lbpIndex - 1) % 128 == 0) begin
                passIndex <= 1;
                lbpCounter <= 0;
            end
            else begin
                passIndex <= 0;
                lbpCounter <= 2;
            end
                
            gray_req <= 1;
            lbp_valid <= 0;
        end
    end
    else
        finish <= 1;
end


always@(*) begin
    tempLbpData[0] = (data[4] <= data[0]);
    tempLbpData[1] = (data[4] <= data[1]);
    tempLbpData[2] = (data[4] <= data[2]);
    tempLbpData[3] = (data[4] <= data[3]);
    tempLbpData[4] = (data[4] <= data[5]);
    tempLbpData[5] = (data[4] <= data[6]);
    tempLbpData[6] = (data[4] <= data[7]);
    tempLbpData[7] = (data[4] <= data[8]);
end
//====================================================================
endmodule
