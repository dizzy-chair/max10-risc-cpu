library ieee;
use ieee.std_logic_1164.all;

-- Hex-to-seven-segment decoder for a common-anode display (segments
-- are active-low, as found on Terasic DE-series boards).
--
-- Segment bit mapping:  [7]=dp  [6]=g  [5]=f  [4]=e
--                       [3]=d   [2]=c  [1]=b  [0]=a
entity dec_7seg is
    port (
        nibble_in    : in  std_logic_vector(3 downto 0);
        segments_out : out std_logic_vector(7 downto 0)   -- active-low
    );
end dec_7seg;

architecture behavior of dec_7seg is
begin

    with nibble_in select
    --                dp gfedcba
        segments_out <= "11000000" when "0000",  -- 0
                        "11111001" when "0001",  -- 1
                        "10100100" when "0010",  -- 2
                        "10110000" when "0011",  -- 3
                        "10011001" when "0100",  -- 4
                        "10010010" when "0101",  -- 5
                        "10000010" when "0110",  -- 6
                        "11111000" when "0111",  -- 7
                        "10000000" when "1000",  -- 8
                        "10010000" when "1001",  -- 9
                        "10001000" when "1010",  -- A
                        "10000011" when "1011",  -- b
                        "11000110" when "1100",  -- C
                        "10100001" when "1101",  -- d
                        "10000110" when "1110",  -- E
                        "10001110" when others;  -- F

end behavior;
