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
			ForCheckTarget = 2, ForFindPixel = 3, Forward = 4, ForNext = 5,
			BackCheckTarget = 6, BackFindPixel = 7, Backward = 8, BackNext = 9
			;

reg [3:0] state;

// ReadROM
reg [9:0] romIndex;
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


// Backward
reg [7:0] SW;
reg [7:0] S;
reg [7:0] SE;
reg [7:0] E;

reg backCheck;
reg backFindIndex;

wire [7:0] back1 = SW < S ? SW : S;
wire [7:0] back2 = SE < E ? SE : E;
wire [8:0] back3 = back1 < back2 ? back1 : back2;
wire [7:0] backwardMin = target < back3 + 1 ? target : back3 + 1;

always@(posedge clk or negedge reset) begin
	if (!reset) begin
		state <= ReadROM;

		sti_rd <= 1;
		sti_addr <= 0;

		res_wr <= 0;
		res_rd <= 0;
		res_addr <= 16383;
		
		done <= 0;

		romIndex <= 0;
		ramIndex <= 0;

		NW <= 0; N <= 0; NE <= 0; W <= 0; target <= 0;

		forCheck <= 0;
		forFindIndex <= 0;

		SW <= 0; S <= 0; SE <= 0; E <= 0;

		backCheck <= 0;
		backFindIndex <= 0;

	end	
	else if (state == ReadROM) begin
		state <= ROMtoRAM;
		
		sti_rd <= 0;
		res_wr <= 0;
	end
	else if (state == ROMtoRAM) begin
		if (ramIndex == 4'd15) begin
			if (romIndex == 10'd1023) begin
				state <= ForCheckTarget;
				forCheck <= 0;

				romIndex <= 8;
				ramIndex <= 1;
			end
			else begin
				state <= ReadROM;
			
				sti_rd <= 1;
				sti_addr <= romIndex + 1;
				romIndex <= romIndex + 1;
				ramIndex <= 0;
			end
		end
		else begin
			ramIndex <= ramIndex + 1;
		end
		
		res_wr <= 1;
		res_addr <= res_addr + 1;
		res_do <= sti_di[4'd15 - ramIndex];
	end
	else if (state == ForCheckTarget) begin
		if (!forCheck) begin
			forCheck <= 1;

			res_wr <= 0;
			res_rd <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
		end
		else begin
			target <= res_di;

			if (romIndex < 10'd16) begin
				state <= Forward;
				// NW <= 0; N <= 0; NE <= 0;
			end
			else if (((romIndex & 3'b111) == 0) && (ramIndex == 4'd1)) begin
				state <= ForFindPixel;

				NW <= 0; W <= 0;
				forFindIndex <= 0;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex - 128;
			end
			else begin
				state <= ForFindPixel;
				
				NW <= N; N <= NE;
				forFindIndex <= 1;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex - 127;
			end
		end
	end
	else if (state == ForFindPixel) begin
		if (forFindIndex == 0) begin
			res_addr <= res_addr + 1;
			N <= res_di;
			
			forFindIndex <= 1;
		end
		else begin
			state <= Forward;
			
			res_rd <= 0;
			NE <= res_di;
		end
	end
	else if (state == Forward) begin
		state <= ForNext;

		if (target > 0) begin
			res_wr <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
			res_do <= forwardMin + 1;
			
			W <= forwardMin + 1;
		end
		else begin
			W <= 0;		// W <= target
		end
	end
	else if (state == ForNext) begin
		res_wr <= 0;

		if ((((romIndex - 10'd7) & 3'b111) == 0) && (ramIndex == 4'd14)) begin
			if (romIndex == 10'd1015) begin
				state <= BackCheckTarget;
				backCheck <= 0;
			end
			else begin
				state <= ForCheckTarget;
				forCheck <= 0;
				
				romIndex <= romIndex + 1;
				ramIndex <= 1;
			end
		end
		else begin
			state <= ForCheckTarget;
			forCheck <= 0;

			if (ramIndex == 4'd15) begin
				romIndex <= romIndex + 1;
			end
			ramIndex <= ramIndex + 1;
		end
	end
	else if (state == BackCheckTarget) begin
		if (!backCheck) begin
			backCheck <= ~backCheck;

			res_wr <= 0;
			res_rd <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
		end
		else begin
			target <= res_di;

			if (romIndex > 10'd1007) begin
				state <= Backward;
			end
			else if ((((romIndex - 10'd7) & 3'b111) == 0) && (ramIndex == 4'd14)) begin
				state <= BackFindPixel;

				SE <= 0; E <= 0;
				backFindIndex <= 0;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex + 128;
			end
			else begin
				state <= BackFindPixel;

				SE <= S; S <= SW;
				backFindIndex <= 1;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex + 127;
			end
		end
	end
	else if (state == BackFindPixel) begin
		if (backFindIndex == 0) begin
			backFindIndex <= 1;
			
			res_addr <= res_addr - 1;
			S <= res_di;
		end
		else begin
			state <= Backward;

			res_rd <= 0;
			SW <= res_di;
		end
	end
	else if (state == Backward) begin
		state <= BackNext;

		if (target > 0) begin
			res_wr <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
			res_do <= backwardMin;

			E <= backwardMin;
		end
		else begin
			E <= 0;
		end
	end
	else if (state == BackNext) begin
		res_wr <= 0;

		if (((romIndex & 3'b111) == 0) && (ramIndex == 4'd1)) begin
			if (romIndex == 10'd8) begin
				done <= 1;
			end			
			else begin
				state <= BackCheckTarget;
				backCheck <= 0;

				romIndex <= romIndex - 1;
				ramIndex <= 4'd14;
			end
		end
		else begin
			state <= BackCheckTarget;
			backCheck <= 0;

			if (ramIndex == 4'd0) begin
				romIndex <= romIndex - 1;
			end
			ramIndex <= ramIndex - 1;
		end
	end
end

endmodule
