library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AVALON2PWM is
	generic(
		WIDTH :           integer range 1 to 8     := 3;
		PWM_COUNTER_MAX : integer range 0 to 65535 := 60000
	);
	port(
		-- clock & reset
		csi_clk:     in std_logic;
		csi_reset_n: in std_logic;
		
		-- Avalon-MM
--		avs_s1_address:       in  std_logic_vector(3 downto 0);-- := (others => '0');
--		avs_s1_chipselect:    in  std_logic;
----		avs_s1_byteenable:    in  std_logic_vector(3 downto 0);
----		avs_s1_read:          in  std_logic;-- := '0';
		avs_s1_write:         in  std_logic;-- := '0';
		avs_s1_writedata:     in  std_logic_vector(31 downto 0);-- := (others => '0');
----		avs_s1_waitrequest:   out std_logic;
--		avs_s1_readdata:      out std_logic_vector(31 downto 0);
--		avs_s1_readdatavalid: out std_logic;
--		
		PWM_OUT: out std_logic_vector(WIDTH downto 0)
	);
end AVALON2PWM;

architecture structural of AVALON2PWM is
	signal pwm_counter: std_logic_vector(15 downto 0);
	signal pwm_duty:    std_logic_vector(31 downto 0);
--	
	begin
		process(csi_clk, csi_reset_n)
			begin
				if csi_reset_n = '0' then
					pwm_counter <= X"0000";
				elsif (csi_clk'event and csi_clk = '1') then
					if pwm_counter = PWM_COUNTER_MAX then
						pwm_counter <= X"0000";
					else
						pwm_counter <= pwm_counter + 1;
					end if;
				end if;
		end process;
	
		process(csi_clk, csi_reset_n)
			begin
				if (csi_reset_n = '0') then
					pwm_duty <= X"00000000";
				elsif (csi_clk'event and csi_clk = '1') then
					if avs_s1_write = '1' then
						pwm_duty <= avs_s1_writedata;
					end if;
				end if;
		end process;
	
--		process(csi_clk, csi_reset_n)
--			begin
--				if (csi_reset_n = '0') then
--					avs_s1_readdata <= X"00000000";
--				elsif (csi_clk'event and csi_clk = '1') then
--					avs_s1_readdata <= pwm_duty;
----					avs_s1_readdatavalid <= ACK_I;
--				end if;
--		end process;
		
		PWM_OUT(0) <= '1' when pwm_counter > pwm_duty(15 downto 0) else '0';
end architecture structural;