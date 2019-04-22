library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity miner is    
    port
    (
        clk      : in std_logic;
        interrupt: in std_logic;
        
        rx_pin : in std_logic;
        tx_pin : out std_logic
    );
end miner;

architecture Behavioral of miner is

    component comm_pico is
        port
        ( 
            clk           : in std_logic;
            int_sig       : in std_logic;
            uart_rx_pin   : in std_logic;
            uart_tx_pin   : out std_logic;
            
            worker_select : out std_logic_vector(7 downto 0);
            
            status_out_worker : out std_logic_vector(3 downto 0);  
            status_out_miner  : out std_logic_vector(3 downto 0);
            recv_data_out     : out std_logic_vector(7 downto 0);
            
            status_in_worker  : in std_logic_vector(3 downto 0);   
            status_in_miner   : in std_logic_vector(3 downto 0);
            send_data_in      : in std_logic_vector(7 downto 0)
        );
    end component;
    
    component work_pico is
        port
        (
            clk     : in std_logic;
            int_sig : in std_logic;
            
            status_out_contr : out std_logic_vector(3 downto 0);  
            status_out_miner : out std_logic_vector(3 downto 0);
            send_data_out    : out std_logic_vector(7 downto 0);
            
            status_in_contr  : in std_logic_vector(3 downto 0);   
            status_in_miner  : in std_logic_vector(3 downto 0);
            recv_data_in     : in std_logic_vector(7 downto 0)
        );
    end component;

    signal worker_id         : std_logic_vector(7 downto 0);
    
    signal control_status_in_worker  : std_logic_vector(3 downto 0) := (others => '0');
    signal control_status_out_worker : std_logic_vector(3 downto 0) := (others => '0');
    signal control_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal control_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal control_data_in_worker    : std_logic_vector(7 downto 0) := (others => '0');
    signal control_data_out_worker   : std_logic_vector(7 downto 0) := (others => '0');

    signal worker1_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker1_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker1_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker1_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker1_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker1_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker2_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker2_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker2_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker2_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker2_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker2_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker3_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker3_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker3_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker3_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker3_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker3_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker4_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker4_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker4_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker4_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker4_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker4_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker5_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker5_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker5_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker5_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker5_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker5_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker6_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker6_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker6_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker6_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker6_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker6_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal worker7_status_in_contr   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker7_status_out_contr  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker7_status_in_miner   : std_logic_vector(3 downto 0) := (others => '0');
    signal worker7_status_out_miner  : std_logic_vector(3 downto 0) := (others => '0');
    signal worker7_data_in_contr     : std_logic_vector(7 downto 0) := (others => '0');
    signal worker7_data_out_contr    : std_logic_vector(7 downto 0) := (others => '0');
