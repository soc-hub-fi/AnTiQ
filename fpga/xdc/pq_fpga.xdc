################################################################################
##                                                                            ##
##      MMP""MM""YMM `7MMF'`7MMM.     ,MMF'`7MMF'`7MN.   `7MF' .g8"""bgd      ##
##      P'   MM   `7   MM    MMMb    dPMM    MM    MMN.    M .dP'     `M      ##
##           MM        MM    M YM   ,M MM    MM    M YMb   M dM'       `      ##
##           MM        MM    M  Mb  M' MM    MM    M  `MN. M MM               ##
##           MM        MM    M  YM.P'  MM    MM    M   `MM.M MM.    `7MMF'    ##
##           MM        MM    M  `YM'   MM    MM    M     YMM `Mb.     MM      ##
##         .JMML.    .JMML..JML. `'  .JMML..JMML..JML.    YM   `"bmmmdPY      ##
##                                                                            ##
################################################################################

# timing constraints derived from clocking wizard IP
# create_clock -add -name clk_100MHz -period 10.00 -waveform {0 5} [get_ports { clk_i }];

################################################################################
##                                                                            ##
##                          '7MMF'     .g8""8q.                               ##
##                            MM     .dP'    `YM.                             ##
##                            MM     dM'      `MM                             ##
##                            MM     MM        MM                             ##
##                            MM     MM.      ,MP                             ##
##                            MM     `Mb.    ,dP'                             ##
##                          .JMML.     `"bmmd"'                               ##
##                                                                            ##
################################################################################

## CLK -------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN AY23 IOSTANDARD LVDS} [get_ports clk_i_n];
set_property -dict {PACKAGE_PIN AY24 IOSTANDARD LVDS} [get_ports clk_i_p];

## RST ----------------------------------------------
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS12} [get_ports rst_ni];