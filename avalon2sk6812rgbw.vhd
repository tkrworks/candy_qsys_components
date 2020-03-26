library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AVALON2SK6812RGBW is
	generic(
		LED_BIT_WIDTH : integer range 1 to 32 := 32;
		T0H     : integer range 0 to 210  := 30;
		T1H     : integer range 0 to 210  := 60;
		T0L     : integer range 0 to 210  := 90;
		T1L     : integer range 0 to 210  := 60;
		TRST    : integer range 0 to 210  := 80 
	);
	port(
		-- clock & reset
		csi_clk:     in std_logic;
		csi_reset_n: in std_logic;
		
		-- Avalon-MM
		avs_s1_address:       in  std_logic_vector(3 downto 0);-- := (others => '0');
--		avs_s1_chipselect:    in  std_logic;
--		avs_s1_byteenable:    in  std_logic_vector(3 downto 0);
		avs_s1_read:          in  std_logic;-- := '0';
		avs_s1_write:         in  std_logic;-- := '0';
		avs_s1_readdata:      out std_logic_vector(31 downto 0);
		avs_s1_writedata:     in  std_logic_vector(31 downto 0);-- := (others => '0');
--		avs_s1_waitrequest:   out std_logic;
--		avs_s1_readdatavalid: out std_logic;
		
		DOUT1: out std_logic;
		DOUT2: out std_logic
	);
end AVALON2SK6812RGBW;

