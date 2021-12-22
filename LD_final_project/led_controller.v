module led_controller(
    input clkdiv,
    input rst,
    input play_pause,
    output reg [15:0] led
);
    reg [15:0] led_next;

    always @(posedge clkdiv, posedge rst) begin
        if(rst) begin
            led <= 16'b1000_0000_0000_0000;
        end else begin
            led <= led_next;
        end
    end

    always @(*) begin
        led_next = led;
        if(play_pause) begin
            if(led == 16'b0000_0000_0000_0001) begin
                led_next = 16'b1000_0000_0000_0000;
            end else begin
                led_next = led>>1;
            end
        end
    end
endmodule