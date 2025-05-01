library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port( op : in std_logic_vector(3 downto 0);
          i1 : in std_logic_vector(15 downto 0);
          i2 : in std_logic_vector(15 downto 0);
          o  : out std_logic_vector(15 downto 0);
          st : out std_logic_vector(3 downto 0));
end alu;

architecture Behavioral of alu is
begin
    process(op, i1, i2)
        variable res    : std_logic_vector(16 downto 0) := (others => '0');
        variable ca2    : std_logic_vector(16 downto 0) := (others => '0');
        variable amount : integer := 0;
    begin
        case op is

            when "0000" =>
                res := '0' & (i1 and i2);
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "0001" =>
                res := '0' & (i1 or i2); st(1) <= '0'; st(0) <= '0';
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "0010" =>
                res := '0' & (i1 xor i2); st(1) <= '0'; st(0) <= '0';
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "0011" =>
                res := '0' & not i2; st(1) <= '0'; st(0) <= '0';
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "0100" =>
                res := std_logic_vector(unsigned('0' & i1) + unsigned('0' & i2));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                st(1) <= res(16);
                st(0) <= (i1(15) and i2(15) and not(res(15))) or (not(i1(15)) and not(i2(15)) and res(15));

            when "0101" =>
                ca2 := std_logic_vector(unsigned('0' & not i2) + 1);
                res := std_logic_vector(unsigned('0' & i1) + unsigned(ca2));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                st(1) <= res(16);
                st(0) <= (i1(15) and not(i2(15)) and not(res(15))) or (not(i1(15)) and i2(15) and res(15));

            when "0110" =>
                amount := to_integer(signed(i2));
                res := std_logic_vector(shift_left(unsigned('0' & i1), amount));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                if (amount > 16 and i1 /= x"0000") or
                   (amount <= 16 and amount > 0 and unsigned(i1(15 downto (16 - amount))) /= 0) then
                    st(1) <= '1';
                else
                    st(1) <= '0';
                end if;
                st(0) <= res(15) xor i1(15);

            when "0111" =>
                amount := to_integer(signed(i2));
                res := std_logic_vector(shift_right(unsigned('0' & i1), amount));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                if (amount < 0 and abs(amount) > 16 and i1 /= x"0000") or
                   (amount < 0 and abs(amount) <= 16 and unsigned(i1(15 downto (16 + amount))) /= 0) then
                    st(1) <= '1';
                else
                    st(1) <= '0';
                end if;
                st(0) <= res(15) xor i1(15);

            when "1000" | "1010" | "1110" | "1111" =>
                res := '0' & i2;
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "1001" | "1011" =>
                res := '0' & i1;
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15); st(1) <= '0'; st(0) <= '0';

            when "1100" =>
                res := std_logic_vector(unsigned('0' & i1) + unsigned('0' & i2));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                st(1) <= res(16);
                st(0) <= (i1(15) and i2(15) and not(res(15))) or (not(i1(15)) and not(i2(15)) and res(15));

            when "1101" =>
                ca2 := std_logic_vector(unsigned('0' & not i2) + 1);
                res := std_logic_vector(unsigned('0' & i1) + unsigned(ca2));
                if res(15 downto 0) = x"0000" then st(3) <= '1'; else st(3) <= '0'; end if;
                st(2) <= res(15);
                st(1) <= res(16);
                st(0) <= (i1(15) and not(i2(15)) and not(res(15))) or (not(i1(15)) and i2(15) and res(15));

            when others =>
                res := (others => 'Z'); st <= "ZZZZ";

        end case;

        o <= res(15 downto 0);
    end process;
end Behavioral;
