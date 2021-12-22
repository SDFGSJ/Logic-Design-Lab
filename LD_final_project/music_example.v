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
	output reg [31:0] toneL,
    output reg [31:0] toneR
);
    always @* begin
        toneR = `sil;
        if(en == 1) begin   //demonstrate mode
            case(ibeatNum)
                12'd0: toneR = `c;   12'd1: toneR = `c;
                12'd2: toneR = `c;   12'd3: toneR = `c;

                12'd4: toneR = `d;   12'd5: toneR = `d;
                12'd6: toneR = `d;   12'd7: toneR = `d;

                12'd8: toneR = `e;   12'd9: toneR = `e;
                12'd10: toneR = `e;   12'd11: toneR = `e;

                12'd12: toneR = `f;   12'd13: toneR = `f;
                12'd14: toneR = `f;   12'd15: toneR = `f;

                12'd16: toneR = `g;   12'd17: toneR = `g;
                12'd18: toneR = `g;   12'd19: toneR = `g;

                12'd20: toneR = `a;   12'd21: toneR = `a;
                12'd22: toneR = `a;   12'd23: toneR = `a;

                12'd24: toneR = `b;   12'd25: toneR = `b;
                12'd26: toneR = `b;   12'd27: toneR = `b;

                12'd28: toneR = `hc;   12'd29: toneR = `hc;
                12'd30: toneR = `hc;   12'd31: toneR = `hc;

                12'd32: toneR = `hd;   12'd33: toneR = `hd;
                12'd34: toneR = `hd;   12'd35: toneR = `hd;

                12'd36: toneR = `he;   12'd37: toneR = `he;
                12'd38: toneR = `he;   12'd39: toneR = `he;

                12'd40: toneR = `hf;   12'd41: toneR = `hf;
                12'd42: toneR = `hf;   12'd43: toneR = `hf;

                12'd44: toneR = `hg;   12'd45: toneR = `hg;
                12'd46: toneR = `hg;   12'd47: toneR = `hg;

                12'd48: toneR = `ha;   12'd49: toneR = `ha;
                12'd50: toneR = `ha;   12'd51: toneR = `ha;

                12'd52: toneR = `hb;   12'd53: toneR = `hb;
                12'd54: toneR = `hb;   12'd55: toneR = `hb;

                12'd56: toneR = `sil;   12'd57: toneR = `sil;
                12'd58: toneR = `sil;   12'd59: toneR = `sil;

                12'd60: toneR = `sil;   12'd61: toneR = `sil;
                12'd62: toneR = `sil;   12'd63: toneR = `sil;
                default: toneR = `sil;
            endcase
        end
    end

    always @(*) begin
        toneL = `sil;
        if(en == 1)begin    //demonstrate mode
            case(ibeatNum)
                12'd0: toneL = `c;   12'd1: toneL = `c;
                12'd2: toneL = `c;   12'd3: toneL = `c;

                12'd4: toneL = `d;   12'd5: toneL = `d;
                12'd6: toneL = `d;   12'd7: toneL = `d;

                12'd8: toneL = `e;   12'd9: toneL = `e;
                12'd10: toneL = `e;   12'd11: toneL = `e;

                12'd12: toneL = `f;   12'd13: toneL = `f;
                12'd14: toneL = `f;   12'd15: toneL = `f;

                12'd16: toneL = `g;   12'd17: toneL = `g;
                12'd18: toneL = `g;   12'd19: toneL = `g;

                12'd20: toneL = `a;   12'd21: toneL = `a;
                12'd22: toneL = `a;   12'd23: toneL = `a;

                12'd24: toneL = `b;   12'd25: toneL = `b;
                12'd26: toneL = `b;   12'd27: toneL = `b;

                12'd28: toneL = `hc;   12'd29: toneL = `hc;
                12'd30: toneL = `hc;   12'd31: toneL = `hc;

                12'd32: toneL = `hd;   12'd33: toneL = `hd;
                12'd34: toneL = `hd;   12'd35: toneL = `hd;

                12'd36: toneL = `he;   12'd37: toneL = `he;
                12'd38: toneL = `he;   12'd39: toneL = `he;

                12'd40: toneL = `hf;   12'd41: toneL = `hf;
                12'd42: toneL = `hf;   12'd43: toneL = `hf;

                12'd44: toneL = `hg;   12'd45: toneL = `hg;
                12'd46: toneL = `hg;   12'd47: toneL = `hg;

                12'd48: toneL = `ha;   12'd49: toneL = `ha;
                12'd50: toneL = `ha;   12'd51: toneL = `ha;

                12'd52: toneL = `hb;   12'd53: toneL = `hb;
                12'd54: toneL = `hb;   12'd55: toneL = `hb;

                12'd56: toneL = `sil;   12'd57: toneL = `sil;
                12'd58: toneL = `sil;   12'd59: toneL = `sil;

                12'd60: toneL = `sil;   12'd61: toneL = `sil;
                12'd62: toneL = `sil;   12'd63: toneL = `sil;
                default : toneL = `sil;
            endcase
        end
    end
endmodule