begin
    
    control_status_in_worker <= worker1_status_out_contr when worker_id(2 downto 0) = "001" else
                                worker2_status_out_contr when worker_id(2 downto 0) = "010" else
                                worker3_status_out_contr when worker_id(2 downto 0) = "011" else
                                worker4_status_out_contr when worker_id(2 downto 0) = "100" else
                                worker5_status_out_contr when worker_id(2 downto 0) = "101" else
                                worker6_status_out_contr when worker_id(2 downto 0) = "110" else
                                worker7_status_out_contr when worker_id(2 downto 0) = "111" else
                                (others => '0');
                                
    control_data_in_worker   <= worker1_data_out_contr when worker_id(2 downto 0) = "001" else
                                worker2_data_out_contr when worker_id(2 downto 0) = "010" else
                                worker3_data_out_contr when worker_id(2 downto 0) = "011" else
                                worker4_data_out_contr when worker_id(2 downto 0) = "100" else
                                worker5_data_out_contr when worker_id(2 downto 0) = "101" else
                                worker6_data_out_contr when worker_id(2 downto 0) = "110" else
                                worker7_data_out_contr when worker_id(2 downto 0) = "111" else
                                (others => '0');
                                
    worker1_status_in_contr  <= control_status_out_worker;
    worker1_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "001" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
    
    worker2_status_in_contr  <= control_status_out_worker;
    worker2_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "010" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
                                                             
    worker3_status_in_contr  <= control_status_out_worker;
    worker3_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "011" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
                                
    worker4_status_in_contr  <= control_status_out_worker;
    worker4_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "100" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
    
    worker5_status_in_contr  <= control_status_out_worker;
    worker5_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "101" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
                                                             
    worker6_status_in_contr  <= control_status_out_worker;
    worker6_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "110" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');
                                
    worker7_status_in_contr  <= control_status_out_worker;
    worker7_data_in_contr    <= control_data_out_worker when worker_id(2 downto 0) = "111" or -- single cast
                                                             worker_id(2 downto 0) = "000"    -- multicast
                                else (others => '0');

    controller : comm_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            uart_rx_pin   => rx_pin,
            uart_tx_pin   => tx_pin,

            worker_select => worker_id,
            
            status_out_worker => control_status_out_worker,
            status_out_miner  => control_status_out_miner,
            recv_data_out     => control_data_out_worker,
            
            status_in_worker  => control_status_in_worker,
            status_in_miner   => control_status_in_miner,
            send_data_in      => control_data_in_worker
        );
        
    worker1 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker1_status_out_contr,
            status_out_miner => worker1_status_out_miner,
            send_data_out    => worker1_data_out_contr,
            
            status_in_contr  => worker1_status_in_contr,
            status_in_miner  => worker1_status_in_miner,
            recv_data_in     => worker1_data_in_contr
        );
        
    worker2 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker2_status_out_contr,
            status_out_miner => worker2_status_out_miner,
            send_data_out    => worker2_data_out_contr,
            
            status_in_contr  => worker2_status_in_contr,
            status_in_miner  => worker2_status_in_miner,
            recv_data_in     => worker2_data_in_contr
        );
        
    worker3 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker3_status_out_contr,
            status_out_miner => worker3_status_out_miner,
            send_data_out    => worker3_data_out_contr,
            
            status_in_contr  => worker3_status_in_contr,
            status_in_miner  => worker3_status_in_miner,
            recv_data_in     => worker3_data_in_contr
        );
        
    worker4 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker4_status_out_contr,
            status_out_miner => worker4_status_out_miner,
            send_data_out    => worker4_data_out_contr,
            
            status_in_contr  => worker4_status_in_contr,
            status_in_miner  => worker4_status_in_miner,
            recv_data_in     => worker4_data_in_contr
        );
        
    worker5 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker5_status_out_contr,
            status_out_miner => worker5_status_out_miner,
            send_data_out    => worker5_data_out_contr,
            
            status_in_contr  => worker5_status_in_contr,
            status_in_miner  => worker5_status_in_miner,
            recv_data_in     => worker5_data_in_contr
        );
        
    worker6 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker6_status_out_contr,
            status_out_miner => worker6_status_out_miner,
            send_data_out    => worker6_data_out_contr,
            
            status_in_contr  => worker6_status_in_contr,
            status_in_miner  => worker6_status_in_miner,
            recv_data_in     => worker6_data_in_contr
        );
        
    worker7 : work_pico
        port map
        (
            clk           => clk,
            int_sig       => interrupt,
            
            status_out_contr => worker7_status_out_contr,
            status_out_miner => worker7_status_out_miner,
            send_data_out    => worker7_data_out_contr,
            
            status_in_contr  => worker7_status_in_contr,
            status_in_miner  => worker7_status_in_miner,
            recv_data_in     => worker7_data_in_contr
        );

    handle_sync : process(clk)
    begin
        if rising_edge(clk) then
            case worker_id(2 downto 0) is
                when "000" =>
                    if control_status_out_miner(0) = '1' and 
                       worker1_status_out_miner(0) = '1' and 
                       worker2_status_out_miner(0) = '1' and
                       worker3_status_out_miner(0) = '1' and 
                       worker4_status_out_miner(0) = '1' and 
                       worker5_status_out_miner(0) = '1' and
                       worker6_status_out_miner(0) = '1' and
                       worker7_status_out_miner(0) = '1' then
                       
                        control_status_in_miner(0) <= '0';
                        worker1_status_in_miner(0) <= '0';
                        worker2_status_in_miner(0) <= '0';
                        worker3_status_in_miner(0) <= '0';
                        worker4_status_in_miner(0) <= '0';
                        worker5_status_in_miner(0) <= '0';
                        worker6_status_in_miner(0) <= '0';        
                        worker7_status_in_miner(0) <= '0';  
                            
                    else
                    
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                        worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                        worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                        worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                        worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                        worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                        worker7_status_in_miner(0) <= worker7_status_out_miner(0);

                    end if;
                    
                when "001" =>
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);
                    
                    if control_status_out_miner(0) = '1' and worker1_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker1_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    end if;
                    
                when "010" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);

                    if control_status_out_miner(0) = '1' and worker2_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker2_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    end if;  
                    
                when "011" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);
    
                    if control_status_out_miner(0) = '1' and worker3_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker3_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    end if;  
                    
                when "100" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);
    
                    if control_status_out_miner(0) = '1' and worker4_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker4_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    end if;    
                    
                when "101" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);
                    
                    if control_status_out_miner(0) = '1' and worker5_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker5_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    end if;    
                    
                when "110" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);
                    
                    if control_status_out_miner(0) = '1' and worker6_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker6_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    end if;    
                    
                when "111" =>
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    
                    if control_status_out_miner(0) = '1' and worker7_status_out_miner(0) = '1' then
                        control_status_in_miner(0) <= '0';
                        worker7_status_in_miner(0) <= '0';
                    else
                        control_status_in_miner(0) <= control_status_out_miner(0);
                        worker7_status_in_miner(0) <= worker7_status_out_miner(0);
                    end if;    
                    
                when others => 
                    worker1_status_in_miner(0) <= worker1_status_out_miner(0);
                    worker2_status_in_miner(0) <= worker2_status_out_miner(0);
                    worker3_status_in_miner(0) <= worker3_status_out_miner(0);
                    worker4_status_in_miner(0) <= worker4_status_out_miner(0);
                    worker5_status_in_miner(0) <= worker5_status_out_miner(0);
                    worker6_status_in_miner(0) <= worker6_status_out_miner(0);
                    worker7_status_in_miner(0) <= worker7_status_out_miner(0);

            end case;
        end if;
    end process handle_sync;

end Behavioral;
