library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 8 × 8-bit register file with two asynchronous read ports and one
-- synchronous write port (write on falling edge when both enabled and
-- signal_we are asserted).
entity data_registers is
    port (
        selector_a  : in  std_logic_vector(2 downto 0);  -- read address A
        selector_b  : in  std_logic_vector(2 downto 0);  -- read address B
        selector_wr : in  std_logic_vector(2 downto 0);  -- write address
        data_in     : in  std_logic_vector(7 downto 0);
        clock       : in  std_logic;
        enabled     : in  std_logic;  -- global clock enable (from clock divider)
        reset       : in  std_logic;  -- asynchronous reset
        signal_we   : in  std_logic;  -- write enable
        output_a    : out std_logic_vector(7 downto 0);
        output_b    : out std_logic_vector(7 downto 0)
    );
end data_registers;

architecture behavior of data_registers is
    type register_file is array (0 to 7) of std_logic_vector(7 downto 0);
    signal registers : register_file;
begin

    write_port: process(clock, reset)
    begin
        if reset = '1' then
            registers <= (others => (others => '0'));
        elsif falling_edge(clock) then
            if signal_we = '1' and enabled = '1' then
                registers(to_integer(unsigned(selector_wr))) <= data_in;
            end if;
        end if;
    end process write_port;

    -- Asynchronous read ports
    output_a <= registers(to_integer(unsigned(selector_a)));
    output_b <= registers(to_integer(unsigned(selector_b)));

end behavior;
