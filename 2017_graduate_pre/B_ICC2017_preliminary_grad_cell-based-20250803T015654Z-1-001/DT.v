module DT(
	input clk, 
	input reset,
	
	output reg		   	sti_rd,
	output reg 	[9:0]   sti_addr,
	input		[15:0]  sti_di,

	output reg	    	res_wr,
	output reg			res_rd,
	output reg 	[13:0]	res_addr,
	output reg 	[7:0]	res_do,
	input		[7:0]	res_di,

	output reg done 
	);


parameter ReadROM = 0, ROMOutput = 1, Forward = 2;
reg [2:0] state;

// ReadROM
reg [9:0] romIndex;
reg [15:0] romData;

reg [3:0] ramIndex;

always@(posedge clk or posedge reset) begin
	if (reset) begin
		state <= ROMOutput;

		romIndex <= 0;
		ramIndex <= 0;

		sti_rd <= 1;
		sti_addr <= 0;

		res_wr <= 0;
		res_rd <= 0;
		res_addr <= 0;
		res_do <= 0;
		
		done <= 0;
	end	
	else if (state == ReadROM) begin
		state <= ROMOutput;
		
		sti_rd <= 0;
		romData <= sti_di;

		res_wr <= 0;

		romIndex <= romIndex + 1;
	end
	else if (state == ROMOutput) begin
		if (ramIndex == 4'd15) begin
			if (romIndex == 10'd1023) begin
				state <= Forward;


			end
			else begin
				state <= ReadROM;
			
				sti_rd <= 1;
				sti_addr <= romIndex;
			end
			
		end
		
		res_wr <= 1;
		res_addr <= romIndex << 4 + ramIndex;
		res_do <= romData[ramIndex];
		
		ramIndex <= ramIndex + 1;
	end
	else if (state == Forward) begin
		done <= 1;
	end

end

endmodule
