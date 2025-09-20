module geofence (clk, reset, X, Y, valid, is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;

reg [1:0] state;
parameter InputData = 0, FindSeq = 1, Judge = 2, Output = 3;

// InputData
reg [2:0] dataCount;

reg [9:0] objX;
reg [9:0] objY;

reg signed [10:0] fenX [0:5];
reg signed [10:0] fenY [0:5];


// FindSeq
reg [1:0] seqCount;

reg signed [10:0] Ax;
reg signed [10:0] Ay;
reg signed [10:0] Bx;
reg signed [10:0] By;

wire signed [19:0] AxBy;
wire signed [19:0] BxAy; 
assign AxBy = Ax * By;
assign BxAy = Bx * Ay;

reg lastResult;

wire currResult;
assign currResult = AxBy > BxAy ? 0:1;

reg rotate;

// Judge
wire [2:0] BIndex;
assign BIndex = dataCount == 5 ? 0 : dataCount + 1;


always@(posedge clk, posedge reset) begin
	if (reset) begin
		// InputData
		state <= InputData;
		dataCount <= 0;

		valid <= 0;
	end
	else if (state == InputData) begin
		if (dataCount == 0) begin
			objX <= X;
			objY <= Y;
			dataCount <= dataCount + 1;
		end
		else begin
			fenX[dataCount - 1] <= X;
			fenY[dataCount - 1] <= Y;
			if (dataCount == 3'd6) begin
				state <= FindSeq;
				seqCount <= 0;
				dataCount <= 0;
				rotate <= 0;
			end
			else begin
				dataCount <= dataCount + 1;
			end
		end
	end
	else if (state == FindSeq) begin
		if (rotate) begin
			fenX[5] <= fenX[seqCount + 3'd1];
			fenY[5] <= fenY[seqCount + 3'd1];
			fenX[4] <= fenX[5];
			fenY[4] <= fenY[5];
			
			if (seqCount != 3) begin
				fenX[3] <= fenX[4];
				fenY[3] <= fenY[4];
				fenX[4] <= fenX[5];
				fenY[4] <= fenY[5];
				if (seqCount <= 1) begin
					fenX[2] <= fenX[3];
					fenY[2] <= fenY[3];
				end
				
				if (seqCount <= 0) begin
					fenX[1] <= fenX[2];
					fenY[1] <= fenY[2];
				end
			end	
			rotate <= 0;
		end
		else begin
			if (seqCount == 0 && dataCount == 0) begin
				lastResult <= AxBy > BxAy ? 0:1;
				dataCount <= dataCount + 1;
			end
			else if (currResult == lastResult) begin
				if (seqCount == 3) begin
					state <= Judge;

					dataCount <= 0;
					seqCount <= 0;
				end
				else if (dataCount + seqCount == 3) begin
					dataCount <= 0;
					seqCount <= seqCount + 1;
				end
				else begin
					dataCount <= dataCount + 1;
				end
			end
			else begin
				dataCount <= 0;
				rotate <= 1;
			end
		end
	end
	else if (state == Judge) begin
		if (dataCount == 0) begin
			lastResult <= AxBy > BxAy ? 0:1;
			dataCount <= dataCount + 1;
		end
		if (currResult == lastResult) begin
			if (dataCount == 5) begin
				state <= Output;
				is_inside <= 1;
				valid <= 1;

				dataCount <= 0;
			end
			else begin
				dataCount <= dataCount + 1;
			end
		end
		else begin
			state <= Output;
			is_inside <= 0;
			valid <= 1;

			dataCount <= 0;
		end
	end
	else if (state == Output) begin
		state <= InputData;
		valid <= 0;
	end
end



always@(*) begin
	if (state == FindSeq) begin
		if (!rotate) begin
			Ax = fenX[seqCount + 1] - fenX[seqCount];
			Ay = fenY[seqCount + 1] - fenY[seqCount];
			Bx = fenX[dataCount + 2 + seqCount] - fenX[seqCount];
			By = fenY[dataCount + 2 + seqCount] - fenY[seqCount];
		end
		else begin
			Ax = 0;
			Ay = 0;
			Bx = 0;
			By = 0;
		end
	end
	else if (state == Judge) begin
		Ax = fenX[dataCount] - objX;
		Ay = fenY[dataCount] - objY;
		Bx = fenX[BIndex] - fenX[dataCount];
		By = fenY[BIndex] - fenY[dataCount];
	end
	else begin
		Ax = 0;
		Ay = 0;
		Bx = 0;
		By = 0;
	end
end

endmodule
