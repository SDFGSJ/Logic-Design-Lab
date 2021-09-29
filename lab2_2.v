`timescale 1ns/100ps
module lab2_2(
    input clk,
    input rst,
    input carA,
    input carB,
    output reg [2:0] lightA,
    output reg [2:0] lightB
);

    parameter [2:0] RED=3'b100, YELLOW=3'b010, GREEN=3'b001;
    reg [1:0] lightA_green_cycle=0,lightB_green_cycle=0;
    reg [2:0] lightA_next=0,lightB_next=0;

    initial begin
        $monitor($time,": clk=%d, rst=%d, carA=%d, carB=%d, lightA=%d, lightB=%d, lightA_green_cycle=%d, lightB_green_cycle=%d",clk,rst,carA,carB,lightA,lightB,lightA_green_cycle,lightB_green_cycle);
    end


    always @(posedge clk,posedge rst) begin
        if(rst) begin
            lightA<=GREEN;
            lightB<=RED;

            lightA_next<=GREEN;
            lightB_next<=RED;

            lightA_green_cycle<=0;
            lightB_green_cycle<=0;
        end else begin
            lightA<=lightA_next;
            lightB<=lightB_next;
        end
    end


    always @(*) begin
        if({carA,carB}==2'b01) begin
            if({lightA,lightB}=={GREEN,RED}) begin
                if(lightA_green_cycle[1]) begin //green has stayed at least 2 cycles
                    lightA=YELLOW;
                    lightB=RED;
                end else begin
                    /*lightA=YELLOW;
                    lightB=RED;*/
                    lightA_green_cycle = lightA_green_cycle + 1;
                end
            end else if({lightA,lightB}=={YELLOW,RED}) begin
                lightA=RED;
                lightB=GREEN;
                lightA_green_cycle=0;
                //maybe reset lightA_green_cycle here
            end else if({lightA,lightB}=={RED,GREEN}) begin
                lightA=RED;
                lightB=GREEN;
                //maybe reset lightA_green_cycle here
            end
        end else if({carA,carB}==2'b10) begin
            if({lightA,lightB}=={RED,GREEN}) begin
                if(lightB_green_cycle[1]) begin //green has stayed at least 2 cycles
                    lightA=RED;
                    lightB=YELLOW;
                end else begin
                    /*lightA=RED;
                    lightB=YELLOW;*/
                    lightB_green_cycle = lightB_green_cycle + 1;
                end
            end else if({lightA,lightB}=={RED,YELLOW}) begin
                lightA=GREEN;
                lightB=RED;
                lightB_green_cycle=0;
                //maybe reset lightA_green_cycle here
            end else if({lightA,lightB}=={GREEN,RED}) begin
                lightA=GREEN;
                lightB=RED;
                //maybe reset lightA_green_cycle here
            end
        end else begin
            lightA=GREEN;
            lightB=RED;
        end
    end
endmodule