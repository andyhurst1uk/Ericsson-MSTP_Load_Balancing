#####################################################################
# This is a generic config file that is valid for both the CIST test
# or the 14 x MSTIs version of the test, the variation on the test
# is set by the parameter cTEST_OPTION 
#####################################################################

global errorInfo
set cSAMPLE_PERIOD                  60000
set cSAMPLE_RATE                    30000
set cDUT_HOSTNAME(1)		    10.44.3.145  	;# DUT1 Hostname
set cDUT_HOSTNAME(2)		    10.44.3.146  	;# DUT2 Hostname
set cCHASSIS_IP                     "10.44.3.136"       ;# IP address of Ixia chassis
set cHPUX_HOSTNAME                  "137.58.37.112"     ;# IP address for MV36
set cTOLERANCE                      1.0                 ;# in percentage
set cFAILING_FRAMES_ONLY            1                   ;# If 0, all frames in log 
set cNEID                           1
set cTRAFFIC_RATE                   60
set cTRAFFIC_PRIORITY_HI            5
set cFRAMESIZE                      1000
set cITERATIONS                     5
set cOMS1410Config                  1
set cMSTPConfig                     1
set cMSTI_COUNT                     16          ;# 16, 32 or 64
set cIXIA_CONFIG                    0
set cSTREAMSPERPORT                 [expr $cMSTI_COUNT / 4]
set cTARGET                         [expr 2367.68 / $cMSTI_COUNT]       ;# in Mbits/sec 147.98
set cTEST_NAME                      "OMS1410 MSTP Load Balancing Test"
set cSCRIPT_VERSION                 "v1.0"
set cUSER_NAME                      $env(USERNAME)
## Get the software build for remote regression testing only
if {[info exists env(ABAT_BUILD_ZIP_NAME)]} {
    set cSUT  $env(ABAT_BUILD_ZIP_NAME)
} else {
    set cSUT  "SW_Version_Unknown"
}
#####################################################################
# List to set Ixia chassis - including ch ca po name and DA and SA
#####################################################################

set cIXIAPORTLIST   [list   "TX_1 1 1 1" \
                            "TX_2 1 1 2" \
                            "TX_3 1 1 3" \
                            "TX_4 1 1 4" \
                            "RX_1 1 2 1" \
                            "RX_2 1 2 2" \
                            "RX_3 1 2 3" \
                            "RX_4 1 2 4"]

#####################################################################
# Variables for switching function on or off
#####################################################################

set		cLOGGING				    1			;# 0 Output to screen, 1 output to a file
set		cCONFIG_IXIA			    1			;# 0 Will not configure the Ixia chassis, 1 will configure the chassis
set		cCONFIG_DUT 			    1			;# 0 Will not configure the DUT, 1 will configure the DUT
set     cMAINTAIN_NEXT_CONNECTID    0           ;# To dertmine the next id number is saved in the txt file created in 14xxSETAllConnections
#####################################################################
# Parameters for the log header.
#####################################################################

set cCONFIGURATION    		"MSTP load balancing"
set	cSCRIPT_NAME			MSTP_Load_Balancing
set cSCRIPT_DESCRIPTION   	"\nTo run a run a provacative test to determine load balancing capability \n"	;# Name of the script
set cTEST_PURPOSE 			"To exercise the 14xx functionality"
set	cTEST_SUITE				"Ixia - Optixia X16"										;# Name of the test suite
set cTEST_TEAM				"System Proving"
set cDUT_NAME 				"OMS16xx"
set cDUT_VERSION 			"Release 3.0.1"

#####################################################################
# Define the mapping between virtual ports and bridge ports
#####################################################################
set VIRTUAL_PORT_MAP_GET(1) {0 0 1 5-5 2 5-6 3 5-7 4 5-8 5 5-11 6 5-12 7 5-13 8 5-14 9 5-15 10 5-16 11 5-17 12 5-18 13 5-19 14 5-20 15 5-21 16 5-22 17 5-23 18 5-24 19 5-25 20 5-26}
set VIRTUAL_PORT_MAP_GET(2) {0 0 1 5-1 2 5-2 3 5-3 4 5-4 5 5-11 6 5-12 7 5-13 8 5-14 9 5-15 10 5-16 11 5-17 12 5-18 13 5-19 14 5-20 15 5-21 16 5-22 17 5-23 18 5-24 19 5-25 20 5-26}

set VIRTUAL_PORT_MAP_SET(1) {0 0 1 5-5 2 5-6 3 5-7 4 5-8 5 5-11 6 5-12 7 5-13 8 5-14 9 5-15 10 5-16 11 5-17 12 5-18 13 5-19 14 5-20 15 5-21 16 5-22 17 5-23 18 5-24 19 5-25 20 5-26}
set VIRTUAL_PORT_MAP_SET(2) {0 0 1 5-1 2 5-2 3 5-3 4 5-4 5 5-11 6 5-12 7 5-13 8 5-14 9 5-15 10 5-16 11 5-17 12 5-18 13 5-19 14 5-20 15 5-21 16 5-22 17 5-23 18 5-24 19 5-25 20 5-26}