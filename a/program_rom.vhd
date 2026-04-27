library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 256 × 21-bit asynchronous program ROM.
-- Each 21-bit word is split into instruction fields on output:
--
--   Bits [20:17]  opcode  (4 bits)
--   Bits [16:14]  rs      (3 bits) – source register A
--   Bits [13:11]  rt      (3 bits) – source register B
--   Bits [10: 8]  rd      (3 bits) – destination register
--   Bits [ 7: 0]  imm     (8 bits) – immediate / branch offset
--
-- Loaded program: Fibonacci sequence
--   r1 = 1   (ADDI r1, r0, 1)
--   r2 = 233 (ADDI r2, r0, 233)
--   loop: r3 = r1 + r2  (ADD)
--         ...
--   Jumps back to continue the sequence
entity program_rom is
    port (
        addr    : in  std_logic_vector(7 downto 0);
        data_op : out std_logic_vector(3 downto 0);   -- opcode
        data_rs : out std_logic_vector(2 downto 0);   -- rs field
        data_rt : out std_logic_vector(2 downto 0);   -- rt field
        data_rd : out std_logic_vector(2 downto 0);   -- rd field
        data_i  : out std_logic_vector(7 downto 0)    -- immediate
    );
end program_rom;

architecture behavior of program_rom is

    constant ADDR_WIDTH : natural :=  8;   -- 2^8 = 256 locations
    constant WORD_WIDTH : natural := 21;

    type rom_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);

    constant ROM : rom_type := (
        -- Active program (Fibonacci sequence)
        '1'&x"00000", '1'&x"00101", '1'&x"002E9", '0'&x"00B00",
        '1'&x"AC000", '0'&x"44800", '0'&x"4D900", '1'&x"4D002",
        '1'&x"60003", '1'&x"60009",
        -- Unused locations – filled with NOPs (opcode 0, all zeros)
        others => '0' & x"00000"
    );

    signal word : std_logic_vector(WORD_WIDTH - 1 downto 0);

begin

    word <= ROM(to_integer(unsigned(addr)));

    data_op <= word(20 downto 17);
    data_rs <= word(16 downto 14);
    data_rt <= word(13 downto 11);
    data_rd <= word(10 downto  8);
    data_i  <= word( 7 downto  0);

end behavior;
