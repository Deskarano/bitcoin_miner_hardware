library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity msa_extender is
    port
    (
        clk   : in std_logic;
        reset : in std_logic;
        
        data_in    : in std_logic_vector(31 downto 0);
        data_valid : in std_logic;
        
        msa_out : out std_logic_vector(31 downto 0)
    );
    
end msa_extender;

architecture Behavioral of msa_extender is
    signal res_buf : std_logic_vector(31 downto 0) := (others => '0');
    signal buf_state : natural range 0 to 3 := 0;
    
    signal var1 : std_logic_vector(31 downto 0) := (others => '0');
    signal var2 : std_logic_vector(31 downto 0) := (others => '0');
begin
    msa_out <= res_buf;
    
    var1 <= std_logic_vector(rotate_right(unsigned(data_in), 7)) xor 
            std_logic_vector(rotate_right(unsigned(data_in), 18)) xor 
            std_logic_vector(shift_right(unsigned(data_in), 3)); 
            
    var2 <= std_logic_vector(rotate_right(unsigned(data_in), 17)) xor 
            std_logic_vector(rotate_right(unsigned(data_in), 19)) xor 
            std_logic_vector(shift_right(unsigned(data_in), 10));

    work : process(clk, reset)
    begin
        if reset = '1' then
            res_buf   <= (others => '0');
            buf_state <= 0;        
        elsif rising_edge(clk) then                        
            if data_valid = '1' then
                case buf_state is
                    when 0 => 
                        res_buf   <= res_buf + var1;
                        buf_state <= 1;
                                                   
                    when 1 => 
                        res_buf   <= res_buf + var2;
                        buf_state <= 2;
                        
                    when 2 => 
                        res_buf   <= res_buf + data_in;
                        buf_state <= 3;
                        
                    when 3 => res_buf <= res_buf + data_in;
                end case;           
            end if;            
        end if;
    end process work;
    
end Behavioral;
