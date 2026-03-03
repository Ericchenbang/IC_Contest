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


parameter ReadROM = 0, ROMtoRAM = 1, 
			ForCheckTarget = 2, ForFindPixel = 3, Forward = 4, ForNext = 5
			BackCheckTarget = 6, BackFindPixel = 7, Backward = 8, BackNext = 9
			;

reg [3:0] state;

// ReadROM
reg [9:0] romIndex;
reg [15:0] romData;
// ROMtoRAM
reg [3:0] ramIndex;

// Forward

reg [7:0] NW;
reg [7:0] N;
reg [7:0] NE;
reg [7:0] W;
reg [7:0] target;

reg forCheck;
reg forFindIndex;

wire [7:0] compare1 = NW < N ? NW : N;
wire [7:0] compare2 = NE < W ? NE : W;
wire [7:0] forwardMin = compare1 < compare2 ? compare1 : compare2;












always@(posedge clk or posedge reset) begin
	if (reset) begin
		state <= ReadROM;

		sti_rd <= 1;
		sti_addr <= 0;

		res_wr <= 0;
		res_rd <= 0;
		res_addr <= 0;
		
		done <= 0;


		romIndex <= 0;
		ramIndex <= 0;

		NW <= 0; N <= 0; NE <= 0; W <= 0; target <= 0;

		forCheck <= 0;
		forFindIndex <= 0;



	end	
	else if (state == ReadROM) begin
		state <= ROMOutput;
		
		sti_rd <= 0;
		romData <= sti_di;

		res_wr <= 0;
	end
	else if (state == ROMtoRAM) begin
		if (ramIndex == 4'd15) begin
			if (romIndex == 10'd1023) begin
				state <= ForCheckTarget;

				romIndex <= 8;
				ramIndex <= 1;

			end
			else begin
				state <= ReadROM;
			
				sti_rd <= 1;
				sti_addr <= romIndex;

				romIndex <= romIndex + 1;
			end
		end
		
		res_wr <= 1;
		res_addr <= res_addr + 1;
		res_do <= romData[ramIndex];
		
		ramIndex <= ramIndex + 1;
	end
	else if (state == ForCheckTarget) begin
		if (!forCheck) begin
			res_wr <= 0;
			res_rd <= 1;
			res_addr <= (romIndex << 4) + ramIndex;

			forCheck <= 1;
		end
		else begin
			if (romIndex < 10'd8) begin
				state <= Forward;

				NW <= 0; N <= 0; NE <= 0;

			end
			else if ((romIndex & 3'b111 == 0) && (ramIndex == 3'd1)) begin
				NW <= 0;
				W <= 0;

				res_addr <= (romIndex << 4) + ramIndex - 128;
				forFindIndex <= 0;
			
			end
			else begin
				NW <= N;
				N <= NE;

				res_addr <= (romIndex << 4) + ramIndex - 127;
				forFindIndex <= 1;
			end

			state <= ForFindPixel;
			res_rd <= 1;
			target <= res_di;
		end
	end
	else if (state == ForFindPixel) begin
		if (forFindIndex == 0) begin
			
			N <= res_di;
			res_addr <= res_addr + 1;

			forFindIndex <= 1;
		end
		else begin
			if (target > 0) begin
				state <= Forward;
			end
			else begin
				state <= ForNext;
				
				W <= 0;

			end
			
			res_rd <= 0;
			NE <= res_di;
		end
	end
	else if (state == Forward) begin
		state <= ForNext;

		res_wr <= 1;
		res_addr <= (romIndex << 4) + ramIndex;
		res_do <= forwardMin;
		
		W <= forwardMin;
	end
	else if (state == ForNext) begin
		if (((romIndex - 10'd7) & 3'd000 == 0) && ramIndex == 4'd14) begin
			if (romIndex == 10'd1015) begin
				state <= // Backward;

			end
			else begin
				state <= ForCheckTarget;
				forCheck <= 0;

				res_wr <= 0;
				romIndex <= romIndex + 1;
				ramIndex <= 1;
			end
		end
		else if (ramIndex == 4'd15) begin
			state <= ForCheckTarget;
			forCheck <= 0;

			res_wr <= 0;
			romIndex <= romIndex + 1;
			ramIndex <= 0;
		end
		else begin
			state <= ForCheckTarget;
			forCheck <= 0;

			res_wr <= 0;
			ramIndex <= ramIndex + 1;
		end

	


	end
	else if (state == )


end

endmodule
