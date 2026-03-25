
module REFRACT(
    input  wire        CLK,
    input  wire        RST,
    input  wire [3:0]  RI,   
    output      [8:0]  SRAM_A,
    output      [15:0] SRAM_D,
    input  wire [15:0] SRAM_Q,   // unused
    output reg         SRAM_WE,
    output reg         DONE
);

reg [4:0] state, next_state;
localparam Idle         = 5'd0;
localparam Count_x_2    = 5'd1;
localparam Count_x_3    = 5'd2;
localparam Count_x_8    = 5'd3;
localparam Count_gx_0   = 5'd4;
localparam Count_1_div_g_2 = 5'd5;
localparam Count_k      = 5'd6;
localparam Count_sqrt_0 = 5'd7;
localparam Count_sqrt_1 = 5'd8;
localparam Count_sqrt_2 = 5'd9;
localparam Count_coef_0 = 5'd10;
localparam Count_t      = 5'd11;
localparam Count_zx_0   = 5'd12;
localparam Count_zx_1   = 5'd13;
localparam Count_zx_2   = 5'd14;
localparam Output_zx    = 5'd15;
localparam Output_zy    = 5'd16;
localparam Finish       = 5'd17;

reg signed [16:0] eta;          // 16:12, 11:0
reg signed [24:0] eta_temp;
reg [27:0] eta_eta;
wire [15:0] eta_2 = eta_eta[27:12];

