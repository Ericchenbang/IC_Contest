module LASER (
    input CLK,
    input RST,
    input [3:0] X,
    input [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
);
integer i;
genvar gv_i;

reg [2:0] state, next_state;
localparam Idle = 3'd0;
localparam ReadData = 3'd1;
localparam FindC_0 = 3'd2;
localparam FindC_1 = 3'd3;
localparam Count_0 = 3'd4;
localparam Count_1 = 3'd5;
localparam Compare = 3'd6;
localparam Output = 3'd7;

// ReadData
reg [3:0] pts [39:0][1:0];

reg [5:0] cnt;
wire [5:0] cnt_add_1 = cnt + 6'd1;
wire read_end = (cnt == 6'd39);
wire [4:0] cnt_mul_20 = (cnt == 0) ? 5'd0 : 5'd20;

// FindC1_0
reg [3:0] cx, cy;
wire [3:0] cx_begin_0 = 4'd15, cy_begin_0 = 4'd0;
wire [3:0] cx_begin_1 = 4'd12, cy_begin_1 = 4'd2; 
wire [3:0] cx_end = 4'd3, cy_end = 4'd12;
wire find_end = (cx == cx_end && cy == cy_end);
wire [3:0] cx_next = (cx == cx_end) ? 4'd13 : cx - 4'd1;
wire [3:0] cy_next = (cx == cx_end) ? cy + 4'd1 : cy;

reg [4:0] cx_max, cy_max;

reg in_curr [39:0];
reg in_curr_max [39:0];
reg in_circle [39:0];
wire in_both [39:0];

wire in [19:0];
generate 
    for (gv_i = 0; gv_i < 20; gv_i = gv_i + 1) begin: CK
        wire [3:0] x_sel = pts[cnt_mul_20 + gv_i][0]; 
        wire [3:0] y_sel = pts[cnt_mul_20 + gv_i][1];

        checkIn u_ck (.x(x_sel), .y(y_sel), .cx(cx), .cy(cy), .in(in[gv_i]));
    end
endgenerate

generate
    for (gv_i = 0; gv_i < 40; gv_i = gv_i + 1) begin
        assign in_both[gv_i] = (in_curr[gv_i] || in_circle[gv_i]); 
    end
endgenerate

wire [1:0] in_both_1 [19:0];
reg  [1:0] in_both_1_reg [19:0];
wire [2:0] in_both_2 [9:0];
wire [3:0] in_both_3 [4:0];

generate
    for (gv_i = 0; (gv_i << 1) < 40; gv_i = gv_i + 1) begin
        assign in_both_1[gv_i] = in_both[(gv_i << 1)] + in_both[(gv_i << 1) + 1];
    end
    for (gv_i = 0; (gv_i << 1) < 20; gv_i = gv_i + 1) begin
        assign in_both_2[gv_i] = in_both_1_reg[(gv_i << 1)] + in_both_1_reg[(gv_i << 1) + 1];
    end
    for (gv_i = 0; (gv_i << 1) < 10; gv_i = gv_i + 1) begin
        assign in_both_3[gv_i] = in_both_2[(gv_i << 1)] + in_both_2[(gv_i << 1) + 1];
    end
endgenerate

wire [4:0] t0 = (in_both_3[4] + in_both_3[3]) , t1 = (in_both_3[2] + in_both_3[1]);
wire [4:0] in_curr_total = t0 + t1 + in_both_3[0]; 

reg [4:0] in_total_max;
reg [4:0] last_in_total_max;

reg last_state;     // 1: FindC1, 0: FindC2
reg improve;

wire changeXY = (last_state) ? (C1X != cx || C1Y != cy) : (C2X != cx || C2Y != cy);

always @(*) begin
    next_state = state;
    case(state) 
        Idle:
            next_state = ReadData;
        ReadData:
            if (read_end) next_state = FindC_0;
        FindC_0:
            next_state = FindC_1;
        FindC_1:
            if (cnt == 6'd1) next_state = Count_0;
        Count_0:
            next_state = Count_1;
        Count_1:
            if (find_end) next_state = Compare;
            else next_state = FindC_1;
        Compare: begin
            if (!improve && (last_in_total_max == in_total_max)) begin
                next_state = Output;
            end
            else begin
                next_state = FindC_1;
            end
        end
        Output: begin
            if (DONE) begin
                next_state = ReadData;    
            end 
        end
    endcase
end

always@(posedge CLK or posedge RST) begin
    if (RST) begin 
        DONE <= 1'b0;
        state <= Idle;
    end
    else begin
        if (state == Output && !DONE) begin
            DONE <= 1'b1;
        end
        else begin
            DONE <= 1'b0;
        end
        state <= next_state;        
    end
end


always @(posedge CLK) begin    
    case (state)
        Idle: begin
            C1X <= 4'd0; C1Y <= 4'd0;
            C2X <= 4'd0; C2Y <= 4'd0;
            cx_max <= 0; cy_max <= 0;

            cnt <= 6'd1;
            pts[39][0] <= X;
            pts[39][1] <= Y;
            improve <= 1'b1;

            for (i = 0; i < 40; i = i + 1) begin
                in_curr[i] <= 0;
                in_curr_max[i] <= 0;
                in_circle[i] <= 0;
            end

            for (i = 0; i < 20; i = i + 1) begin
                in_both_1_reg[i] <= 0;
            end
        end
        ReadData: begin
            cnt <= cnt_add_1;
            
            
            pts[39][0] <= X;
            pts[39][1] <= Y;
            for (i = 0; i < 39; i = i + 1) begin
                pts[i][0] <= pts[i+1][0];
                pts[i][1] <= pts[i+1][1];
            end
            
            in_total_max <= 0;
            last_in_total_max <= 0;
            last_state <= 1'b0;
        end
        FindC_0: begin
            cx <= cx_begin_0;
            cy <= cy_begin_0;
            cnt <= 6'd0;
        end
        FindC_1: begin
            cnt <= cnt_add_1;

            for (i = 0; i < 20; i = i + 1) begin
                in_curr[cnt_mul_20 + i] <= in[i];
            end
        end
        Count_0: begin
            for (i = 0; i < 20; i = i + 1) begin
                in_both_1_reg[i] <= in_both_1[i];
            end
        end
        Count_1: begin
            if (find_end) begin
                cx <= cx_begin_1;
                cy <= cy_begin_1;
                last_state <= ~last_state;
            end
            else begin
                cx <= cx_next;
                cy <= cy_next;
            end

            if (in_curr_total >= in_total_max) begin
                if (changeXY || (in_curr_total > in_total_max)) begin
                    for (i = 0; i < 40; i = i + 1) begin
                        in_curr_max[i] <= in_curr[i];
                    end

                    cx_max <= cx;
                    cy_max <= cy;

                    in_total_max <= in_curr_total;                    
                end
            end
        end
        Compare: begin
            if (last_state) begin
                C1X <= cx_max;
                C1Y <= cy_max;
            end
            else begin
                C2X <= cx_max;
                C2Y <= cy_max;
            end
            
            if (last_in_total_max == in_total_max) begin
                if (improve) begin
                    improve <= 1'b0;
                    in_total_max <= 0;
                end
                else begin
                    improve <= 1'b1;
                end
            end
            else begin
                last_in_total_max <= in_total_max;
                in_total_max <= 0;
            end

            for (i = 0; i < 40; i = i + 1) begin
                in_circle[i] <= in_curr_max[i];
            end
        end
        Output: begin
            cnt <= 6'b0;
        end
    endcase
end

endmodule


module checkIn (
    input [3:0] x, y, cx, cy,
    output in
);

    wire [3:0] xd_abs = (x > cx) ? x - cx : cx - x;
    wire [3:0] yd_abs = (y > cy) ? y - cy : cy - y;

    wire [3:0] ld, sd;
    assign ld = (xd_abs > yd_abs) ? xd_abs : yd_abs;
    assign sd = (xd_abs > yd_abs) ? yd_abs : xd_abs;

    assign in = ((ld <= 4'd4 && sd <= 4'd0) || 
                 (ld <= 4'd3 && sd <= 4'd2)); 
endmodule