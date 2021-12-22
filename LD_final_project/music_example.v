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
    output reg [31:0] toneR
);
    always @* begin
        toneR = `sil;
        if(en == 1) begin   //demonstrate mode
            if(0<=ibeatNum && ibeatNum<4 && switch[15]) begin
                toneR = `c;
            end else if(4<=ibeatNum && ibeatNum<8 && switch[14]) begin
                toneR = `d;
            end else if(8<=ibeatNum && ibeatNum<12 && switch[13]) begin
                toneR = `e;
            end else if(12<=ibeatNum && ibeatNum<16 && switch[12]) begin
                toneR = `f;
            end else if(16<=ibeatNum && ibeatNum<20 && switch[11]) begin
                toneR = `g;
            end else if(20<=ibeatNum && ibeatNum<24 && switch[10]) begin
                toneR = `a;
            end else if(24<=ibeatNum && ibeatNum<28 && switch[9]) begin
                toneR = `b;
            end else if(28<=ibeatNum && ibeatNum<32 && switch[8]) begin
                toneR = `hc;
            end else if(32<=ibeatNum && ibeatNum<36 && switch[7]) begin
                toneR = `hd;
            end else if(36<=ibeatNum && ibeatNum<40 && switch[6]) begin
                toneR = `he;
            end else if(40<=ibeatNum && ibeatNum<44 && switch[5]) begin
                toneR = `hf;
            end else if(44<=ibeatNum && ibeatNum<48 && switch[4]) begin
                toneR = `hg;
            end else if(48<=ibeatNum && ibeatNum<52 && switch[3]) begin
                toneR = `ha;
            end else if(52<=ibeatNum && ibeatNum<56 && switch[2]) begin
                toneR = `hb;
            end else if(56<=ibeatNum && ibeatNum<60 && switch[1]) begin
                toneR = `ha;
            end else if(60<=ibeatNum && ibeatNum<64 && switch[0]) begin
                toneR = `hg;
            end else begin
                toneR = `sil;
            end
        end
    end

    always @(*) begin
        toneL = `sil;
        if(en == 1)begin    //demonstrate mode
            if(0<=ibeatNum && ibeatNum<4 && switch[15]) begin
                toneL = `c;
            end else if(4<=ibeatNum && ibeatNum<8 && switch[14]) begin
                toneL = `d;
            end else if(8<=ibeatNum && ibeatNum<12 && switch[13]) begin
                toneL = `e;
            end else if(12<=ibeatNum && ibeatNum<16 && switch[12]) begin
                toneL = `f;
            end else if(16<=ibeatNum && ibeatNum<20 && switch[11]) begin
                toneL = `g;
            end else if(20<=ibeatNum && ibeatNum<24 && switch[10]) begin
                toneL = `a;
            end else if(24<=ibeatNum && ibeatNum<28 && switch[9]) begin
                toneL = `b;
            end else if(28<=ibeatNum && ibeatNum<32 && switch[8]) begin
                toneL = `hc;
            end else if(32<=ibeatNum && ibeatNum<36 && switch[7]) begin
                toneL = `hd;
            end else if(36<=ibeatNum && ibeatNum<40 && switch[6]) begin
                toneL = `he;
            end else if(40<=ibeatNum && ibeatNum<44 && switch[5]) begin
                toneL = `hf;
            end else if(44<=ibeatNum && ibeatNum<48 && switch[4]) begin
                toneL = `hg;
            end else if(48<=ibeatNum && ibeatNum<52 && switch[3]) begin
                toneL = `ha;
            end else if(52<=ibeatNum && ibeatNum<56 && switch[2]) begin
                toneL = `hb;
            end else if(56<=ibeatNum && ibeatNum<60 && switch[1]) begin
                toneL = `ha;
            end else if(60<=ibeatNum && ibeatNum<64 && switch[0]) begin
                toneL = `hg;
            end else begin
                toneL = `sil;
            end
        end
    end
endmodule