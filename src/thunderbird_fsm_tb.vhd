--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture tb of thunderbird_fsm_tb is

    ----------------------------------------------------------------------
    -- 1) Test Bench Constants
    ----------------------------------------------------------------------
    constant c_CLK_PERIOD : time := 10 ns;

    ----------------------------------------------------------------------
    -- 2) Signals for Connecting to the UUT
    ----------------------------------------------------------------------
    signal s_clk       : std_logic := '0';
    signal s_reset     : std_logic := '0';
    signal s_left      : std_logic := '0';
    signal s_right     : std_logic := '0';
    signal s_lights_L  : std_logic_vector(2 downto 0);
    signal s_lights_R  : std_logic_vector(2 downto 0);

begin

    ----------------------------------------------------------------------
    -- 3) Clock Generation Process
    ----------------------------------------------------------------------
    p_clk_gen : process
    begin
        while true loop
            s_clk <= '0';
            wait for c_CLK_PERIOD/2;
            s_clk <= '1';
            wait for c_CLK_PERIOD/2;
        end loop;
        wait;
    end process p_clk_gen;

    ----------------------------------------------------------------------
    -- 4) Instantiate the thunderbird_fsm
    ----------------------------------------------------------------------
    UUT : entity work.thunderbird_fsm
        port map (
            i_clk      => s_clk,
            i_reset    => s_reset,
            i_left     => s_left,
            i_right    => s_right,
            o_lights_L => s_lights_L,
            o_lights_R => s_lights_R
        );

    ----------------------------------------------------------------------
    -- 5) Test Stimulus Process
    ----------------------------------------------------------------------
    p_stimulus : process
    begin
        report "Starting Thunderbird FSM test bench..." severity note;

        ------------------------------------------------------------------
        -- Test #1: Check Reset Behavior
        ------------------------------------------------------------------
        s_reset <= '1';
        wait for 2 * c_CLK_PERIOD;  
        s_reset <= '0';
        wait for c_CLK_PERIOD;

        assert (s_lights_L = "000" and s_lights_R = "000")
            report "ERROR: Lights not OFF after reset!"
            severity error;

        ------------------------------------------------------------------
        -- Test #2: Left Turn Signal
        ------------------------------------------------------------------
        s_left  <= '1';
        wait for (2 * c_CLK_PERIOD);

        assert (s_lights_L = "100")
            report "ERROR: First left state not as expected!"
            severity error;

        wait for (2 * c_CLK_PERIOD);
        
        assert (s_lights_L = "110")
            report "ERROR: Second left state not as expected!"
            severity error;

        wait for (2 * c_CLK_PERIOD);
        assert (s_lights_L = "111")
            report "ERROR: Third left state not as expected!"
            severity error;

        wait for (2 * c_CLK_PERIOD);
        assert (s_lights_L = "000")
            report "ERROR: Did not return to OFF after finishing left sequence!"
            severity error;

        s_left <= '0';
        wait for (2 * c_CLK_PERIOD);

        ------------------------------------------------------------------
        -- Test #3: Hazard Condition (Both Left and Right)
        ------------------------------------------------------------------
        s_left  <= '1';
        s_right <= '1';
        wait for (5 * c_CLK_PERIOD);

        assert (s_lights_L = "111" and s_lights_R = "111")
            report "ERROR: Hazard lights not all ON!"
            severity error;

        wait for (4 * c_CLK_PERIOD);

        s_left  <= '0';
        s_right <= '0';
        wait for (3 * c_CLK_PERIOD);

        ------------------------------------------------------------------
        -- End Test
        ------------------------------------------------------------------
        report "Thunderbird FSM test bench complete. Check waveforms for detail." severity note;
        wait;
    end process p_stimulus;

end architecture tb;
