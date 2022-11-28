module mycostas(
    clock,
    resest,
    signal_in,
    signal_out,
	 fsclock,
	 fsclock2,
	 fs2clock,
	 fs2clock2,
	 sin_oo,
	 sin_oo2,
	 sin_o
);
input clock;
input resest;
input  signed [13:0] signal_in;
output signed [13:0] signal_out;
output fsclock;//采样时钟
output fsclock2;
output fs2clock;//采样时钟
output fs2clock2;
output signed [13:0] sin_o;
output signed [13:0] sin_oo;
reg signed [13:0] sin_oo;
output signed [13:0] sin_oo2;
reg signed [13:0] sin_oo2;
wire signed [13:0] sin_oI;
wire signed [13:0] sin_oQ;

//f1=1M
mypll Umypll
(
.refclk(clock),   //  refclk.clk
.outclk_0(fsclock) // outclk0.clk
);
mypll2 Umypll2
(
.refclk(clock),   //  refclk.clk
.outclk_0(fsclock2) // outclk0.clk
);
assign fs2clock=fsclock;
assign fs2clock2=fsclock2;
cordiczijiI U1
(
    .clock(fsclock),
    .resest(resest),
   .freq_ctl_word(16'd1152),//120/(360/3)=1M
    .sin_o(sin_o)
);
reg [23:0] cnt1;//时钟1产生伪随机序列
reg pn;
always @(posedge fsclock or negedge resest) 
begin
    if(!resest)
       cnt1<=24'b0;
    else 
	 begin 
       if(cnt1<24'd1500)
          cnt1<=cnt1+1'b1;
       else
          cnt1<=24'd0;
	 end
end
always @(posedge fsclock or negedge resest) begin
if(!resest) begin
pn<=0;end
else begin
if(cnt1==24'd1500) begin
pn<=~pn;end
else begin
pn<=pn;end
end
end
wire signed [13:0] code;
cordiczijiI UIcode
(
    .clock(fsclock),
    .resest(resest),
    .freq_ctl_word(16'd38),//120/(360/3)=1M
    .sin_o(code)
);
//always @(posedge fsclock or negedge resest) begin
//if(!resest) begin
//pn<=0;end
//else begin
//if(pn==0) begin
//code<=2'b01;end
//else begin
//code<=2'b11;end
//end
//end
wire signed [26:0] ss;
wire signed [13:0] sin_end;
assign ss=code*sin_o;
assign sin_end=ss[24:11];

//reg signed [13:0] sin_end50;
//always @(posedge clock or negedge resest) begin
//if(!resest) begin
//sin_end50<=0;end
//else begin
//sin_end50<=sin_end;
//end
//end



//384为1M

//仿真接收到的信号
//wire signed [13:0] sin_in;
//cordiczijiI UI2
//(
//    .clock(fsclock),
//    .resest(resest),
//    .freq_ctl_word(16'd375),//120/(360/3)=1M
//    .sin_o(sin_in)
//);
//I路为sin
//Q路为cos
//costas锁相环的参数设置
//当前相位步进
//reg  [16:0] LO;
//频率调整字
reg signed [9:0] VPDS;//相位调整
reg  signed [16:0] Theta_Errors;
always @(posedge clock or negedge resest) begin
if(!resest) begin
Theta_Errors<=16'd1152;end
else begin
Theta_Errors<=$signed(16'd1152)+VPDS;end
end
reg [15:0] Theta_Error;
always @(posedge clock or negedge resest) begin
if(!resest) begin
Theta_Error<=15'd1152;end
else begin
Theta_Error<=Theta_Errors[15:0];end
end
//I路乘法器输出
reg [30:0] VLOI;
reg [13:0] VLO_I;
//第一个乘法器
//I路
cordiczijiI UI
(
    .clock(fsclock),
    .resest(resest),
    .freq_ctl_word(Theta_Error),//120/(360/3)=1M
    .sin_o(sin_oI)
);
always @(posedge clock or negedge resest) begin
if(!resest) begin
VLOI<=30'b0;end
else begin
VLOI<=sin_oI*sin_end;
end
end
always @(posedge clock or negedge resest) begin
if(!resest) begin
VLO_I<=14'b0;end
else begin
VLO_I<=VLOI[25:12];
end
end



//Q路乘法器
reg [30:0] VLOQ;
reg [13:0] VLO_Q;
//第一个乘法器
//Q路
cordiczijiQ UQ
(
    .clock(fsclock),
    .resest(resest),
    .freq_ctl_word(Theta_Error),//120/(360/3)=1M
    .sin_o(sin_oQ)
);
always @(posedge clock or negedge resest) begin
if(!resest) begin
VLOQ<=30'b0;end
else begin
VLOQ<=sin_oQ*sin_end;
end
end
always @(posedge clock or negedge resest) begin
if(!resest) begin
VLO_Q<=14'b0;end
else begin
VLO_Q<=VLOQ[25:12];
end
end

//低通滤波器阶段
wire signed  [27:0] VI;
reg signed  [13:0] VII;
fir1 IFIRT(
.clk(clock),              //                     clk.clk
.ast_sink_data(VLO_I),
.reset_n(1'b1),
.ast_sink_valid(1'b1),
//.ast_sink_error(2'b00),    //   avalon_streaming_sink.data
.ast_source_data(VI)  // avalon_streaming_source.
);

always @(posedge clock or negedge resest) begin
if(!resest) begin
VII<=VI;end
else begin
VII<=VI[24:11];
end
end


wire signed  [27:0] VQ;
reg signed  [13:0] VQQ;
fir1 QFIRT(
.clk(clock),              //                     clk.clk
.ast_sink_data(VLO_Q),
.reset_n(1'b1),
.ast_sink_valid(1'b1),
//.ast_sink_error(2'b00),    //   avalon_streaming_sink.data
.ast_source_data(VQ)  // avalon_streaming_source.
);

always @(posedge clock or negedge resest) begin
if(!resest) begin
VQQ<=VQ;end
else begin
VQQ<=VQ[24:11];
end
end

//压控振荡器输入
reg signed [17:0] VPD;
reg signed [1:0] fuhao;
always @(posedge clock or negedge resest) begin
if(!resest) begin
fuhao<=2'b0;end
else begin
if(VQQ[13]==1'b0) begin
fuhao<=2'b01; end
else begin
fuhao<=2'b11; end
end
end
always @(posedge clock or negedge resest) begin
if(!resest) begin
VPD<=2'b0;end
else begin
VPD<=fuhao*VII;
end
end
//位数截取

always @(posedge clock or negedge resest) begin
if(!resest) begin
VPDS<=10'b0;end
else begin
VPDS<=VPD[16:7];end
end

//调整相位



//f2=1.0005M
//reg [15:0] LO={9'd3,7'd5};//本振
//频率为120/
reg [15:0] freq_ct2_word;
always @(posedge fsclock or negedge resest) begin
if(!resest) begin
sin_oo<=14'b0;end
else begin
sin_oo<={~sin_o[13],sin_o[12:0]};
end
end
always @(posedge fsclock or negedge resest) begin
if(!resest) begin
sin_oo2<=14'b0;end
else begin
sin_oo2<={~sin_oI[13],sin_oI[12:0]};
end
end
endmodule