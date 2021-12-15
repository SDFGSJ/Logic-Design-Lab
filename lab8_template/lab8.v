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
`define sil   32'd50000000
`define silence   32'd50000000

module lab8(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    _play,      // SW0: Play/Pause
    _mute,      // SW1: Mute
    _slow,      // SW2: Slow
    _music,     // SW3: Music
    _mode,      // SW15: Mode
    _volUP,     // BTNU: Vol up
    _volDOWN,   // BTND: Vol down
    _higherOCT, // BTNR: Oct higher
    _lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    _led,       // LED: [15:13] octave & [4:0] volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck,  // serial clock
    audio_sdin, // serial audio data input
    DISPLAY,    // 7-seg
    DIGIT       // 7-seg
);

    // I/O declaration
    input clk; 
    input rst; 
    input _play, _mute, _slow, _music, _mode; 
    input _volUP, _volDOWN, _higherOCT, _lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output reg [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output reg [6:0] DISPLAY; 
    output reg [3:0] DIGIT; 
    
    // Modify these
    /*assign _led = 16'b1110_0000_0001_1111;
    assign DIGIT = 4'b0000;
    assign DISPLAY = 7'b0111111;*/

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    reg [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // clkDiv22
    wire clkDiv22, clkDiv23, display_clk, myclk;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio
    clock_divider #(.n(23)) clock_23(.clk(clk), .clk_div(clkDiv23));    // for keyboard and audio
    clock_divider #(.n(13)) display(.clk(clk), .clk_div(display_clk));  //7-segment display

    reg [2:0] volume=3'd3, volume_next;
    reg [2:0] octave=3'd2, octave_next;
    reg [15:0] _led_next;
    wire _volUP_debounced, _volDOWN_debounced, _higherOCT_debounced, _lowerOCT_debounced;
    wire _volUP_1p, _volDOWN_1p, _higherOCT_1p, _lowerOCT_1p;
    debounce vol_up_de(    .clk(clk), .pb(_volUP),     .pb_debounced(_volUP_debounced));
    debounce vol_down_de(  .clk(clk), .pb(_volDOWN),   .pb_debounced(_volDOWN_debounced));
    debounce oct_up_de(    .clk(clk), .pb(_higherOCT), .pb_debounced(_higherOCT_debounced));
    debounce oct_down_de(  .clk(clk), .pb(_lowerOCT),  .pb_debounced(_lowerOCT_debounced));

    onepulse vol_up_op(     .clk(clk), .signal(_volUP_debounced),       .op(_volUP_1p));
    onepulse vol_down_op(   .clk(clk), .signal(_volDOWN_debounced),     .op(_volDOWN_1p));
    onepulse oct_up_op(     .clk(clk), .signal(_higherOCT_debounced),   .op(_higherOCT_1p));
    onepulse oct_down_op(   .clk(clk), .signal(_lowerOCT_debounced),    .op(_lowerOCT_1p));

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            volume<=3'd3;
            octave<=3'd2;
        end else begin
            volume<=volume_next;
            octave<=octave_next;
        end
    end

    //adjust volume,octave
    always @(*) begin
        volume_next=volume;
        octave_next=octave;
        if(_volUP_1p) begin
            if(volume==5) begin
                volume_next=5;
            end else begin
                volume_next=volume+1;
            end
        end

        if(_volDOWN_1p) begin
            if(volume==1) begin
                volume_next=1;
            end else begin
                volume_next=volume-1;
            end
        end

        if(_higherOCT_1p) begin
            if(octave==3) begin
                octave_next=3;
            end else begin
                octave_next=octave+1;
            end
        end

        if(_lowerOCT_1p) begin
            if(octave==1) begin
                octave_next=1;
            end else begin
                octave_next=octave-1;
            end
        end
    end

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            _led <= 16'b0100_0000_0000_0111;
        end else begin
            _led <= _led_next;
        end
    end

    //led
    always @(*) begin
        _led_next = _led;
        if(_mute) begin
            _led_next[4:0] = 5'b00000;
        end else begin
            if(volume==1) begin
                _led_next[4:0] = 5'b00001;
            end else if(volume==2) begin
                _led_next[4:0] = 5'b00011;
            end else if(volume==3) begin
                _led_next[4:0] = 5'b00111;
            end else if(volume==4) begin
                _led_next[4:0] = 5'b01111;
            end else if(volume==5) begin
                _led_next[4:0] = 5'b11111;
            end else begin
                _led_next[4:0] = 5'b00000;
            end

            if(octave==1) begin
                _led_next[15:13] = 3'b100;
            end else if(octave==2) begin
                _led_next[15:13] = 3'b010;
            end else if(octave==3) begin
                _led_next[15:13] = 3'b001;
            end else begin
                _led_next[15:13] = 3'b000;
            end
        end
    end

    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    assign myclk = (_slow)? clkDiv23 : clkDiv22;
    player_control #(.LEN(512)) playerCtrl_00 (
        .clk(myclk),
        .reset(rst),
        ._play(_play),
        ._slow(_slow),
        ._mode(_mode),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .clk(clk),
        .rst(rst),
        .ibeatNum(ibeatNum),
        .en(_mode),
        .toneL(freqL),
        .toneR(freqR),
        .PS2_CLK(PS2_CLK),
        .PS2_DATA(PS2_DATA)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    /*assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;*/
    always @(*) begin
        if(!_mode || (_mode && _play)) begin //user play mode || (demonstrate && play)
            freq_outL = 50000000 / (_mute ? `silence : freqL);
            if(octave==1) begin
                freq_outL = 50000000 / (_mute ? `silence : freqL/2);
            end else if(octave==2) begin
                freq_outL = 50000000 / (_mute ? `silence : freqL);
            end else if(octave==3) begin
                freq_outL = 50000000 / (_mute ? `silence : freqL*2);
            end
        end else begin
            freq_outL = 50000000 / `silence;
        end
    end

    always @(*) begin
        if(!_mode || (_mode && _play)) begin    //user play mode || (demonstrate && play)
            freq_outR = 50000000 / (_mute ? `silence : freqR);
            if(octave==1) begin
                freq_outR = 50000000 / (_mute ? `silence : freqR/2);
            end else if(octave==2) begin
                freq_outR = 50000000 / (_mute ? `silence : freqR);
            end else if(octave==3) begin
                freq_outR = 50000000 / (_mute ? `silence : freqR*2);
            end
        end else begin
            freq_outR = 50000000 / `silence;
        end
    end




    //7-segment control, freqR = main melody
    reg [3:0] num;
    always @(*) begin
        if(!_mode || (_mode && _play)) begin   //user play mode || (demonstrate && play)
            if(freqR == `a || freqR == `ha)
                num = 4'd5;
            else if(freqR == `b || freqR == `hb)
                num = 4'd6;
            else if(freqR == `c || freqR == `hc)
                num = 4'd0;
            else if(freqR == `d || freqR == `hd)
                num = 4'd1;
            else if(freqR == `e || freqR == `he)
                num = 4'd2;
            else if(freqR == `f || freqR == `hf)
                num = 4'd3;
            else if(freqR == `g || freqR == `hg)
                num = 4'd4;
            else if(`sil)
                num = 4'd7;
            else
                num = 4'd7;
        end else begin
            num = 4'd7;
        end
    end

    reg [3:0] value;
    always @(posedge display_clk) begin
        case(DIGIT)
            4'b1110: begin
                value=7;
                DIGIT=4'b1101;
            end
            4'b1101: begin
                value=7;
                DIGIT=4'b1011;
            end
            4'b1011: begin
                value=7;
                DIGIT=4'b0111;
            end
            4'b0111: begin
                value=num;
                DIGIT=4'b1110;
            end
            default: begin
                value=7;
                DIGIT=4'b1110;
            end
        endcase
    end
    always @(*) begin
        case(value) //0 means on,1 means off(GFEDCBA)
            4'd0: DISPLAY=7'b0100111;   //C
            4'd1: DISPLAY=7'b0100001;   //D
            4'd2: DISPLAY=7'b0000110;   //E
            4'd3: DISPLAY=7'b0001110;   //F
            4'd4: DISPLAY=7'b1000010;   //G
            4'd5: DISPLAY=7'b0100000;   //A
            4'd6: DISPLAY=7'b0000011;   //B
            4'd7: DISPLAY=7'b0111111;   //-
            default: DISPLAY=7'b1111111;
        endcase
    end

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );
endmodule