architecture structural of AVALON2SK6812RGBW is
	signal index     : integer range 0 to LED_BIT_WIDTH := LED_BIT_WIDTH;
	signal pwm_count : integer range 0 to 210 := 0;
	signal pwm_th    : integer range 0 to 210 := 0;
	signal pwm_t     : integer range 0 to 210 := 0;
	
	signal rdata : std_logic_vector(7 downto 0);
	signal gdata : std_logic_vector(7 downto 0);
	signal bdata : std_logic_vector(7 downto 0);
	signal wdata : std_logic_vector(7 downto 0);
	
	signal index2     : integer range 0 to LED_BIT_WIDTH := LED_BIT_WIDTH;
	signal pwm_count2 : integer range 0 to 210 := 0;
	signal pwm_th2    : integer range 0 to 210 := 0;
	signal pwm_t2     : integer range 0 to 210 := 0;
	
	signal rdata2 : std_logic_vector(7 downto 0);
	signal gdata2 : std_logic_vector(7 downto 0);
	signal bdata2 : std_logic_vector(7 downto 0);
	signal wdata2 : std_logic_vector(7 downto 0);
	
	
	begin
		process(csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					avs_s1_readdata <= X"00000000";
				elsif (csi_clk'event and csi_clk = '1') then
					if avs_s1_read = '1' then
							if index < LED_BIT_WIDTH or index2 < LED_BIT_WIDTH then
								avs_s1_readdata <= X"00000000";
							else
								avs_s1_readdata <= X"00000001";
							end if;
					end if;
				end if;
		end process;
				
		process(csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					pwm_count <= 0;
					index <= 0;
					rdata <= X"00";
					gdata <= X"00";
					bdata <= X"00";
					wdata <= X"00";
					
					pwm_count2 <= 0;
					index2 <= 0;
					rdata2 <= X"00";
					gdata2 <= X"00";
					bdata2 <= X"00";
					wdata2 <= X"00";
				elsif (csi_clk'event and csi_clk = '1') then
					if avs_s1_write = '1' then
						if avs_s1_address = "0000" then
							pwm_count <= 0;
							index <= 0;
						elsif avs_s1_address = "0001" then
							rdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "0010" then
							gdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "0011" then
							bdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "0100" then
							wdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "1000" then
							pwm_count2 <= 0;
							index2 <= 0;
						elsif avs_s1_address = "1001" then
							rdata2 <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "1010" then
							gdata2 <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "1011" then
							bdata2 <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "1100" then
							wdata2 <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "1111" then
							pwm_count <= 0;
							index <= 0;
							pwm_count2 <= 0;
							index2 <= 0;
						end if;
					else	
						if (pwm_t > 0 and pwm_count = pwm_t) then
							pwm_count <= 0;
						
							if index < LED_BIT_WIDTH then
								index <= index + 1;
							end if;
						else
							pwm_count <= pwm_count + 1;
						end if;
						
						if (pwm_t2 > 0 and pwm_count2 = pwm_t2) then
							pwm_count2 <= 0;
						
							if index2 < LED_BIT_WIDTH then
								index2 <= index2 + 1;
							end if;
						else
							pwm_count2 <= pwm_count2 + 1;
						end if;
					end if;
				end if;
		end process;
		
		process (csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					pwm_th <= 0;
					pwm_t <= 0;
				elsif (csi_clk'event and csi_clk = '1') then
					if (index >= 0 and index < 8) then
						if gdata(7 - index) = '1' then
							pwm_th <= T1H;
							pwm_t <= T1H + T1L;
						else
							pwm_th <= T0H;
							pwm_t <= T0H + T0L;
						end if;
					elsif (index >= 8 and index < 16) then
						if rdata(7 - (index - 8)) = '1' then
							pwm_th <= T1H;
							pwm_t <= T1H + T1L;
						else
							pwm_th <= T0H;
							pwm_t <= T0H + T0L;
						end if;
					elsif (index >= 16 and index < 24) then
						if bdata(7 - (index - 16)) = '1' then
							pwm_th <= T1H;
							pwm_t <= T1H + T1L;
						else
							pwm_th <= T0H;
							pwm_t <= T0H + T0L;
						end if;
					elsif (index >= 24 and index < 32) then
						if wdata(7 - (index - 24)) = '1' then
							pwm_th <= T1H;
							pwm_t <= T1H + T1L;
						else
							pwm_th <= T0H;
							pwm_t <= T0H + T0L;
						end if;
					elsif index = LED_BIT_WIDTH then
						pwm_th <= 0;
						pwm_t <= 0;
					end if;
				end if;
		end process;
		
		process (csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					pwm_th2 <= 0;
					pwm_t2 <= 0;
				elsif (csi_clk'event and csi_clk = '1') then
					if (index2 >= 0 and index2 < 8) then
						if gdata2(7 - index2) = '1' then
							pwm_th2 <= T1H;
							pwm_t2 <= T1H + T1L;
						else
							pwm_th2 <= T0H;
							pwm_t2 <= T0H + T0L;
						end if;
					elsif (index2 >= 8 and index2 < 16) then
						if rdata2(7 - (index2 - 8)) = '1' then
							pwm_th2 <= T1H;
							pwm_t2 <= T1H + T1L;
						else
							pwm_th2 <= T0H;
							pwm_t2 <= T0H + T0L;
						end if;
					elsif (index2 >= 16 and index2 < 24) then
						if bdata2(7 - (index2 - 16)) = '1' then
							pwm_th2 <= T1H;
							pwm_t2 <= T1H + T1L;
						else
							pwm_th2 <= T0H;
							pwm_t2 <= T0H + T0L;
						end if;
					elsif (index2 >= 24 and index2 < 32) then
						if wdata2(7 - (index2 - 24)) = '1' then
							pwm_th2 <= T1H;
							pwm_t2 <= T1H + T1L;
						else
							pwm_th2 <= T0H;
							pwm_t2 <= T0H + T0L;
						end if;
					elsif index2 = LED_BIT_WIDTH then
						pwm_th2 <= 0;
						pwm_t2 <= 0;
					end if;
				end if;
		end process;
		
		process (csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					DOUT1 <= '0';
					DOUT2 <= '0';
				elsif (csi_clk'event and csi_clk = '1') then
					if (index < LED_BIT_WIDTH and pwm_count < pwm_th) then
						DOUT1 <= '1';
					else
						DOUT1 <= '0';
					end if;

					if (index2 < LED_BIT_WIDTH and pwm_count2 < pwm_th2) then
						DOUT2 <= '1';
					else 
						DOUT2 <= '0';
					end if;
				end if;
		end process;
end architecture structural;