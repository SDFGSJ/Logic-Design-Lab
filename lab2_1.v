`timescale 1ns/100ps

module lab2_1(
    input clk,
    input rst,
    output reg [5:0] out
);

    reg [5:0] an=0,an_next=0,previous=0,previous_next=0,n=0,n_next=0;
    reg countup=0;

    //flip-flop
    always @(posedge clk,posedge rst) begin
        if(rst==1) begin
            out <= 0;
            an <= 0;
            previous <= 0;
            n <= 0;
        end else begin
            out <= an_next;
            an <= an_next;
            previous <= previous_next;
            n <= n_next;
        end
    end

    //combinational logic
    always @(*) begin
        if(countup) begin    //countup
            if(n==0) begin
                an = 0;
            end else if(previous > n) begin
                an = previous - n;
            end else begin
                an = previous + n;
            end
        end else begin  //countdown
            an = previous - ( 1<<(n-1) );
            //previous = an;
        end
        an_next = an;
        previous_next = an;
        n_next = n + 1;
    end
    
    always @(*) begin
        if(an==0 /*|| an==63*/) begin
            countup = ~countup;
        end
    end

    initial begin
        $monitor($time,": an=%d, an_next=%d, previous=%d, previous_next=%d, n=%d, n_next=%d, countup=%d",an,an_next,previous,previous_next,n,n_next,countup);
    end
endmodule