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
		ForCheckTarget = 2, ForFindPixel = 3, Output = 4, ForNext = 5,
		BackCheckTarget = 6, BackFindPixel = 7, BackNext = 8;
reg [3:0] state;


reg [9:0] romIndex;
reg [3:0] ramIndex;

// Forward
reg [7:0] A, B, C, D;
reg [7:0] target;

reg check;
reg findIndex;

reg forward;

wire [7:0] compare1 = A < B ? A : B;
wire [7:0] compare2 = C < D ? C : D;
wire [7:0] forwardMin = compare1 < compare2 ? compare1 + 1: compare2 + 1;

// Backward
wire [7:0] backwardMin = target < forwardMin? target : forwardMin;

wire [7:0] outputMin = forward ? forwardMin: backwardMin;

wire [2:0] romMod8 = (romIndex & 3'b111);
wire [2:0] romMinus7Mod8 = ((romIndex - 10'd7) & 3'b111);



always@(posedge clk or negedge reset) begin
	if (!reset) begin
		state <= ROMtoRAM;

		sti_rd <= 1;
		sti_addr <= 0;

		res_wr <= 0;
		res_rd <= 0;
		res_addr <= 16383;
		
		done <= 0;

		romIndex <= 0;
		ramIndex <= 0;

		A <= 0; B <= 0; C <= 0; D <= 0; target <= 0;

		check <= 0;
		findIndex <= 0;

		forward <= 1;
	end	
	else if (state == ReadROM) begin
		state <= ROMtoRAM;
		
		sti_rd <= 0;
		res_wr <= 0;
	end
	else if (state == ROMtoRAM) begin
		res_wr <= 1;
		res_addr <= res_addr + 1;

		if (romIndex < 10'd8 || romIndex > 10'd1015) begin
			res_do <= 8'd0;
			ramIndex <= ramIndex + 1;
			
			if (ramIndex == 4'd15) begin
				romIndex <= romIndex + 1;

				if (romIndex == 10'd7) begin
					state <= ReadROM;

					sti_rd <= 1;
					sti_addr <= romIndex + 1;
				end
				else if (romIndex == 10'd1023) begin
					state <= ForCheckTarget;
					check <= 0;

					romIndex <= 10'd8;
					ramIndex <= 4'd1;
				end
			end
		end
		else begin
			res_do <= sti_di[4'd15 - ramIndex];
			ramIndex <= ramIndex + 1;

			if (ramIndex == 4'd15) begin
				state <= ReadROM;
			
				sti_rd <= 1;
				sti_addr <= romIndex + 1;
				romIndex <= romIndex + 1;
			end
		end
	end
	else if (state == ForCheckTarget) begin
		if (!check) begin
			check <= 1;

			res_wr <= 0;
			res_rd <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
		end
		else begin
			target <= res_di;

			if (romIndex < 10'd16) begin
				state <= Output;
				// A <= 0; B <= 0; C <= 0;
			end
			else if ((romMod8 == 0) && (ramIndex == 4'd1)) begin
				state <= ForFindPixel;

				A <= 0; D <= 0;
				findIndex <= 0;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex - 128;
			end
			else begin
				state <= ForFindPixel;
				
				A <= B; B <= C;
				findIndex <= 1;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex - 127;
			end
		end
	end
	else if (state == ForFindPixel) begin
		if (!findIndex) begin
			res_addr <= res_addr + 1;
			B <= res_di;
			
			findIndex <= 1;
		end
		else begin
			state <= Output;
			
			res_rd <= 0;
			C <= res_di;
		end
	end
	else if (state == Output) begin
		state <= forward ? ForNext : BackNext;

		if (target > 0) begin
			res_wr <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
			res_do <= outputMin;
			D <= outputMin;
		end
		else begin
			D <= 0;		// D <= target
		end
	end
	else if (state == ForNext) begin
		res_wr <= 0;
		check <= 0;

		if ((romMinus7Mod8 == 0) && (ramIndex == 4'd14)) begin
			if (romIndex == 10'd1015) begin
				state <= BackCheckTarget;
				forward <= 0;
			end
			else begin
				state <= ForCheckTarget;
				
				romIndex <= romIndex + 1;
				ramIndex <= 1;
			end
		end
		else begin
			state <= ForCheckTarget;

			if (ramIndex == 4'd15) begin
				romIndex <= romIndex + 1;
			end
			ramIndex <= ramIndex + 1;
		end
	end
	else if (state == BackCheckTarget) begin
		if (!check) begin
			check <= ~check;

			res_wr <= 0;
			res_rd <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
		end
		else begin
			target <= res_di;

			if (romIndex > 10'd1007) begin
				state <= Output;
			end
			else if ((romMinus7Mod8 == 0) && (ramIndex == 4'd14)) begin
				state <= BackFindPixel;

				C <= 0; D <= 0;
				findIndex <= 0;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex + 128;
			end
			else begin
				state <= BackFindPixel;

				C <= B; B <= A;
				findIndex <= 1;
				res_rd <= 1;
				res_addr <= (romIndex << 4) + ramIndex + 127;
			end
		end
	end
	else if (state == BackFindPixel) begin
		if (findIndex == 0) begin
			findIndex <= 1;
			
			res_addr <= res_addr - 1;
			B <= res_di;
		end
		else begin
			state <= Output;

			res_rd <= 0;
			A <= res_di;
		end
	end
	/*else if (state == Backward) begin
		state <= BackNext;

		if (target > 0) begin
			res_wr <= 1;
			res_addr <= (romIndex << 4) + ramIndex;
			res_do <= backwardMin;

			D <= backwardMin;
		end
		else begin
			D <= 0;
		end
	end*/
	else if (state == BackNext) begin
		res_wr <= 0;
		check <= 0;

		if ((romMod8 == 0) && (ramIndex == 4'd1)) begin
			if (romIndex == 10'd8) begin
				done <= 1;
			end			
			else begin
				state <= BackCheckTarget;
	
				romIndex <= romIndex - 1;
				ramIndex <= 4'd14;
			end
		end
		else begin
			state <= BackCheckTarget;

			if (ramIndex == 4'd0) begin
				romIndex <= romIndex - 1;
			end
			ramIndex <= ramIndex - 1;
		end
	end
end

endmodule
