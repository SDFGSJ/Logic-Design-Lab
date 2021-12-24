//BTNL, BTNR
module speed_controller(
    input clk,
    input rst,
    input speedup,
    input speeddown,
    output reg play_clk
);
    wire clkDiv21, clkDiv22, clkDiv23;
    clock_divider #(.n(21)) clock_21(.clk(clk), .clk_div(clkDiv21));    // for player[fast]
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for player[normal]
    clock_divider #(.n(23)) clock_23(.clk(clk), .clk_div(clkDiv23));    // for player[slow]

    wire speedup_debounced, speeddown_debounced;
    wire speedup_1p, speeddown_1p;
    debounce speed_up_de(   .clk(clk), .pb(speedup),    .pb_debounced(speedup_debounced));
    debounce speed_down_de( .clk(clk), .pb(speeddown),  .pb_debounced(speeddown_debounced));

    onepulse speed_up_op(   .clk(clk), .signal(speedup_debounced),   .op(speedup_1p));
    onepulse speed_down_op( .clk(clk), .signal(speeddown_debounced), .op(speeddown_1p));

    reg [1:0] speed = 2'd2, speed_next;    //speed: 1~3, default = 2
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            speed <= 2'd2;
        end else begin
            speed <= speed_next;
        end
    end

    always @(*) begin
        speed_next = speed;
        if(speedup_1p) begin
            if(speed == 2'd3) begin
                speed_next = 2'd3;
            end else begin
                speed_next = speed+1;
            end
        end

        if(speeddown_1p) begin
            if(speed == 2'd1) begin
                speed_next = 2'd1;
            end else begin
                speed_next = speed-1;
            end
        end
    end

    //assign the clock
    always @(*) begin
        if(speed==1) begin  //slow
            play_clk = clkDiv23;
        end else if (speed==2) begin    //normal
            play_clk = clkDiv22;
        end else begin  //fast
            play_clk = clkDiv21;
        end
    end
endmodule