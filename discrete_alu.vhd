library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 8-bit Arithmetic Logic Unit.
-- Performs one of eight operations selected by `operation`:
--   000 = ADD,  001 = SUB,  010 = AND,  011 = OR
--   100 = XOR,  101 = NOT,  110 = SHL,  111 = SHR
entity discrete_alu is
    port (
        input_a   : in  std_logic_vector(7 downto 0);
        input_b   : in  std_logic_vector(7 downto 0);
        operation : in  std_logic_vector(2 downto 0);
        result    : out std_logic_vector(7 downto 0);
        flag_zero : out std_logic
    );
end discrete_alu;

architecture behavior of discrete_alu is
    signal temp_result : std_logic_vector(7 downto 0);
begin

    -- Combinational operation select
    temp_result <=
        std_logic_vector(unsigned(input_a) + unsigned(input_b)) when operation = "000" else  -- ADD
        std_logic_vector(unsigned(input_a) - unsigned(input_b)) when operation = "001" else  -- SUB
        input_a and input_b                                      when operation = "010" else  -- AND
        input_a or  input_b                                      when operation = "011" else  -- OR
        input_a xor input_b                                      when operation = "100" else  -- XOR
        not input_a                                              when operation = "101" else  -- NOT
        input_a(6 downto 0) & '0'                               when operation = "110" else  -- SHL
        '0' & input_a(7 downto 1);                                                           -- SHR

    result    <= temp_result;
    flag_zero <= '1' when temp_result = x"00" else '0';

end behavior;
