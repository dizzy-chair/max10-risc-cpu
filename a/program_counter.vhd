library ieee;
use ieee.std_logic_1164.all;

-- 8-bit Program Counter register.
-- Loads counter_in on the rising clock edge whenever enabled is asserted.
-- Asynchronous reset clears the counter to 0.
entity program_counter is
    port (
        counter_in  : in  std_logic_vector(7 downto 0);
        clock       : in  std_logic;
        enabled     : in  std_logic;  -- clock enable (from clock divider)
        reset       : in  std_logic;  -- asynchronous reset
        counter_out : out std_logic_vector(7 downto 0)
    );
end program_counter;

architecture behavior of program_counter is
    signal counter_tmp : std_logic_vector(7 downto 0);
begin

    update_register: process(reset, clock)
    begin
        if reset = '1' then
            counter_tmp <= (others => '0');
        elsif rising_edge(clock) then
            if enabled = '1' then
                counter_tmp <= counter_in;
            end if;
        end if;
    end process update_register;

    counter_out <= counter_tmp;

end behavior;
