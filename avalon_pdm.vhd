library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity AVALON_PDM is
	generic(
		DATA_WIDTH: integer range 1 to 512 := 50
	);
	port (
		-- clock
		clk: in std_logic;
		
		-- reset
		reset_n: in std_logic;
		
		-- Avalon-MM Slave
		avs_s1_address:       in  std_logic_vector(1 downto 0);-- := (others => '0');
--		avs_s1_chipselect:    in  std_logic;
--		avs_s1_byteenable:    in  std_logic_vector(3 downto 0);
--		avs_s1_read:          in  std_logic;-- := '0';
		avs_s1_write:         in  std_logic;-- := '0';
		avs_s1_writedata:     in  std_logic_vector(31 downto 0);-- := (others => '0');
--		avs_s1_waitrequest:   out std_logic;
--		avs_s1_readdata:      out std_logic_vector(31 downto 0);
--		avs_s1_readdatavalid: out std_logic;
		
		-- Avalon-ST Source
--		av_st1_ready:   in  std_logic;
--		av_st1_valid:   out std_logic;
--		av_st1_data:    out std_logic_vector(31 downto 0);
----		av_st1_channel: out std_logic;
--		av_st1_error:   out std_logic;
		
		-- Avalon-MM Slave
		av_mm1_address:     out std_logic_vector(2 downto 0);
		av_mm1_write:       out std_logic;
		av_mm1_writedata:   out std_logic_vector(31 downto 0);
		av_mm1_waitrequest: in  std_logic;
		
		-- PDM
		PDM_CLK:  out std_logic;
		PDM_DATA: in  std_logic
	);
end AVALON_PDM;

architecture structural of AVALON_PDM is
	signal out_flag: std_logic := '0';
	signal sampling_count: integer range 0 to 50;
	signal data: std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

	begin
		PDM_CLK <= clk;

		process(clk, reset_n)
			variable counter: integer range -8388608 to 8388607 := 0;
			variable mv0: signed(31 downto 0);
			variable mic_value: signed(23 downto 0);
		begin
			if (reset_n = '0') then
				data <= (others => '0');
			elsif (falling_edge(clk)) then -- because SELECT pin to GND
				data <= data(DATA_WIDTH - 2 downto 0) & PDM_DATA;
				
				if (out_flag = '1') then
					counter := 0;
					for i in 0 to (DATA_WIDTH - 1) loop
						if (data(i) = '1') then
							counter := counter + 1023;
						else
							counter := counter - 1023;
						end if;
					end loop;

--					if (PDM_DATA = '1') then
--						counter := counter + 1;
--					else
--						counter := counter - 1;
--					end if;
					
--					if (counter > 8388607) then
--						counter := 8388607;
--					elsif (counter < -8388608) then
--						counter := -8388608;
--					end if;
					
					mv0 := to_signed(counter, 32);
					mic_value := resize(mv0, 24);
				
					if (sampling_count = 49) then
						av_mm1_address <= "000";
						av_mm1_write <= '1';
						av_mm1_writedata <= '0' & std_logic_vector(mic_value) & "0000000";
						sampling_count <= 0;
					else
						av_mm1_write <= '0';
						sampling_count <= sampling_count + 1;
					end if;
				end if;
			end if;
		end process;
		
		process(clk, reset_n)
			begin
				if (reset_n = '0') then
					out_flag <= '0';
				elsif (rising_edge(clk)) then
					if (avs_s1_write = '1' and avs_s1_address(1 downto 0) = "00") then
						out_flag <= avs_s1_writedata(0);
					end if;
				end if;
		end process;
end architecture structural;