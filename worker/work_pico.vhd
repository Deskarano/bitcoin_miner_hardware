library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity work_pico is
    port
    (
        clk     : in std_logic;
        int_sig : in std_logic;
        
        status_out_contr : out std_logic_vector(3 downto 0); -- XX | state1 | state0
        status_out_miner : out std_logic_vector(3 downto 0); -- XXX | sync_req
        send_data_out    : out std_logic_vector(7 downto 0);
        
        status_in_contr  : in std_logic_vector(3 downto 0);   
        status_in_miner  : in std_logic_vector(3 downto 0); -- XXX | sync_sig
        recv_data_in     : in std_logic_vector(7 downto 0)
    );
end work_pico;

architecture Behavioral of work_pico is

    component kcpsm6 
        generic 
        (                 
            hwbuild                 : std_logic_vector(7 downto 0) := X"00";
            interrupt_vector        : std_logic_vector(11 downto 0) := X"3FF";
            scratch_pad_memory_size : integer := 64
        );
        port 
        (                   
            address        : out std_logic_vector(11 downto 0);
            instruction    : in std_logic_vector(17 downto 0);
            bram_enable    : out std_logic;
            in_port        : in std_logic_vector(7 downto 0);
            out_port       : out std_logic_vector(7 downto 0);
            port_id        : out std_logic_vector(7 downto 0);
            write_strobe   : out std_logic;
            k_write_strobe : out std_logic;
            read_strobe    : out std_logic;
            interrupt      : in std_logic;
            interrupt_ack  : out std_logic;
            sleep          : in std_logic;
            reset          : in std_logic;
            clk            : in std_logic
        );
    end component;
    
    component sha_prog                            
        generic
        (    
            C_FAMILY          : string  := "S6"; 
            C_RAM_SIZE_KWORDS : integer := 1
        );
                  
        port  
        (      
            address     : in std_logic_vector(11 downto 0);
            instruction : out std_logic_vector(17 downto 0);
            enable      : in std_logic;
            clk         : in std_logic;
              
            address_b    : in std_logic_vector(15 downto 0);
            data_in_b    : in std_logic_vector(31 downto 0);
            parity_in_b  : in std_logic_vector(3 downto 0);
            data_out_b   : out std_logic_vector(31 downto 0);
            parity_out_b : out std_logic_vector(3 downto 0);
            enable_b     : in std_logic;
            we_b         : in std_logic_vector(3 downto 0)
        );
    end component;
    
    component mem_interface
        generic ( C_BRAM_PORT_WIDTH : string := "1" );
        port 
        (
            -- data inputs
            clk            : in std_logic;
            reset          : in std_logic;
            
            split_addr_in  : in std_logic_vector(7 downto 0);
            split_data_in  : in std_logic_vector(7 downto 0);
            parity_in      : in std_logic;
            
            -- signals
            addr_buf_en    : in std_logic;
            data_buf_en    : in std_logic;
                       
            -- to bram
            bram_addr_out   : out std_logic_vector(15 downto 0);
            bram_data_out   : out std_logic_vector(31 downto 0);
            bram_parity_out : out std_logic_vector(3 downto 0);
            
            bram_data_in    : in std_logic_vector(31 downto 0);
            bram_parity_in  : in std_logic_vector(3 downto 0)
        );
    end component;
    
    component msa_extender is
        port
        (
            clk   : in std_logic;
            reset : in std_logic;
            
            data_in    : in std_logic_vector(31 downto 0);
            data_valid : in std_logic;
            
            msa_out : out std_logic_vector(31 downto 0)
        );
    end component;
    
    component hash_iterator is
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
    end component;
    
    -- stuff for the processor
    signal address        : std_logic_vector(11 downto 0) := (others => '0');
    signal instruction    : std_logic_vector(17 downto 0) := (others => '0');
    signal bram_enable    : std_logic                     := '0';
    signal in_port        : std_logic_vector(7 downto 0)  := (others => '0');
    signal out_port       : std_logic_vector(7 downto 0)  := (others => '0');
    signal port_id        : std_logic_vector(7 downto 0)  := (others => '0');
    signal write_strobe   : std_logic                     := '0';
    signal k_write_strobe : std_logic                     := '0';
    signal read_strobe    : std_logic                     := '0';
    signal interrupt      : std_logic                     := '0';
    signal interrupt_ack  : std_logic                     := '0';
    signal kcpsm6_sleep   : std_logic                     := '0';
    signal kcpsm6_reset   : std_logic                     := '0';
    
    -- signals for memory interface
    signal mem_intf_split_addr_in   : std_logic_vector(7 downto 0)  := (others => '0');
    signal mem_intf_split_data_in   : std_logic_vector(7 downto 0)  := (others => '0');
    signal mem_intf_parity_in       : std_logic                     := '0';
    
    signal mem_intf_addr_buf_en     : std_logic                     := '0';
    signal mem_intf_data_buf_en     : std_logic                     := '0';
    signal mem_intf_reset           : std_logic                     := '0';
        
    signal mem_intf_bram_addr_out   : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_intf_bram_data_out   : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_intf_bram_parity_out : std_logic_vector(3 downto 0)  := (others => '0');
    
    signal mem_intf_bram_data_in    : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_intf_bram_parity_in  : std_logic_vector(3 downto 0)  := (others => '0');
    
    -- signals for bram
    signal bram_addr       : std_logic_vector(15 downto 0) := (others => '0');
    signal bram_data_in    : std_logic_vector(31 downto 0) := (others => '0');
    signal bram_parity_in  : std_logic_vector(3 downto 0)  := (others => '0');
    signal bram_data_out   : std_logic_vector(31 downto 0) := (others => '0');
    signal bram_parity_out : std_logic_vector(3 downto 0)  := (others => '0');
    
    signal bram_we : std_logic_vector(3 downto 0) := (others => '0');
    
    -- signals for the msa_extender
    signal msa_extender_reset      : std_logic := '0';
    signal msa_extender_data_in    : std_logic_vector(31 downto 0) := (others => '0');
    signal msa_extender_data_valid : std_logic := '0';
    signal msa_extender_data_out   : std_logic_vector(31 downto 0) := (others => '0');
    
    -- signals for the hash iterator
    signal hash_iterator_reset  : std_logic                     := '0';
    signal hash_iterator_msa_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_rc_in  : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_valid  : std_logic                     := '0';
    
    signal hash_iterator_a_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_b_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_c_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_d_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_e_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_f_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_g_in : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_h_in : std_logic_vector(31 downto 0) := (others => '0');
    
    signal hash_iterator_new_a_out : std_logic_vector(31 downto 0) := (others => '0');
    signal hash_iterator_new_e_out : std_logic_vector(31 downto 0) := (others => '0');
    
    -- for the miner and control
    signal status_out_buf : std_logic_vector(7 downto 0) := (others => '0');
    signal status_in_buf  : std_logic_vector(7 downto 0) := (others => '0');
    
    -- for the main state machine
    signal worker_state  : natural range 0 to 3  := 0;
    signal worker_idx    : natural range 0 to 63 := 0;
    signal worker_subidx : natural range 0 to 4  := 0;
    
    -- for the bram state machines
    signal addr_writes     : natural range 0 to 2  := 0;
    signal data_writes     : natural range 0 to 4  := 0;
    signal bram_read_data  : std_logic := '0';
    signal bram_write_data : std_logic := '0';
    
