
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

wire ending;
assign ending = ((gray_addr + 1) & 7'b1111111) == 0;

reg [3:0] count;
reg [7:0] compare;
wire [7:0] multi;
assign multi = count < 4 ? 8'b1 << count : 8'b1 << (count - 1);


wire [8:0] rowTerm;
wire [1:0] colTerm;
assign rowTerm = (count <= 2 ? 0: (count <= 5 ? 128: 256));
assign colTerm = (count % 3);

parameter StandBy = 0, ReqData = 1, Output = 2;
reg [1:0] state;

always@(posedge clk, posedge reset)begin
    if (reset) begin
        state <= StandBy;
        gray_addr <= 129;

        gray_req <= 1;
        lbp_valid <= 0;
        finish <= 0;
    end
    else if (gray_ready && state == StandBy) begin
        state <= ReqData;
        compare <= gray_data;
        gray_addr <= gray_addr - 129;

        count <= 0;
        lbp_data <= 0;
    end
    else if (state == ReqData) begin
        if (count <= 8) begin
            if (gray_data >= compare) begin
                lbp_data <= lbp_data + multi;
            end
            else begin
                lbp_data <= lbp_data + 0;
            end
        end
        else begin
            lbp_data <= lbp_data + 0;
        end

        case(count) 
            0, 1, 6, 7: begin
                gray_addr <= gray_addr + 1;
                count <= count + 1;
            end
            2, 5: begin
                gray_addr <= gray_addr + 126;
                count <= count + 1;
            end
            3: begin
                gray_addr <= gray_addr + 2;
                count <= 5;
            end
            8: begin
                gray_req <= 0;
                count <= count + 1;
            end
            default: begin 
                gray_addr <= gray_addr + 0;
                state <= Output;

                lbp_valid <= 1;
                lbp_addr <= gray_addr - 129;
            end
        endcase
    end
    else if (state == Output) begin
        if (gray_addr == 16383) begin
            lbp_valid <= 0;
            finish <= 1;
        end
        else begin
            if (ending) begin
                gray_addr <= gray_addr - 126;
            end
            else begin    
                gray_addr <= gray_addr - 128;
            end

            state <= StandBy;
            gray_req <= 1;
            lbp_valid <= 0;
        end
    end
    else begin
        gray_req <= 0;
        lbp_valid <= 0;
        finish <= 0;
    end
end

//====================================================================
endmodule
