
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

reg [7:0] data [0:16383];

reg [14:0] lbpIndex;
initial lbpIndex <= 15'd129;
reg [7:0] lbpData [0:16383];
reg [7:0] localLbpData;
initial localLbpData = 0;
initial gray_addr = 0;

reg addToLbpData;

always@(posedge clk, posedge reset) begin
    if (reset) begin
        gray_req <= 0;
        gray_addr <= 0;
        lbpIndex <= 15'd129;
        lbp_addr <= lbpIndex;
        lbp_valid <= 0;
        finish <= 0;
        addToLbpData <= 0;
        localLbpData <= 0;
    end
    else if (gray_ready && gray_req == 0) begin
        gray_req <= 1;
    end
    else begin
        if (gray_addr <= 15'd16383) begin
            data[gray_addr] <= gray_data;
            gray_addr <= gray_addr + 1;
        end
        else begin
            gray_addr <= gray_addr;
        end
    end
end



// input data transform to LBP
always@(posedge clk) begin
    if (lbp_valid) begin
        lbp_addr <= lbpIndex;
        lbp_data <= lbpData[lbpIndex];

        if (lbpIndex < 15'd16254) begin
            if ((lbpIndex + 15'd2) % 15'd128 == 0)
                lbpIndex <= lbpIndex + 15'd3;
            else
                lbpIndex <= lbpIndex + 1;
        end
        else begin
            lbp_valid <= 0;
            finish <= 1; 
        end
    end
    else if (gray_addr > 15'd258) begin
        if ((lbpIndex + 15'd1) % 15'd128 == 0 || (lbpIndex % 15'd128 == 0))
            localLbpData = 0;
        else begin    
            localLbpData = 0;
            if (data[lbpIndex - 15'd129] >= data[lbpIndex])
                localLbpData = localLbpData + 1;
            else 
                localLbpData = localLbpData + 0;
                
            if (data[lbpIndex - 15'd128] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd2;
            else 
                localLbpData = localLbpData + 0;
                
            if (data[lbpIndex - 15'd127] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd4;
            else 
                localLbpData = localLbpData + 0;
            
            if (data[lbpIndex - 15'd1] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd8;
            else 
                localLbpData = localLbpData + 0;
            
            if (data[lbpIndex + 15'd1] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd16;
            else 
                localLbpData = localLbpData + 0;
                
            if (data[lbpIndex + 15'd127] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd32;
            else 
                localLbpData = localLbpData + 0;
                
            if (data[lbpIndex + 15'd128] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd64;
            else 
                localLbpData = localLbpData + 0;
                
            if (data[lbpIndex + 15'd129] >= data[lbpIndex])
                localLbpData = localLbpData + 8'd128;
            else 
                localLbpData = localLbpData + 0;
        end
        lbpData[lbpIndex] <= localLbpData;
        
        if (lbpIndex <= 15'd16253) begin
            lbpIndex <= lbpIndex + 1;
        end
        else begin
            lbpIndex <= 15'd129;
            lbp_valid <= 1;
        end
    end
    else begin
        lbpData[gray_addr] <= 0;
    end
end

/*always@(*) begin
    if (addToLbpData) begin
        localLbpData = 0;

        if (data[lbpIndex - 15'd129] >= data[lbpIndex])
            localLbpData = localLbpData + 1;
            
        if (data[lbpIndex - 15'd128] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd2;
            
        if (data[lbpIndex - 15'd127] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd4;
        
        if (data[lbpIndex - 15'd1] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd8;
        
        if (data[lbpIndex + 15'd1] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd16;
            
        if (data[lbpIndex + 15'd127] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd32;
            
        if (data[lbpIndex + 15'd128] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd64;
            
        if (data[lbpIndex + 15'd129] >= data[lbpIndex])
            localLbpData = localLbpData + 8'd128;
        
        addToLbpData = 0;
    end
    else begin
        localLbpData = 0;
    end
end*/
//====================================================================
endmodule
