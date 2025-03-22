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
parameter LoadData = 2'd0, Compare = 2'd1, StoreMatch = 2'd2, Output = 2'd3;


// LoadData
reg [7:0] str [31:0];
reg [5:0] strlen;
reg [7:0] pattern [8:0];
reg [3:0] patlen;

// Compare
reg [5:0] strIndex;
reg [3:0] patIndex;



always@(posedge clk, posedge reset) begin
    if (reset) begin
        state <= LoadData;

        // LoadCost
        strlen <= 0;
        patlen <= 0;

        // Compare
        strIndex <= 0;
        patIndex <= 0;
        match <= 0;
        match_index <= 0;

    end
    else if (state == LoadData) begin
        if (isstring) begin
            str[strlen] <= chardata;
            strlen <= strlen + 1;
        end
        else if (ispattern) begin
            pattern[patlen] <= chardata;
            patlen <= patlen + 1;
        end
        else begin
            state <= Compare;
        end

    end
    else if (state == Compare) begin
        // all words in pattern match in str 
        if (patIndex >= patlen) begin
            state <= StoreMatch;
        end
        else if (strIndex < strlen || pattern[patIndex] == 8'h24) begin
            // ^
            if (pattern[patIndex] == 8'h5E) begin
                if (strIndex == 0) begin
                    patIndex <= patIndex + 1;
                    match <= 1;
                    match_index <= 0;
                end
                else if (str[strIndex] == 8'h20) begin
                    strIndex <= strIndex + 1;
                    patIndex <= patIndex + 1;
                    match <= 1;
                    match_index <= strIndex + 1;
                end
                else begin
                    strIndex <= strIndex + 1;
                    match <= 0;
                end
            end
            // $
            else if (pattern[patIndex] == 8'h24) begin
                if (strIndex == strlen || str[strIndex] == 8'h20) begin
                    patIndex <= patIndex + 1;
                end
                else begin
                    strIndex <= match_index + 1;
                    patIndex <= 0;
                    match <= 0;
                end
            end
            // .
            else if (pattern[patIndex] == 8'h2E) begin
                strIndex <= strIndex + 1;
                patIndex <= patIndex + 1;
                
                if (match == 0) begin
                    match <= 1;
                    match_index <= strIndex;
                end
            end
            // match
            else if (pattern[patIndex] == str[strIndex]) begin
                strIndex <= strIndex + 1;
                patIndex <= patIndex + 1;
                if (match == 0) begin
                    match <= 1;
                    match_index <= strIndex;
                end
            end
            // not match
            else begin
                if (match) begin
                    // ?
                    strIndex <= match_index + 1;
                    patIndex <= 0;
                    match <= 0;
                end
                else begin
                    strIndex <= strIndex + 1;
                end
            end
        end
        else begin
            if (patIndex < patlen) begin
                match <= 0;
            end
            else begin
                match <= 1;
            end
            state <= StoreMatch;
        end
    end
    else if (state == StoreMatch) begin
        state <= Output;
        valid <= 1;
    end
    else begin
        if (isstring) begin
            valid <= 0;
            str[0] <= chardata;
            strlen <= 1;
            patlen <= 0;
            state <= LoadData;
            match <= 0;
            strIndex <= 0;
            patIndex <= 0;
        end
        else if (ispattern) begin
            valid <= 0;
            pattern[0] <= chardata;
            patlen <= 1;
            state <= LoadData;
            match <= 0;
            strIndex <= 0;
            patIndex <= 0;
        end
        else begin
            valid <= 0;
            state <= LoadData;
            match <= 0;
            strIndex <= 0;
            patIndex <= 0;
        end
    end
end





endmodule