begin
    -- constant, system level mappings
    kcpsm6_sleep <= status_in_miner(0);
    
    status_out_contr <= status_out_buf(7 downto 4);
    status_out_miner <= status_out_buf(3 downto 0);
    status_in_buf    <= status_in_contr & status_in_miner;
    
    worker_state <= 0 when status_out_buf(5 downto 4) = "00" else
                    1 when status_out_buf(5 downto 4) = "01" else
                    2 when status_out_buf(5 downto 4) = "10" else
                    3;
    
    -- various memory mappings 
    bram_addr      <= mem_intf_bram_addr_out;
    bram_data_in   <= mem_intf_bram_data_out when (worker_state = 0 and worker_idx < 16) else 
                      msa_extender_data_out when (worker_state = 0 and worker_idx >= 16) else
                      mem_intf_bram_data_out;
                      
    bram_parity_in <= mem_intf_bram_parity_out when (worker_state = 0 and worker_idx < 16) else 
                      "1111" when (worker_state = 0 and worker_idx >= 16) else
                      "1111";
    
    mem_intf_bram_data_in <= bram_data_out when (worker_state = 0 and worker_idx < 16) else 
                             (others => '0') when (worker_state = 0 and worker_idx >= 16) else
                             (others => '0');
                               
    mem_intf_bram_parity_in <= bram_parity_out when (worker_state = 0 and worker_idx < 16) else 
                               (others => '0') when (worker_state = 0 and worker_idx >= 16) else
                               (others => '0');
    
    msa_extender_data_in <= (others => '0') when worker_state = 0 and worker_idx < 16 else
                            bram_data_out when worker_state = 0 and worker_idx >= 16 else 
                            (others => '0');
                            
    -- for the hash iterator
    hash_iterator_msa_in <= (others => '0') when worker_state = 0 else
                            bram_data_out when worker_state = 1 and worker_subidx = 0 else
                            (others => '0');
                            
    hash_iterator_rc_in  <= (others => '0') when worker_state = 0 else
                            bram_data_out when worker_state = 1 and worker_subidx = 1 else
                            (others => '0');

    processor: kcpsm6
        generic map 
        (                 
            hwbuild                 => X"00", 
            interrupt_vector        => X"7D1",
            scratch_pad_memory_size => 64
        )
        port map 
        (      
            address        => address,
            instruction    => instruction,
            bram_enable    => bram_enable,
            port_id        => port_id,
            write_strobe   => write_strobe,
            k_write_strobe => k_write_strobe,
            out_port       => out_port,
            read_strobe    => read_strobe,
            in_port        => in_port,
            interrupt      => interrupt,
            interrupt_ack  => interrupt_ack,
            sleep          => kcpsm6_sleep,
            reset          => kcpsm6_reset,
            clk            => clk
        );
        
    program_rom: sha_prog                   --Name to match your PSM file
        generic map 
        (             
            C_FAMILY             => "7S",   --Family 'S6', 'V6' or '7S'
            C_RAM_SIZE_KWORDS    => 2       --Program size '1', '2' or '4'
        )      
        port map 
        (      
            address     => address,      
            instruction => instruction,
            enable      => bram_enable,
            clk         => clk,
            
            address_b    => bram_addr,
            data_in_b    => bram_data_in,
            parity_in_b  => bram_parity_in,
            data_out_b   => bram_data_out,
            parity_out_b => bram_parity_out,
            enable_b     => '1',
            we_b         => bram_we
        );
       
    bram_interface: mem_interface
        generic map (C_BRAM_PORT_WIDTH => "36")
        port map 
        (  
            clk            => clk,
            reset          => mem_intf_reset,
            
            split_addr_in   => mem_intf_split_addr_in,
            split_data_in   => mem_intf_split_data_in,
            parity_in       => mem_intf_parity_in,
            
            addr_buf_en     => mem_intf_addr_buf_en,
            data_buf_en     => mem_intf_data_buf_en,
                                
            bram_addr_out   => mem_intf_bram_addr_out,
            bram_data_out   => mem_intf_bram_data_out,
            bram_parity_out => mem_intf_bram_parity_out,
            
            bram_data_in    => mem_intf_bram_data_in,
            bram_parity_in  => mem_intf_bram_parity_in
        );
        
    extend_msa: msa_extender
        port map
        (
            clk       => clk,
            reset     => msa_extender_reset,
            
            data_in    => msa_extender_data_in,
            data_valid => msa_extender_data_valid,
            
            msa_out    => msa_extender_data_out
        );
    
    iterate_hash: hash_iterator
        port map
        (
            clk    => clk,
            reset  => hash_iterator_reset,
            
            msa_in => hash_iterator_msa_in,
            rc_in  => hash_iterator_rc_in,
            valid  => hash_iterator_valid,
            
            a_in   => hash_iterator_a_in,
            b_in   => hash_iterator_b_in,
            c_in   => hash_iterator_c_in,
            d_in   => hash_iterator_d_in,
            e_in   => hash_iterator_e_in,
            f_in   => hash_iterator_f_in,
            g_in   => hash_iterator_g_in,
            h_in   => hash_iterator_h_in,
            
            new_a_out => hash_iterator_new_a_out,
            new_e_out => hash_iterator_new_e_out
        );
        
    bram_we <= "1111" when bram_write_data = '1' else "0000";
        
    handle_mem_states : process(clk)
    begin
        if rising_edge(clk) then    
            msa_extender_data_valid <= '0';
            hash_iterator_valid     <= '0';

            if bram_read_data = '1' then
                mem_intf_reset <= '1';
                
                case worker_state is
                    when 0 =>
                        if worker_idx >= 16 then
                            msa_extender_data_valid <= '1';
                        end if;
                        
                    when 1 =>
                        case worker_subidx is
                            when 0 => 
                                if worker_idx = 0 then
                                    hash_iterator_a_in <= x"6a09e667";
                                    hash_iterator_b_in <= x"bb67ae85";
                                    hash_iterator_c_in <= x"3c6ef372";
                                    hash_iterator_d_in <= x"a54ff53a";
                                    hash_iterator_e_in <= x"510e527f";
                                    hash_iterator_f_in <= x"9b05688c";
                                    hash_iterator_g_in <= x"1f83d9ab";
                                    hash_iterator_h_in <= x"5be0cd19";
                                else
                                    hash_iterator_h_in <= hash_iterator_g_in;
                                    hash_iterator_g_in <= hash_iterator_f_in;
                                    hash_iterator_f_in <= hash_iterator_e_in;
                                    hash_iterator_e_in <= hash_iterator_new_e_out;
                                    hash_iterator_d_in <= hash_iterator_c_in;
                                    hash_iterator_c_in <= hash_iterator_b_in;
                                    hash_iterator_b_in <= hash_iterator_a_in;
                                    hash_iterator_a_in <= hash_iterator_new_a_out;
                                end if;
                                                                
                            when 1 => 
                                hash_iterator_valid <= '1';
                                
                            when others => null;
                        end case;
                        
                    when others => null;
                end case;

            elsif bram_write_data = '1' then
                mem_intf_reset     <= '1';
                
                case worker_state is
                    when 0 =>
                        msa_extender_reset <= '1';
                                                
                    when others => null;
                end case;
            else
                mem_intf_reset     <= '0';
                msa_extender_reset <= '0';
            end if;
        end if;
    end process handle_mem_states;
        
    -- Port mapping
    -- 0000 0001 - Memory interface split address out
    -- 0000 0010 - Memory interface split data out, parity 0
    -- 0000 0011 - Memory interface split data out, parity 1
    -- 0000 0100 - Status out
    -- 0000 0101 - Controller send data out
    output_ports : process(clk)
    begin
        if rising_edge(clk) then   
            bram_read_data       <= '0';
            bram_write_data      <= '0';   
                    
            mem_intf_addr_buf_en <= '0';
            mem_intf_data_buf_en <= '0';
            
            if write_strobe = '1' or k_write_strobe = '1' then
                case port_id(2 downto 0) is
                    when "001" => 
                        addr_writes            <= addr_writes + 1;
                        mem_intf_addr_buf_en   <= '1';
                        mem_intf_split_addr_in <= out_port;
                        
                    when "010" =>
                        data_writes            <= data_writes + 1;
                        mem_intf_data_buf_en   <= '1';
                        mem_intf_split_data_in <= out_port;
                        mem_intf_parity_in     <= '0';
                        
                    when "011" =>
                        data_writes            <= data_writes + 1;
                        mem_intf_data_buf_en   <= '1';
                        mem_intf_split_data_in <= out_port;
                        mem_intf_parity_in     <= '1';
                        
                    when "100" => 
                        status_out_buf <= out_port;
                        worker_idx     <= 0;
                    when "101" => send_data_out  <= out_port;
                        
                    when others => null;
                end case;
            end if;
            
            case worker_state is
                when 0 =>
                    if worker_idx < 16 then
                        if addr_writes = 2 and data_writes = 4 then
                            bram_write_data <= '1';
                            addr_writes     <= 0;
                            data_writes     <= 0;
                            
                            worker_idx       <= worker_idx + 1;      
                        end if;
                    else
                        if addr_writes = 2 then
                            if worker_subidx = 4 then
                                bram_write_data <= '1';
                                worker_subidx   <= 0;
                                addr_writes     <= 0;
                                
                                worker_idx      <= worker_idx + 1;      
                            else
                                bram_read_data <= '1';
                                worker_subidx  <= worker_subidx + 1;
                                addr_writes    <= 0;
                            end if;
                        end if;
                    end if;    
                    
                when 1 =>
                    if addr_writes = 2 then
                        bram_read_data <= '1';
                        addr_writes    <= 0;
                        
                        if worker_subidx = 0 then
                            worker_subidx <= 1;
                        elsif worker_subidx = 1 then
                            worker_subidx <= 0;
                            worker_idx    <= worker_idx + 1;      
                        end if;
                    end if;
                    
                when others => null;
            end case;
        end if;
    end process output_ports;
    
    -- Port mapping
    -- 0000 0001 - Memory interface split data in
    -- 0000 0010 - Controller status in
    -- 0000 0011 - Controller recv data in
    -- 0000 0100 - Final hash data in
    input_ports : process(clk)
    begin
        if rising_edge(clk) then
            case port_id(2) is
                when '0' =>
                    case port_id(1 downto 0) is
                        when "01" => in_port <= mem_intf_bram_data_out(7 downto 0);
                        when "10" => in_port <= status_in_buf;
                        when "11" => in_port <= recv_data_in;
                        when others => in_port <= (others => '0');
                    end case;  
                    
                when '1' =>
                    case worker_idx is
                        when 0 => in_port <= hash_iterator_a_in(7 downto 0);
                        when 1 => in_port <= hash_iterator_a_in(15 downto 8);
                        when 2 => in_port <= hash_iterator_a_in(23 downto 16);
                        when 3 => in_port <= hash_iterator_a_in(31 downto 24);
                        
                        when 4 => in_port <= hash_iterator_b_in(7 downto 0);
                        when 5 => in_port <= hash_iterator_b_in(15 downto 8);
                        when 6 => in_port <= hash_iterator_b_in(23 downto 16);
                        when 7 => in_port <= hash_iterator_b_in(31 downto 24);
                        
                        when 8 => in_port <= hash_iterator_c_in(7 downto 0);
                        when 9 => in_port <= hash_iterator_c_in(15 downto 8);
                        when 10 => in_port <= hash_iterator_c_in(23 downto 16);
                        when 11 => in_port <= hash_iterator_c_in(31 downto 24);
                        
                        when 12 => in_port <= hash_iterator_d_in(7 downto 0);
                        when 13 => in_port <= hash_iterator_d_in(15 downto 8);
                        when 14 => in_port <= hash_iterator_d_in(23 downto 16);
                        when 15 => in_port <= hash_iterator_d_in(31 downto 24);
                        
                        when 16 => in_port <= hash_iterator_e_in(7 downto 0);
                        when 17 => in_port <= hash_iterator_e_in(15 downto 8);
                        when 18 => in_port <= hash_iterator_e_in(23 downto 16);
                        when 19 => in_port <= hash_iterator_e_in(31 downto 24);
                        
                        when 20 => in_port <= hash_iterator_f_in(7 downto 0);
                        when 21 => in_port <= hash_iterator_f_in(15 downto 8);
                        when 22 => in_port <= hash_iterator_f_in(23 downto 16);
                        when 23 => in_port <= hash_iterator_f_in(31 downto 24);
                      
                        when 24 => in_port <= hash_iterator_g_in(7 downto 0);
                        when 25 => in_port <= hash_iterator_g_in(15 downto 8);
                        when 26 => in_port <= hash_iterator_g_in(23 downto 16);
                        when 27 => in_port <= hash_iterator_g_in(31 downto 24);
                        
                        when 28 => in_port <= hash_iterator_h_in(7 downto 0);
                        when 29 => in_port <= hash_iterator_h_in(15 downto 8);
                        when 30 => in_port <= hash_iterator_h_in(23 downto 16);
                        when 31 => in_port <= hash_iterator_h_in(31 downto 24);
                        
                        when others => in_port <= (others => '0');
                    end case;
                
                when others => in_port <= (others => '0');
            end case;
        end if;
    end process input_ports;
end Behavioral;
