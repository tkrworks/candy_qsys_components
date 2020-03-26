library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AVALON2NEOPIXEL is
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
		avs_s1_address:       in  std_logic_vector(2 downto 0);-- := (others => '0');
--		avs_s1_chipselect:    in  std_logic;
--		avs_s1_byteenable:    in  std_logic_vector(3 downto 0);
		avs_s1_read:          in  std_logic;-- := '0';
		avs_s1_write:         in  std_logic;-- := '0';
		avs_s1_readdata:      out std_logic_vector(31 downto 0);
		avs_s1_writedata:     in  std_logic_vector(31 downto 0);-- := (others => '0');
--		avs_s1_waitrequest:   out std_logic;
--		avs_s1_readdatavalid: out std_logic;
--		
		DOUT: out std_logic
	);
end AVALON2NEOPIXEL;

architecture structural of AVALON2NEOPIXEL is
	signal index     : integer range 0 to LED_BIT_WIDTH := LED_BIT_WIDTH;
	signal pwm_count : integer range 0 to 210 := 0;
	signal pwm_th    : integer range 0 to 210 := 0;
	signal pwm_t     : integer range 0 to 210 := 0;
	
	signal rdata : std_logic_vector(7 downto 0);
	signal gdata : std_logic_vector(7 downto 0);
	signal bdata : std_logic_vector(7 downto 0);
	signal wdata : std_logic_vector(7 downto 0);
	
	
	begin
		process(csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					avs_s1_readdata <= X"00000000";
				elsif (csi_clk'event and csi_clk = '1') then
					if avs_s1_read = '1' then
							if index < LED_BIT_WIDTH then
								avs_s1_readdata <= X"00000000";
							else
								avs_s1_readdata <= X"00000001";
							end if;
					end if;
				end if;
		end process;
		
--		process(csi_clk, csi_reset_n)
--			begin
--				if (csi_reset_n = '0') then
--					flag <= '0';
--					rdata <= X"00";
--					gdata <= X"00";
--					bdata <= X"00";
--				elsif (csi_clk'event and csi_clk = '1') then
--					if avs_s1_write = '1' then
--						if avs_s1_address = "00" then
--							flag <= '1';
--						elsif avs_s1_address = "01" then
--							rdata <= avs_s1_writedata(7 downto 0);
--						elsif avs_s1_address = "10" then
--							gdata <= avs_s1_writedata(7 downto 0);
--						elsif avs_s1_address = "11" then
--							bdata <= avs_s1_writedata(7 downto 0);
--						end if;
--					end if;
--				end if;
--		end process;
		
		process(csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					pwm_count <= 0;
					index <= 0;
					rdata <= X"00";
					gdata <= X"00";
					bdata <= X"00";
					wdata <= X"00";
				elsif (csi_clk'event and csi_clk = '1') then
					if avs_s1_write = '1' then
						if avs_s1_address = "000" then
							pwm_count <= 0;
							index <= 0;
						elsif avs_s1_address = "001" then
							rdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "010" then
							gdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "011" then
							bdata <= avs_s1_writedata(7 downto 0);
						elsif avs_s1_address = "100" then
							wdata <= avs_s1_writedata(7 downto 0);
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
		
		DOUT <= '1' when (index < LED_BIT_WIDTH and pwm_count < pwm_th) else '0';
end architecture structural;