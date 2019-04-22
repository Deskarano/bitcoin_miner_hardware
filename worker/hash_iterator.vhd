library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity hash_iterator is
    port
    (
        clk : in std_logic;
        reset : in std_logic;
        
        msa_in : in std_logic_vector(31 downto 0);
        rc_in  : in std_logic_vector(31 downto 0);
        valid  : in std_logic;
        
        a_in : in std_logic_vector(31 downto 0);
        b_in : in std_logic_vector(31 downto 0);
        c_in : in std_logic_vector(31 downto 0);
        d_in : in std_logic_vector(31 downto 0);
        e_in : in std_logic_vector(31 downto 0);
        f_in : in std_logic_vector(31 downto 0);
        g_in : in std_logic_vector(31 downto 0);
        h_in : in std_logic_vector(31 downto 0);
        
        new_a_out : out std_logic_vector(31 downto 0);
        new_e_out : out std_logic_vector(31 downto 0)  
    );
end hash_iterator;

architecture Behavioral of hash_iterator is
    -- math values
    signal temp1 : std_logic_vector(31 downto 0) := (others => '0');
    signal temp2 : std_logic_vector(31 downto 0) := (others => '0');
    
    signal S1  : std_logic_vector(31 downto 0) := (others => '0');
    signal S0  : std_logic_vector(31 downto 0) := (others => '0');
    signal ch  : std_logic_vector(31 downto 0) := (others => '0');
    signal maj : std_logic_vector(31 downto 0) := (others => '0');

begin
    S1  <= std_logic_vector(rotate_right(unsigned(e_in), 6)) xor
           std_logic_vector(rotate_right(unsigned(e_in), 11)) xor
           std_logic_vector(rotate_right(unsigned(e_in), 25));
          
    S0  <= std_logic_vector(rotate_right(unsigned(a_in), 2)) xor
           std_logic_vector(rotate_right(unsigned(a_in), 13)) xor
           std_logic_vector(rotate_right(unsigned(a_in), 22));
          
    ch  <= (e_in and f_in) xor ((not e_in) and g_in);
    maj <= (a_in and b_in) xor (a_in and c_in) xor (b_in and c_in);
    
    temp1 <= h_in + S1 + ch + rc_in + msa_in;
    temp2 <= S0 + maj;
    
    iterate : process(clk)
    begin
        if rising_edge(clk) then
            if valid = '1' then
                new_e_out <= d_in + temp1;
                new_a_out <= temp1 + temp2;
            else
                new_e_out <= (others => '0');
                new_a_out <= (others => '0');
            end if;
        end if;
    end process iterate;
end Behavioral;
