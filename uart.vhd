
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------
entity uart is--定义uart实体
    port
	 (
	   clkin,resetin:in std_logic;--clkin为50M
		rxd:in std_logic;--串行输入数据
		led:out std_logic_vector(5 downto 0);--led指示
		txd:out std_logic;--串行输出数据
		DATA_F:OUT std_logic;
		clk_out:OUT std_logic;
		DATA_OUT:OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	 );
end uart;
---------------------------------------
architecture behave of uart is
---------------------------------------
    component gen_div is--分频元件调用声明
	 generic(div_param:integer:=163); --326分频，326 * 16 * （9600）= 50M   --波特率为9600. 
	 port
	 (
	   clk:in std_logic;
		bclk:out std_logic;
		resetb:in std_logic
	 );
	 end component;
	 ---------------------------------------------------
	 component uart_t is--串口发送元件调用声明
	 port
	 (
	   bclkt,resett,xmit_cmd_p:in std_logic;
		txdbuf:in std_logic_vector(7 downto 0);
		txd:out std_logic;
		txd_done:out std_logic
	 );
	 end component;
	 ----------------------------------------------------
	 component uart_r is--串口接受元件调用声明
	 port
	 (
	   bclkr,resetr,rxdr:in std_logic;
		r_ready:out std_logic;
		rbuf:out std_logic_vector(7 downto 0)
	 );
	 end component;
	 -----------------------------------------------------
	 component narr_sig is--信号窄化元件声明调用
	 port
	 (
	   sig_in:in std_logic;
		clk:in std_logic;
		resetb:in std_logic;
		narr_prd:in std_logic_vector(7 downto 0);
		narr_sig_out:out std_logic
	 );
	 end component;
	 -------------------------------------------------
	 signal clk_b:std_logic;--波特率时钟
	 signal clk1:std_logic;--数码管时钟
	 ---------------------------------------------------
	 signal xmit_p:std_logic;--新一轮发送启动信号
	 signal xbuf:std_logic_vector(7 downto 0);--待发送数据缓冲区
	 signal txd_done_iner:std_logic;--帧数据发送完标志
	 -----------------------------------------------------
	 signal rev_buf:std_logic_vector(7 downto 0);--接收数据缓冲区
	 signal rev_ready:std_logic;--帧数据接受完标志
	 -------------------------------------------------
	 signal led_tmp:std_logic_vector(5 downto 0);--led控制
	 -------------------------------------------------
	 signal flag:std_logic:='0';--结束标志
	 ------------------------------
	 begin 
	 --------分频模块例化--------------
	      uart_baud:gen_div
			generic map(163) --326分频，326 * 16 * （9600）= 50M   --波特率为9600. 
			port map
			(
			  clk=>clkin,
			  resetb=>not resetin,
			  bclk=>clk_b
			);
	 --------分频模块例化--------------
	      seg_clk:gen_div
			generic map(10) --20分频
			port map
			(
			  clk=>clkin,
			  resetb=>not resetin,
			  bclk=>clk1
			);
			-------串口发送模块例化------------
			uart_transfer:uart_t
			port map
			(
			  bclkt=>clk_b,
			  resett=>not resetin,
			  xmit_cmd_p=>xmit_p,
			  txdbuf=>xbuf,
			  txd=>txd,
			  txd_done=>txd_done_iner
			);
			-------串口接收元件例化-------------
			uart_receive:uart_r
			port map
			(
				bclkr=>clk_b,
				resetr=>not resetin,
				rxdr=>rxd,
				r_ready=>rev_ready,
				rbuf=>rev_buf
			);
			--------信号窄化模块例化-------------
			narr_rev_ready:narr_sig--窄化rev_ready信号后给xmit_p
			port map
			(
				sig_in=>rev_ready,--输入需窄化信号
				clk=>clk_b,
				resetb=>not resetin,
				narr_prd=>X"03",--narr信号高电平持续的周期数(以clk为周期)
				narr_sig_out=>xmit_p--输出窄化后信号
			);
			------------------------------------
			led<=led_tmp;
			-----------------------------
			process(rev_ready,resetin,rev_buf,led_tmp,clk_b)
			begin
				   if rising_edge(rev_ready) then--接收完毕
					 xbuf<=rev_buf;--装载数据		 
					end if;
			end process;
			---------------------------------------
		display:process(clk1,rev_ready,rev_buf,clkin)
			variable cnt:integer range 0 to 2:=0;
			begin
				if rising_edge(clkin)then
					if (rev_ready='0') then--接收完毕
							DATA_OUT<=rev_buf;
							cnt:=1;
					end if;
					if(cnt=1)then
						flag<='1';
						cnt:=cnt+1;
					elsif(cnt=2)then
						flag<='0';
						cnt:=cnt+1;
					end if;
				 end if;
				
			end process;
			---------------------------------------
DATA_F<=flag;
clk_out<=clk_b;

end behave;
-------------------------------	 
	 
	 