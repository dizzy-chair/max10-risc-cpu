library ieee;
use ieee.std_logic_1164.all;

-- Generic frequency divider for a 50 MHz board oscillator.
-- clk_out is HIGH for exactly one clk_in cycle each period, making it
-- suitable for use as a synchronous clock-enable (Cen) rather than a
-- direct clock.  Driving sequential logic directly from clk_out would
-- create a gated clock and is therefore discouraged on FPGAs.
--
-- Example: freq_out => 1 gives a 1 Hz enable pulse (one tick per second).
entity clk_div is
    generic (
        freq_out : natural  -- desired output frequency in Hz
    );
    port (
        clk_in  : in  std_logic;
        reset   : in  std_logic;
        clk_out : out std_logic
    );
end clk_div;

architecture behavior of clk_div is
    constant FREQ_OSC  : natural := 50_000_000;       -- 50 MHz crystal
    constant MAX_COUNT : natural := FREQ_OSC / freq_out;
    signal   counter   : natural range 0 to MAX_COUNT;
begin

    freq_divider: process(reset, clk_in)
    begin
        if reset = '1' then
            counter <= 0;
            clk_out <= '0';
        elsif rising_edge(clk_in) then
            if counter = MAX_COUNT then
                counter <= 0;
                clk_out <= '1';   -- one-cycle high pulse
            else
                counter <= counter + 1;
                clk_out <= '0';
            end if;
        end if;
    end process freq_divider;

end behavior;
