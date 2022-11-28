set_global_assignment -entity "mypll2" -library "lib_mypll2" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "mypll2" -library "lib_mypll2" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "mypll2" -library "lib_mypll2" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_mypll2" -name SPD_FILE [file join $::quartus(sip_path) "mypll2.spd"]

set_global_assignment -library "lib_mypll2" -name MISC_FILE [file join $::quartus(sip_path) "mypll2_sim/mypll2.vo"]
