`timescale 1 ns/1 ns
module mycostas_test;

reg clock;//时钟信号
reg resest;//复位信号

mycostas U(//模块的调�?
.clock(clock),
.resest(resest)
);

initial begin//时钟的产�?
 clock=1;
  forever
  #5
  clock=~clock;
end

initial begin//复位信号产生
 resest=0;
 #17
 resest=1;
end

endmodule    
 


