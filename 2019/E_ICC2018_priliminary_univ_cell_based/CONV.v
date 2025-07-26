`timescale 1ns/10ps
module  CONV(
	input		clk,
	input		reset,
	output reg	busy,	
	input		ready,	
	output reg [11:0] iaddr,
	input [19:0] idata,	
	output reg cwr,
	output reg [11:0] caddr_wr,
	output reg [19:0] cdata_wr,
	output reg crd,
	output reg [11:0] caddr_rd,
	input [19:0] cdata_rd,
	output reg [2:0] csel
	);

reg [2:0] state;
parameter InputData = 0, Conv = 1, OutputLayer0 = 2, MaxPooling = 3, OutputLayer1 = 4;

// InputData
reg signed[19:0] data [0:8];
// 0~4095
reg [11:0] inputCount;
reg [3:0] dataCount;

// Conv
reg [3:0] convCount;
reg signed  [19:0] kernel [0:8];
reg [19:0] bias;
reg signed [39:0] convResult;

// MaxPooling
reg [11:0] poolCount;
reg [9:0] layer1Index;


always@(posedge clk, posedge reset) begin
	if (reset) begin
		state <= InputData;

		data[0] <= 0;
		data[1] <= 0;
		data[2] <= 0;
		data[3] <= 0;
		data[6] <= 0;
		inputCount <= 0;
		dataCount <= 4;

			
		convCount <= 0;	
		convResult <= 0;

		poolCount <= 0;
		layer1Index <= 0;

		cwr <= 0;
		crd <= 0;
		csel <= 0;
		busy <= 0;
	end
	else if (ready) begin
		kernel[0] <= 20'h0A89E;
		kernel[1] <= 20'h092D5;
		kernel[2] <= 20'h06D43;
		kernel[3] <= 20'h01004;
		kernel[4] <= 20'hF8F71;
		kernel[5] <= 20'hF6E54;
		kernel[6] <= 20'hFA6D7;
		kernel[7] <= 20'hFC834;
		kernel[8] <= 20'hFAC19;
		bias <= 20'h01310;
		busy <= 1;
		
	end
	else if (state == InputData) begin
		if (inputCount <= 63) begin
			if (inputCount == 0) begin
				data[dataCount] <= idata;

				if (dataCount == 4 || dataCount == 7) begin
					dataCount <= dataCount + 1;
				end
				else if (dataCount == 5) begin
					dataCount <= 7;
				end
				else begin  // dataCount == 8
					state <= Conv;
					dataCount <= 5;
				end
			end
			else if (inputCount == 63) begin
				state <= Conv;
				data[3] <= data[4];
				data[4] <= data[5];
				data[5] <= 0;
				data[6] <= data[7];
				data[7] <= data[8];
				data[8] <= 0;
				dataCount <= 1;
			end
			else begin
				data[dataCount] <= idata;

				if (dataCount == 5) begin
					data[3] <= data[4];
					data[4] <= data[5];
					data[6] <= data[7];
					data[7] <= data[8];
					dataCount <= 8;
				end
				else begin
					state <= Conv;	
					dataCount <= 5;
				end
			end
		end
		else if (inputCount >= 4032) begin
			if (inputCount == 4032) begin
				data[dataCount] <= idata;

				if (dataCount == 1 || dataCount == 4) begin
					dataCount <= dataCount + 1;
				end
				else if (dataCount == 2) begin
					dataCount <= 4;
				end
				else begin //dataCount == 5
					state <= Conv;
					data[0] <= 0;
					data[3] <= 0;
					data[6] <= 0;
					data[7] <= 0;
					data[8] <= 0;
					dataCount <= 2;
				end
			end
			else if (inputCount == 4095) begin
				state <= Conv;
				data[0] <= data[1];
				data[1] <= data[2];
				data[2] <= 0;
				data[3] <= data[4];
				data[4] <= data[5];
				data[5] <= 0;
			end
			else begin
				data[dataCount] <= idata;

				if (dataCount == 2) begin
					data[0] <= data[1];
					data[1] <= data[2];
					data[3] <= data[4];
					data[4] <= data[5];
					dataCount <= 5;
				end
				else begin
					state <= Conv;
					dataCount <= 2;
				end
			end
		end
		// MUST ADD ()
		else if ((inputCount & 12'b000000111111) == 0) begin // % 64 == 0
			data[dataCount] <= idata;

			if (dataCount == 1 || (dataCount == 4 || dataCount == 7)) begin
				dataCount <= dataCount + 1;
			end
			else if (dataCount == 2 || dataCount == 5) begin
				dataCount <= dataCount + 2;
			end
			else begin // dataCount == 8
				state <= Conv;
				data[0] <= 0;
				data[3] <= 0;
				data[6] <= 0;
				dataCount <= 2;
			end
		end
		else if (((inputCount+1) & 12'b000000111111) == 0) begin
			state <= Conv;

			data[0] <= data[1];
			data[1] <= data[2];
			data[2] <= 0;
			data[3] <= data[4];
			data[4] <= data[5];
			data[5] <= 0;
			data[6] <= data[7];
			data[7] <= data[8];
			data[8] <= 0;
			dataCount <= 1;

		end
		else begin
			data[dataCount] <= idata;
			if (dataCount == 2 || dataCount == 5) begin
				if (dataCount == 2) begin
					data[0] <= data[1];
					data[1] <= data[2];
					data[3] <= data[4];
					data[4] <= data[5];
					data[6] <= data[7];
					data[7] <= data[8];
				end
				dataCount <= dataCount + 3;
			end
			else begin // dataCount == 8
				state <= Conv;
				dataCount <= 2;
			end
		end
	end
	else if (state == Conv) begin
		if (convCount <= 8) begin
			convResult <= convResult + kernel[convCount] * data[convCount];
			convCount <= convCount + 1;
		end
		else if (convCount == 9) begin
			cdata_wr[19:16] <= convResult[35:32];
			cdata_wr[15:0] <= (convResult[15] == 1 ? convResult[31:16] + 1 : convResult[31:16]);
			caddr_wr <= inputCount;
			convCount <= convCount + 1;
		end
		else if (convCount == 10) begin
			cdata_wr <= cdata_wr + bias;
			convCount <= convCount + 1;
		end
		else begin
			convCount <= 0;
			convResult <= 0;

			state <= OutputLayer0;
			if (cdata_wr[19] == 1) cdata_wr <= 0;
			cwr <= 1;
			csel <= 3'b001;
		end
	end
	else if (state == OutputLayer0) begin
		cwr <= 0;
		csel <= 3'b000;
		if (inputCount == 4095) begin
			state <= MaxPooling;
			crd <= 1;
			csel <= 3'b001;
			cdata_wr <= 0;
			dataCount <= 0;
		end
		else begin
			state <= InputData;
			inputCount <= inputCount + 1;
		end
	end
	else if (state == MaxPooling) begin
		if (dataCount <= 3) begin
			if (cdata_wr < cdata_rd) begin
				cdata_wr <= cdata_rd;
			end
			dataCount <= dataCount + 1;
		end
		else begin
			if (((poolCount + 2) & 6'b111111) == 0) begin
				poolCount <= poolCount + 66;
			end
			else begin
				poolCount <= poolCount + 2;
			end

			state <= OutputLayer1;

			caddr_wr <= layer1Index;

			crd <= 0;
			cwr <= 1;
			csel <= 3'b011;
		end
	end
	else if (state == OutputLayer1) begin
		cwr <= 0;
		if (layer1Index == 1023) begin
			csel <= 0;
			busy <= 0;
		end
		else begin
			state <= MaxPooling;
			layer1Index <= layer1Index + 1;
			crd <= 1;
			csel <= 3'b001;
			cdata_wr <= 0;
			dataCount <= 0;
		end
	end
end


always@(*) begin
	if (state == InputData) begin
		case(dataCount) 
			0: begin
				iaddr = inputCount - 65;
			end
			1: begin
				iaddr = inputCount - 64;
			end
			2: begin
				iaddr = inputCount - 63;
			end
			3: begin
				iaddr = inputCount - 1;
			end
			4: begin
				iaddr = inputCount;
			end
			5: begin
				iaddr = inputCount + 1;
			end
			6: begin
				iaddr = inputCount + 63;
			end
			7: begin
				iaddr = inputCount + 64;
			end
			8: begin
				iaddr = inputCount + 65;
			end
			default: begin
				iaddr = 0;
			end
		endcase
		caddr_rd = 0;
	end
	else if (state == MaxPooling) begin
		case(dataCount)
			0: begin
				caddr_rd = poolCount;
			end
			1: begin
				caddr_rd = poolCount + 1;
			end
			2: begin
				caddr_rd = poolCount + 64;
			end
			3: begin
				caddr_rd = poolCount + 65;
			end
			default: begin
				caddr_rd = 0;
			end
		endcase
		iaddr = 0;
	end
	else begin
		iaddr = 0;
		caddr_rd = 0;
	end
end

endmodule