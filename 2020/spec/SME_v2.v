module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;

reg [1:0] state;
parameter ReadString = 0, ReadPattern = 1, Compare = 2, Output = 3;

// ReadString
reg [7:0] str [0:31];
reg [5:0] sIndex;
reg [5:0] sLength;

// ReadPattern
reg [7:0] pattern [0:7];
reg [3:0] pIndex;
reg [3:0] pLength;



always@(posedge clk, posedge reset) begin
    if (reset) begin
        state <= Output;

        sIndex <= 0;
        pIndex <= 0;

        match <= 0;
        match_index <= 0;
        valid <= 0;
    end
    else if (state == ReadString) begin
        if (ispattern) begin
            sLength <= sIndex;

            state <= ReadPattern;
            pattern[0] <= chardata;
            pIndex <= 1;
        end
        else begin
            str[sIndex] <= chardata;
            sIndex <= sIndex + 1;
        end 
    end
    else if (state == ReadPattern) begin
        if (!ispattern) begin
            pLength <= pIndex;

            state <= Compare;
            sIndex <= 0;
            pIndex <= 0;
        end
        else begin
            pattern[pIndex] <= chardata;
            pIndex <= pIndex + 1;
        end
    end
    else if (state == Compare) begin
        if (pIndex == pLength) begin
            state <= Output;
            valid <= 1;
        end
        else if (sIndex == sLength && (pIndex != pLength - 1 && pattern[pIndex] != 8'h24)) begin
            state <= Output;
            match <= 0;
            valid <= 1;
        end
        else begin
            if (!match) begin
                if (pattern[0] == 8'h5E) begin
                    if (str[sIndex] == 8'h20 && (str[sIndex + 1] == pattern[1] || pattern[1] == 8'h2E)) begin
                        match <= 1;
                        match_index <= sIndex + 1;

                        sIndex <= sIndex + 2;
                        pIndex <= pIndex + 2;
                    end
                    else if (sIndex == 0 && (str[0] == pattern[1] || pattern[1] == 8'h2E)) begin
                        match <= 1;
                        match_index <= 0;

                        sIndex <= sIndex + 1;
                        pIndex <= pIndex + 2;
                    end
                    else begin
                        sIndex <= sIndex + 1;
                    end
                end
                else begin
                    if (str[sIndex] == pattern[0] || pattern[0] == 8'h2E) begin
                        match <= 1;
                        match_index <= sIndex;

                        sIndex <= sIndex + 1;
                        pIndex <= pIndex + 1;
                    end
                    else begin
                        sIndex <= sIndex + 1;
                    end
                end
            end
            else begin // match == 1
                if (pIndex == pLength - 1 && pattern[pIndex] == 8'h24) begin
                    if (sIndex == sLength || str[sIndex] == 8'h20) begin
                        pIndex <= pIndex + 1;
                    end
                    else begin
                        match <= 0;
                        sIndex <= match_index + 1;
                        pIndex <= 0;
                    end
                end
                else if (pattern[pIndex] == 8'h2E || str[sIndex] == pattern[pIndex]) begin
                    sIndex <= sIndex + 1;
                    pIndex <= pIndex + 1;
                end
                else begin
                    match <= 0;
                    sIndex <= match_index + 1;
                    pIndex <= 0;
                end
            end
        end
    end
    else if (state == Output) begin
        match <= 0;
        valid <= 0;

        if (isstring) begin
            state <= ReadString;
            str[0] <= chardata;
            sIndex <= 1;
        end
        else if (ispattern) begin
            state <= ReadPattern;
            pattern[0] <= chardata;
            pIndex <= 1;
        end
        
    end
end

endmodule
