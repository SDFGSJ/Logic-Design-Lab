module clock_divider #(parameter n=25)(
    input clk,
    output clk_div
);
    reg [n-1:0] num=0;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end
    assign next_num = num+1;
    assign clk_div = num[n-1];
endmodule

module mem_addr_gen2(
    input clk,
    input rst,
    input hold,
    /*inout PS2_CLK,
    inout PS2_DATA,*/
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output reg [16:0] pixel_addr
);
    /*wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
	reg [3:0] key_num;

    KeyboardDecoder keydecode(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(key_valid),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );
    */
    always @(*) begin
        //1st row,all clockwise 90
        //formula:(Max-(h_cnt>>1))*320 + (min+(v_cnt>>1)). Max/min = max/min num of the horizontal range
        if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ( (80-(h_cnt>>1) )*320 + (v_cnt>>1) ) % 76800;

        end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ((160-(h_cnt>>1) )*320 + 80+(v_cnt>>1) )% 76800;

        end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ((240-(h_cnt>>1) )*320 + 160+(v_cnt>>1) )% 76800;

        end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 0 <= v_cnt>>1 && v_cnt>>1 < 80) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ((320-(h_cnt>>1) )*320 + 240+(v_cnt>>1) )% 76800;

        //2nd row,all counter clockwise 90
        //formula:((h_cnt>>1)+80-min)*320 + (80+Max-(v_cnt>>1)) Max/min=max/min num of the horizontal range
        end else if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ( ((h_cnt>>1)+80-0 )*320 + ( 80+80-(v_cnt>>1) ) ) % 76800;

        end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ( ((h_cnt>>1)+80-80)*320 + ( 80+160-(v_cnt>>1)) ) % 76800;

        end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ( ((h_cnt>>1)+80-160)*320 + ( 80+240-(v_cnt>>1)) ) % 76800;

        end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 80 <= v_cnt>>1 && v_cnt>>1 < 160) begin

            pixel_addr = (hold) ? ((h_cnt>>1)+320*(v_cnt>>1))%76800 : ( ((h_cnt>>1)+80-240)*320 + ( 80+320-(v_cnt>>1)) ) % 76800;

        //3rd row,not yet
        end else if(0 <= h_cnt>>1 && h_cnt>>1 < 80 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin

            pixel_addr = ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original

        end else if(80 <= h_cnt>>1 && h_cnt>>1 < 160 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin

            pixel_addr = ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original

        end else if(160 <= h_cnt>>1 && h_cnt>>1 < 240 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin

            pixel_addr = ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original

        end else if(240 <= h_cnt>>1 && h_cnt>>1 < 320 && 160 <= v_cnt>>1 && v_cnt>>1 < 240) begin

            pixel_addr = ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original

        end else begin
            pixel_addr = ( (h_cnt>>1) + 320*(v_cnt>>1) )% 76800;  //640*480 --> 320*240 original
        end
    end
endmodule

module lab7_2(
    input clk,
    input rst,
    input hold,
    inout PS2_CLK,
    inout PS2_DATA,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output pass
);
    wire [11:0] data;
    wire clk_25MHz;
    wire clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? pixel : 12'h0;
    assign data = {vgaRed, vgaGreen, vgaBlue};

    clock_divider #(.n(2)) c25MHz(.clk(clk), .clk_div(clk_25MHz)); //100/4 = 25Mhz
    clock_divider #(.n(22)) c22(.clk(clk), .clk_div(clk_22));

    mem_addr_gen2 mem_addr_gen_inst(
        .clk(clk_22),
        .rst(rst),
        .hold(hold),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
    );
    
    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    ); 

    vga_controller vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
endmodule