reg [3:0] x, y;
reg signed [16:0] Z;            // 16:12, 11:0
reg signed [40:0] Z_temp;      
wire [3:0] x_next = x + 4'd1;
wire [3:0] y_next = (x == 4'd15) ? y + 4'd1 : y;
wire xy_end = (x == 15) && (y == 15);

wire x_lt_8 = (x < 4'd8);
wire y_lt_8 = (y < 4'd8);
wire [3:0] x_sub_8 = (x_lt_8) ? 4'd8 - x : x - 4'd8;
wire [3:0] y_sub_8 = (y_lt_8) ? 4'd8 - y : y - 4'd8;
wire [15:0] x_1, y_1;
assign x_1[15:9] = x_sub_8; assign x_1[8:0] = 0;
assign y_1[15:9] = y_sub_8; assign y_1[8:0] = 0;

reg [25:0] x_1_mul_x_1, y_1_mul_y_1;
reg [25:0] x_1_mul_x_2, y_1_mul_y_2;
reg [25:0] x_2_mul_x_2, y_2_mul_y_2;
reg [26:0] x_3_mul_x_4, y_3_mul_y_4;
reg [26:0] x_4_mul_x_4, y_4_mul_y_4;

wire [14:0] x_2 = x_1_mul_x_1[25:12], y_2 = y_1_mul_y_1[25:12];
wire [14:0] x_3 = x_1_mul_x_2[25:12], y_3 = y_1_mul_y_2[25:12];
wire [14:0] x_4 = x_2_mul_x_2[25:12], y_4 = y_2_mul_y_2[25:12];
wire [15:0] x_7 = x_3_mul_x_4[26:12], y_7 = y_3_mul_y_4[26:12];
wire [15:0] x_8 = x_4_mul_x_4[26:12], y_8 = y_4_mul_y_4[26:12];

wire signed [16:0] gx, gy;
assign gx = (x_lt_8) ? (-x_7 << 1) : (x_7 << 1);
assign gy = (y_lt_8) ? (-y_7 << 1) : (y_7 << 1);

reg [27:0] gx_mul_gx, gy_mul_gy;
wire [15:0] gx_2 = gx_mul_gx[27:12], gy_2 = gy_mul_gy[27:12];
wire signed [16:0] g_2 = gx_2 + gy_2 + (1 << 12);
wire signed [24:0] g_2_wire = {g_2, 6'b00_0000};
 
reg [15:0] one_div_g_2;
reg signed [27:0] k_temp;       // 27:24, 23:0
wire signed [27:0] k = (1 << 24) - k_temp;  // 27:24, 23:0

reg [41:0] k_mul_g_2;       // 41:36, 35:0
reg start;
wire sqrt_finish;
wire [20:0] sqrt_result;    // 20:18, 17:0
DW_sqrt_seq #(
    .width(42),
    .tc_mode(0),
    .num_cyc(6)
) U_sqrt (
    .clk(CLK),
    .rst_n(~RST),
    .start(!start),
    .hold(1'b0),
    .a(k_mul_g_2),
    .root(sqrt_result),
    .complete(sqrt_finish)
);

reg signed [39:0] eta_sub_sqrt;
reg signed [24:0] coef;         // 24:18, 17:0
reg signed [24:0] t;            // 24:18, 17:0

reg signed [40:0] t_mul_coef;   // 40:36, 35:0
wire signed [16:0] t_mul_coef_wire = {t_mul_coef[40:36], t_mul_coef[35:24]};    // 16:12, 11:0

reg signed [28:0] zx, zy;   // 35:24, 23:0

wire [4:0] x_a = x << 1;
wire [8:0] y_a = y << 5;
wire [8:0] add = x_a + y_a;
wire [8:0] add_next = add + 9'd1;
wire [27:0] zx_output = (zx[28]) ? -zx : zx;
wire [27:0] zy_output = (zy[28]) ? -zy : zy;
assign SRAM_A = (state == Output_zx) ? add : add_next; 
assign SRAM_D = (state == Output_zx) ? zx_output[27:12] : zy_output[27:12];


always @(*) begin
    next_state = state;
    if (state <= Output_zx) begin
        if (state == Count_sqrt_2 && !sqrt_finish) begin
            next_state = state;
        end
        else begin
            next_state = state + 1;
        end
    end
    else if (state == Output_zy) begin
        if (xy_end) begin
            next_state = Finish;
        end
        else begin
            next_state = Count_x_2;
        end
    end
end

always @(posedge CLK or posedge RST) begin
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
            eta <= 0;
            eta_temp <= 0;
            eta_eta <= 0;

            x <= 0;
            y <= 0;
            Z <= 0;
            Z_temp <= 0;

            x_1_mul_x_1 <= 0;
            y_1_mul_y_1 <= 0;
            x_1_mul_x_2 <= 0;
            y_1_mul_y_2 <= 0;
            x_2_mul_x_2 <= 0;
            y_2_mul_y_2 <= 0;
            x_3_mul_x_4 <= 0;
            y_3_mul_y_4 <= 0;
            x_4_mul_x_4 <= 0;
            y_4_mul_y_4 <= 0;

            gx_mul_gx <= 0; gy_mul_gy <= 0;

            one_div_g_2 <= 0;
            k_temp <= 0;
            
            k_mul_g_2 <= 0;
            start <= 0;

            eta_sub_sqrt <= 0;
            coef <= 0;
            t <= 0;

            t_mul_coef <= 0;

            zx <= 0;
            zy <= 0;

            SRAM_WE <= 0;
            DONE <= 0;
        end
        Count_x_2: begin
            eta <= (1 << 12) / RI;

            x_1_mul_x_1 <= x_1 * x_1;
            y_1_mul_y_1 <= y_1 * y_1;
            
        end
        Count_x_3: begin
            eta_temp <= {eta, 6'b00_0000};
            eta_eta <= (eta * eta);

            x_1_mul_x_2 <= x_2 * x_1;
            y_1_mul_y_2 <= y_2 * y_1;

            x_2_mul_x_2 <= x_2 * x_2;
            y_2_mul_y_2 <= y_2 * y_2;
        end
        Count_x_8: begin
            x_3_mul_x_4 <= x_4 * x_3;
            y_3_mul_y_4 <= y_4 * y_3;

            x_4_mul_x_4 <= x_4 * x_4;
            y_4_mul_y_4 <= y_4 * y_4;
        end
        Count_gx_0: begin
            Z <= (6 << 12) - (x_8 << 1) - (y_8 << 1);

            gx_mul_gx <= gx * gx;
            gy_mul_gy <= gy * gy;
        end
        Count_1_div_g_2: begin
            one_div_g_2 <=  (1 << 12) - ((1 << 24) / g_2);
        end
        Count_k: begin
            k_temp <= eta_2 * one_div_g_2;
        end
        Count_sqrt_0: begin
            k_mul_g_2 <= k * g_2;
        end
        Count_sqrt_1: begin
            start <= 1'b1;
        end
        Count_sqrt_2: begin
            if (sqrt_finish) begin
                start <= 1'b0;
                eta_sub_sqrt <= eta_temp - sqrt_result;
            end
        end
        Count_coef_0: begin
            coef <= ((eta_sub_sqrt << 18) / g_2_wire);
            Z_temp <= (-Z) << 6;
        end
        Count_t: begin
            t <= ((Z_temp << 18) / (-eta_temp + coef));
        end
        Count_zx_0: begin
            t_mul_coef <= t * coef;
        end
        Count_zx_1: begin
            zx <= t_mul_coef_wire * gx;
            zy <= t_mul_coef_wire * gy;
            
        end
        Count_zx_2: begin
            zx <= {x, 24'h00_0000} + zx;
            zy <= {y, 24'h00_0000} + zy;

            SRAM_WE <= 1;
        end
        Output_zy: begin
            SRAM_WE <= 0;

            x <= x_next;
            y <= y_next;

            if (xy_end) begin
                DONE <= 1'b1;
            end
        end
    endcase
end


endmodule


