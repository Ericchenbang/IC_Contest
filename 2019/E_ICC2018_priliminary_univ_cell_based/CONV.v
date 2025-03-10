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
parameter 	StoreData = 3'd0,
			// do convolution and ReLu 
			Conv = 3'd1,
			WriteLayerZero = 3'd2,
			ReadData = 3'd3,
			WriteLayerOne = 3'd4;

reg signed [19:0] kernel [8:0];
reg signed [19:0] bias;

reg signed [19:0] data [8:0];
reg signed [43:0] convProduct;

// from 0 to 4096
reg [11:0] inputIndex;
// inputIndex had gone through 0 to 4096
reg completeLayerZero;


// read the data from layer 0 and store them
reg signed [20:0] pool[3:0];
// from 0 to 1031
reg [11:0] outputIndex;
// compare the four data and find the maxest in combination circuit
reg signed [20:0] max;

always@(posedge clk, posedge reset) begin
	if (reset) begin
		state <= 0;

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


		inputIndex <= 0;

		iaddr <= 0;
		busy <= 0;
		cwr <= 0;
		crd <= 0;
		csel <= 0;
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
	else if (busy) begin
		if (state == StoreData) begin
			// first row
			if (inputIndex >= 0 && inputIndex <= 12'd63) begin
				if (inputIndex == 0) begin
					if (iaddr == 0) begin
						data[0] <= 0;
						data[1] <= 0;
						data[2] <= 0;
						data[3] <= 0;
						data[6] <= 0;
						data[4] <= idata;
						iaddr <= 12'd1;
					end
					else if (iaddr == 12'd1) begin
						data[5] <= idata;
						iaddr <= 12'd64;
					end
					else if (iaddr == 12'd64) begin
						data[7] <= idata;
						iaddr <= 12'd65;
					end
					else begin
						state <= Conv;
						data[8] <= idata;
						iaddr <= 12'd2;
					end
				end
				else if (inputIndex == 12'd63) begin
					state <= Conv;
					data[3] <= data[4];
					data[4] <= data[5];
					data[5] <= 0;
					data[6] <= data[7];
					data[7] <= data[8];
					data[8] <= 0;
					iaddr <= 12'd64;
				end
				else begin
					if (iaddr == inputIndex + 1) begin
						data[3] <= data[4];
						data[4] <= data[5];
						data[6] <= data[7];
						data[7] <= data[8];
						data[5] <= idata;
						iaddr <= iaddr + 12'd64;
					end
					else begin
						state <= Conv;
						data[8] <= idata;
						iaddr <= iaddr - 12'd64 + 1;
					end
				end
			end
			// last row
			else if (inputIndex >= 12'd4032 && inputIndex <= 12'd4095) begin
				if (inputIndex == 12'd4032) begin
					if (iaddr == inputIndex) begin
						data[0] <= 0;
						data[3] <= 0;
						data[6] <= 0;
						data[7] <= 0;
						data[8] <= 0;
						data[4] <= idata;
						iaddr <= iaddr + 1;
					end
					else if (iaddr == inputIndex + 1) begin
						data[5] <= idata;
						iaddr <= inputIndex - 12'd64; 
					end
					else if (iaddr == inputIndex - 12'd64) begin
						data[1] <= idata;
						iaddr <= inputIndex - 12'd64 + 1;
					end
					else begin
						state <= Conv;
						data[2] <= idata;
						iaddr <= inputIndex + 2;
					end
				end
				else if (inputIndex == 12'd4095) begin
					state <= Conv;
					data[0] <= data[1];
					data[1] <= data[2];
					data[2] <= 0;
					data[3] <= data[4];
					data[4] <= data[5];
					data[5] <= 0;
					completeLayerZero <= 1;
				end
				else begin
					if (iaddr == inputIndex + 1) begin
						data[0] <= data[1];
						data[1] <= data[2];
						data[3] <= data[4];
						data[4] <= data[5];
						data[5] <= idata;
						iaddr <= iaddr - 12'd64;
					end
					else begin
						state <= Conv;
						data[2] <= idata;
						iaddr <= iaddr + 12'd64 + 1;
					end
				end
			end
			// first column
			else if (inputIndex % 12'd64 == 0) begin
				if (iaddr == inputIndex) begin
					data[0] <= 0;
					data[3] <= 0;
					data[6] <= 0;
					data[4] <= idata;
					iaddr <= inputIndex + 1;
				end
				else if (iaddr == inputIndex + 1) begin
					data[5] <= idata;
					iaddr <= inputIndex - 12'd64;
				end
				else if (iaddr == inputIndex - 12'd64) begin
					data[1] <= idata;
					iaddr <= iaddr + 1;
				end
				else if (iaddr == inputIndex - 12'd64 + 1) begin
					data[2] <= idata;
					iaddr <= inputIndex + 12'd64;
				end
				else if (iaddr == inputIndex + 12'd64) begin
					data[7] <= idata;
					iaddr <= iaddr + 1;
				end
				else begin
					state <= Conv;
					data[8] <= idata;
					iaddr <= iaddr - 12'd64 + 1;
				end
			end
			// last column
			else if ((inputIndex + 1) % 12'd64 == 0) begin
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

			end
			// rest pixel
			else begin
				if (iaddr == inputIndex + 1) begin
					data[0] <= data[1];
					data[1] <= data[2];
					data[3] <= data[4];
					data[4] <= data[5];
					data[6] <= data[7];
					data[7] <= data[8];
					data[5] <= idata;
					iaddr <= inputIndex + 1 - 12'd64;
				end
				else if (iaddr == inputIndex + 1 - 12'd64) begin
					data[2] <= idata;
					iaddr <= inputIndex + 1 + 12'd64;
				end
				else begin
					state <= Conv;
					data[8] <= idata;
					iaddr <= iaddr - 12'd64 + 1;
				end
			end

		end
		else if (state == Conv) begin
			state <= WriteLayerZero;

			cdata_wr <= convProduct;
			caddr_wr <= inputIndex;
			
			csel <= 3'b001;
			cwr <= 1;
			
		end
		else if (state == WriteLayerZero) begin
			if (completeLayerZero) begin
				state <= ReadData;
				outputIndex <= 0;

				crd <= 1;
				caddr_rd <= 0;
				csel <= 3'b01;
			end
			else begin
				state <= StoreData;
				csel <= 3'b000;
			end
			inputIndex <= inputIndex + 1; 
			cwr <= 0;

		end
		else if (state == ReadData) begin
			if (caddr_rd == inputIndex) begin
				pool[0] <= cdata_rd;
				caddr_rd <= inputIndex + 1;
			end
			else if (caddr_rd == inputIndex + 1) begin
				pool[1] <= cdata_rd;
				caddr_rd <= inputIndex + 12'd64;
			end
			else if (caddr_rd == inputIndex + 12'd64) begin
				pool[2] <= cdata_rd;
				caddr_rd <= inputIndex + 12'd64 + 1;
			end
			else begin
				state <= WriteLayerOne;
				pool[3] <= cdata_rd;
				
			end

		end
		else begin
			if (~cwr) begin
				caddr_wr <= outputIndex;
				outputIndex <= outputIndex + 1;
				cdata_wr <= max;

				csel <= 3'b011;
				cwr <= 1;
			end
			else begin
				if (inputIndex < 12'd4030) begin
					if ((inputIndex + 12'd2) % 12'd64 == 0) begin
						inputIndex <= inputIndex + 12'd2 + 12'd64;
						caddr_rd <= inputIndex + 12'd2 + 12'd64;
					end
					else begin
						inputIndex <= inputIndex + 12'd2;
						caddr_rd <= inputIndex + 12'd2; 
					end
					state <= ReadData;
					crd <= 1;
					cwr <= 0;
					csel <= 3'b001;
				end
				else begin
					busy <= 0;
					crd <= 0;
					cwr <= 0;
					csel <= 3'b000;

				end
			end
		end
	end
	else begin
		crd <= 0;
		cwr <= 0;
		csel <= 3'b000;
	end
end


reg [3:0] i;
//reg [43:0] temp [8:0];


always@(state) begin
	if (state == Conv || state == WriteLayerZero) begin
		max = 0;
		convProduct = {bias, 16'd0};
		for (i = 0; i <= 8; i = i + 1) begin
			convProduct = convProduct + data[i] * kernel[i];
		end

		/*temp[0] = data[0] * kernel[0];
		temp[1] = data[1] * kernel[1];
		temp[2] = data[2] * kernel[2];
		temp[3] = data[3] * kernel[3];
		temp[4] = data[4] * kernel[4];
		temp[5] = data[5] * kernel[5];
		temp[6] = data[6] * kernel[6];
		temp[7] = data[7] * kernel[7];
		temp[8] = data[8] * kernel[8];
		convProduct = {bias, 16'd0} + temp[0] + temp[1] + temp[2] + temp[3] + temp[4] + temp[5] + temp[6] + temp[7] + temp[8];
		*/

		if (convProduct[43] == 1) 
			convProduct = 0;
		else
			convProduct = {convProduct[43], convProduct[34:16]} + convProduct[15];

	end
	else if (state == ReadData || state == WriteLayerOne) begin
		convProduct = 0;

		max = pool[0];
		for (i = 1; i <= 3; i = i + 1) begin
			if (pool[i] > max)
				max = pool[i];
			else 
				max = max + 0;
		end

	end
	else begin
		max = 0;
		convProduct = 0;
	end
end

endmodule