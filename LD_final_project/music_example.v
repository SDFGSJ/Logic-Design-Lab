`define c   32'd262   // C3
`define d   32'd294
`define e   32'd330
`define f   32'd349
`define g   32'd392   // G3
`define a   32'd440
`define b   32'd494   // B3
`define hc  32'd524   // C4
`define hd  32'd588   // D4
`define he  32'd660   // E4
`define hf  32'd698   // F4
`define hg  32'd784   // G4
`define ha  32'd880
`define hb  32'd988

`define sil   32'd50000000 // slience


module music_example (
    input clk,
    input rst,
	input [11:0] ibeatNum,
	input en,
    input [15:0] switch,
	output reg [31:0] toneL,
    output reg [31:0] toneR,
    output reg [15:0] led
);
    reg [15:0] led_next;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            led <= 16'b1000_0000_0000_0000;
        end else begin
            led <= led_next;
        end
    end

    always @* begin
        toneR = `sil;
        led_next = led;
        if(en) begin   //play
            if(0<=ibeatNum && ibeatNum<4) begin
                if(switch[15]) begin
                    toneR = `c;
                end
                led_next = 1<<15;
            end else if(4<=ibeatNum && ibeatNum<8) begin
                if(switch[14]) begin
                    toneR = `d;
                end
                led_next = 1<<14;
            end else if(8<=ibeatNum && ibeatNum<12) begin
                if(switch[13]) begin
                    toneR = `e;
                end
                led_next = 1<<13;
            end else if(12<=ibeatNum && ibeatNum<16) begin
                if(switch[12]) begin
                    toneR = `f;
                end
                led_next = 1<<12;
            end else if(16<=ibeatNum && ibeatNum<20) begin
                if(switch[11]) begin
                    toneR = `g;
                end
                led_next = 1<<11;
            end else if(20<=ibeatNum && ibeatNum<24) begin
                if(switch[10]) begin
                    toneR = `a;
                end
                led_next = 1<<10;
            end else if(24<=ibeatNum && ibeatNum<28) begin
                if(switch[9]) begin
                    toneR = `b;
                end
                led_next = 1<<9;
            end else if(28<=ibeatNum && ibeatNum<32) begin
                if(switch[8]) begin
                    toneR = `hc;
                end
                led_next = 1<<8;
            end else if(32<=ibeatNum && ibeatNum<36) begin
                if(switch[7]) begin
                    toneR = `hd;
                end
                led_next = 1<<7;
            end else if(36<=ibeatNum && ibeatNum<40) begin
                if(switch[6]) begin
                    toneR = `he;
                end
                led_next = 1<<6;
            end else if(40<=ibeatNum && ibeatNum<44) begin
                if(switch[5]) begin
                    toneR = `hf;
                end
                led_next = 1<<5;
            end else if(44<=ibeatNum && ibeatNum<48) begin
                if(switch[4]) begin
                    toneR = `hg;
                end
                led_next = 1<<4;
            end else if(48<=ibeatNum && ibeatNum<52) begin
                if(switch[3]) begin
                    toneR = `ha;
                end
                led_next = 1<<3;
            end else if(52<=ibeatNum && ibeatNum<56) begin
                if(switch[2]) begin
                    toneR = `hb;
                end
                led_next = 1<<2;
            end else if(56<=ibeatNum && ibeatNum<60) begin
                if(switch[1]) begin
                    toneR = `ha;
                end
                led_next = 1<<1;
            end else if(60<=ibeatNum && ibeatNum<64) begin
                if(switch[0]) begin
                    toneR = `hg;
                end
                led_next = 1;
            end else begin
                toneR = `sil;
            end
        end
    end

    always @(*) begin
        toneL = toneR;
    end
endmodule