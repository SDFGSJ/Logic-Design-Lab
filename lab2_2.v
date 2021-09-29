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
    
    reg [2:0] lightA_next=0,lightB_next=0;
    reg [1:0] lightA_green_cycle=0,lightB_green_cycle=0;
    reg [1:0] lightA_green_cycle_next=0,lightB_green_cycle_next=0;
    

    /*initial begin
        $monitor($time,": clk=%d, rst=%d, carA=%d, carB=%d, lightA=%d, lightB=%d, lightA_green_cycle=%d, lightB_green_cycle=%d",clk,rst,carA,carB,lightA,lightB,lightA_green_cycle,lightB_green_cycle);
    end*/


    always @(posedge clk,posedge rst) begin
        if(rst) begin
            lightA<=GREEN;
            lightB<=RED;
            lightA_next<=GREEN;
            lightB_next<=RED;

            lightA_green_cycle<=0;
            lightB_green_cycle<=0;
            lightA_green_cycle_next<=0;
            lightB_green_cycle_next<=0;
        end else begin
            lightA<=lightA_next;
            lightB<=lightB_next;
            lightA_green_cycle<=lightA_green_cycle_next;
            lightB_green_cycle<=lightB_green_cycle_next;
        end
    end


    always @(*) begin
        if({carA,carB}==2'b01) begin
            if({lightA,lightB}=={GREEN,RED}) begin
                if(lightA_green_cycle[1]) begin //green has stayed at least 2 cycles
                    lightA_next=YELLOW;
                    lightB_next=RED;
                end else begin
                    lightA_green_cycle_next = lightA_green_cycle + 1;
                end
            end else if({lightA,lightB}=={YELLOW,RED}) begin
                lightA_next=RED;
                lightB_next=GREEN;
                lightA_green_cycle_next=0;
                //maybe reset lightA_green_cycle here
            end else if({lightA,lightB}=={RED,GREEN}) begin
                lightA_next=RED;
                lightB_next=GREEN;
                //maybe reset lightA_green_cycle here
            end
        end else if({carA,carB}==2'b10) begin
            if({lightA,lightB}=={RED,GREEN}) begin
                if(lightB_green_cycle[1]) begin //green has stayed at least 2 cycles
                    lightA_next=RED;
                    lightB_next=YELLOW;
                end else begin
                    lightB_green_cycle_next = lightB_green_cycle + 1;
                end
            end else if({lightA,lightB}=={RED,YELLOW}) begin
                lightA_next=GREEN;
                lightB_next=RED;
                lightB_green_cycle_next=0;
                //maybe reset lightA_green_cycle here
            end else if({lightA,lightB}=={GREEN,RED}) begin
                lightA_next=GREEN;
                lightB_next=RED;
                //maybe reset lightA_green_cycle here
            end
        end else begin
            lightA_next=lightA;
            lightB_next=lightB;
            //lightA_green_cycle_next=lightA_green_cycle;
            //lightB_green_cycle_next=lightB_green_cycle;
        end
    end
endmodule