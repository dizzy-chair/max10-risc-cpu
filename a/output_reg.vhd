library ieee;
use ieee.std_logic_1164.all;

-- 8-bit output register used to latch values onto the seven-segment
-- display or the LED bank.
-- The register captures data_in on the falling clock edge when both
-- enabled (global clock enable) and write_en (instruction write-enable)
-- are asserted.  Asynchronous reset clears all bits to 0.
entity output_reg is
    port (
        data_in  : in  std_logic_vector(7 downto 0);
        clock    : in  std_logic;
        enabled  : in  std_logic;  -- global clock enable (from clock divider)
        write_en : in  std_logic;  -- per-instruction write enable
        reset    : in  std_logic;  -- asynchronous reset
        data_out : out std_logic_vector(7 downto 0)
    );
end output_reg;

architecture behavior of output_reg is
begin

    latch: process(clock, reset)
    begin
        if reset = '1' then
            data_out <= (others => '0');
        elsif falling_edge(clock) then
            if enabled = '1' and write_en = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process latch;

end behavior;
