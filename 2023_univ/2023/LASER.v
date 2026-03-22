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
localparam FindC1_0 = 3'd2;
localparam FindC1_1 = 3'd3;
localparam FindC2 = 3'd4;
localparam CountIn = 3'd5;
localparam Output = 3'd6;

// ReadData
reg [3:0] pts [39:0][1:0];

reg [5:0] cnt;
wire [5:0] cnt_add_1 = cnt + 6'd1;
wire read_end = (cnt == 6'd39);

// FindC1_0
reg firstC1;
reg [3:0] cx, cy;
wire [3:0] cx_begin = 4'd15, cy_begin = 4'd0; 
wire [3:0] cx_end = 4'd0, cy_end = 4'd15;
wire find_end = (cx == cx_end && cy == cy_end);
wire [3:0] cx_next = cx - 4'd1;
wire [3:0] cy_next = (cx == cx_end) ? cy - 4'd1 : cy;

reg [4:0] c1_x_max, c1_y_max, c2_x_max, c2_y_max;
reg in_curr [39:0];
reg in_c1 [39:0], in_c2 [39:0];
wire in_both [39:0];

for (gv_i = 0; gv_i < 40; gv_i = gv_i + 1) begin
    checkIn u_checkIn (.x(pts[gv_i][0]), .y(pts[gv_i][1]), .cx(cx), .cy(cy), .in(in_curr[gv_i]));

    assign in_both[gv_i] = (in_c1[gv_i] || in_c2[gv_i]);
end

/*
wire [1:0] t0 [19:0];
wire [2:0] t1 [9:0];
wire [3:0] t2 [4:0];
for (gv_i = 0; 2 * gv_i < 40; gv_i = gv_i + 1) begin
    assign t0[gv_i] = in_curr[2 * gv_i] + in_curr[2 * gv_i + 1];
end
for (gv_i = 0; 2 * gv_i < 20; gv_i = gv_i + 1) begin
    assign t1[gv_i] = t0[2 * gv_i] + t0[2 * gv_i + 1];
end
for (gv_i = 0; 2 * gv_i < 10; gv_i = gv_i + 1) begin
    assign t2[gv_i] = t1[2 * gv_i] + t1[2 * gv_i + 1];
end
wire [4:0] in_cnt = t2[4] + t2[3] + t2[2] + t2[1] + t2[0];
*/

wire [1:0] in_total_1 [19:0];
wire [2:0] in_total_2 [9:0];
wire [3:0] in_total_3 [4:0];

for (gv_i = 0; 2 * gv_i < 40; gv_i = gv_i + 1) begin
    assign in_total_1[gv_i] = in_both[2*gv_i] + in_both[2*gv_i+1];
end
for (gv_i = 0; 2 * gv_i < 20; gv_i = gv_i + 1) begin
    assign in_total_2[gv_i] = in_total_1[2*gv_i] + in_total_1[2*gv_i+1];
end
for (gv_i = 0; 2 * gv_i < 10; gv_i = gv_i + 1) begin
    assign in_total_3[gv_i] = in_total_2[2*gv_i] + in_total_2[2*gv_i+1];
end
wire [4:0] in_total = in_total_3[4] + in_total_3[3] + in_total_3[2] + in_total_3[1] + in_total_3[0]; 
reg [4:0] in_total_max;
reg [4:0] last_in_total_max;

reg [2:0] last_state;
always @(*) begin
    next_state = state;
    case(state) 
        Idle: begin
            next_state = ReadData;
        end
        ReadData: begin
            if (read_end) begin
                next_state = FindC1_0;
            end
            else begin
                next_state = ReadData;
            end
        end
        FindC1_0: begin
            next_state = FindC1_1;
        end
        FindC1_1: begin
            if (find_end) begin
                next_state = CountIn;
            end
            else begin
                next_state = FindC1_1;
            end
        end
        FindC2: begin
            if (find_end) begin
                next_state = CountIn;
            end
            else begin
                next_state = FindC2;
            end
        end
        CountIn: begin
            if (last_in_total_max == in_total_max) begin
                next_state = Output;
            end
            else if (last_state == FindC1_1) begin
                next_state = FindC2;
            end
            else if (last_state == FindC2) begin
                next_state = FindC1_1;
            end
        end
        Output: begin
            next_state <= ReadData;
        end
    endcase
end

always@(posedge CLK or posedge RST) begin
    if (RST) begin
        state <= Idle;
    end
    else begin
        state <= next_state;
    end
end




always @(posedge CLK) begin
    case (state)
        Idle: begin
            cnt <= 6'd1;
            pts[39][0] <= X;
            pts[39][1] <= Y;

        end
        ReadData: begin
            firstC1 <= 1'b1;
            cnt <= cnt_add_1;

            pts[39][0] <= X;
            pts[39][1] <= Y;
            for (i = 0; i < 39; i = i + 1) begin
                pts[i][0] <= pts[i+1][0];
                pts[i][1] <= pts[i+1][1];
                in_c1[i] <= 0;
                in_c2[i] <= 0;
            end

            in_total_max <= 0;
            last_in_total_max <= 0;
        end
        FindC1_0: begin
            cx <= cx_begin;
            cy <= cy_begin;

        end
        FindC1_1: begin
            if (find_end) begin
                cx <= cx_begin;
                cy <= cy_begin;
                last_state <= FindC1_1;
            end
            else begin
                cx <= cx_next;
                cy <= cy_next;
            end

            if (in_total > in_total_max) begin
                for (i = 0; i < 40; i = i + 1) begin
                    in_c1[i] <= in_curr[i];
                end
                in_total_max <= in_total;
                c1_x_max <= cx;
                c1_y_max <= cy;
            end
        end
        FindC2: begin
            if (find_end) begin
                cx <= cx_begin;
                cy <= cy_begin;
                last_state <= FindC1_1;
            end
            else begin
                cx <= cx_next;
                cy <= cy_next;
            end

            if (in_total > in_total_max) begin
                for (i = 0; i < 40; i = i + 1) begin
                    in_c2[i] <= in_curr[i];
                end
                in_total_max <= in_total;
                c2_x_max <= cx;
                c2_y_max <= cy;
            end
        end
        CountIn: begin
            if (last_state == FindC1_1) begin
                C1X <= c1_x_max;
                C1Y <= c1_y_max;
            end
            else if (last_state == FindC2) begin
                C2X <= c2_x_max;
                C2Y <= c2_y_max;
            end
            
            last_in_total_max <= in_total_max;
            cx <= cx_begin;
            cy <= cy_begin;
        end
        Output: begin
            DONE <= 1'b0;
            cnt <= 6'b0;
        end
    endcase
end

endmodule



module checkIn (
    input [3:0] x, y, cx, cy,
    output in
);
    wire [3:0] xd = (x > cx) ? x - cx : cx - x;
    wire [3:0] yd = (y > cy) ? y - cy : cy - y;

    wire [3:0] ld, sd;
    assign ld = (xd > yd) ? xd : yd;
    assign sd = (xd > yd) ? yd : xd;

    assign in = ((ld <= 4'd4 && sd <= 4'd0) || 
                 (ld <= 4'd3 && sd <= 4'd2)); 
endmodule