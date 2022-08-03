################################################################################
#   NAME:       14xx_MSTP_Load_Balancing_r01_exec.tcl
#
#   VERSION:    1.0 draft a
#
#	DATE:		01/11/07
#
#   AURTHOR:    David Stothert / Andy Hurst
#
#   USAGE:      MSTP_Load_Balancing_r01_exec.tcl <file.csv>
#
#   PURPOSE:	To check the load balancing of an MSTI network between 2 1410s,
#				implemented by configuring a network of 2 1400 bridges. Each
#				bridge with 4 ports connected to 4 Ixia transmit ports
#				containing 4 VLANs (2 each priority 0 and 7). VLAN mapping to
#				MSTI configuration so that 2 4VC 8V SDH links each contain equal
#				value priority VLANs then output via 4 bridge ports to 4 Ixia
#				chassis ports. The test will then perfom the provocative action
#				of removing each link to check for 50% traffic on the Ixia ports
#				and recieving priority 7 traffic only.
#       
################################################################################

# Display and modify the console.  The catch is necessary in case this script is
# run in a tclsh in which case errors will be generated and will cause the
# script to terminate.
console show
console title "MSTP 1410 Load Balancing testing"
console eval {wm geometry . 101x35+430+1}
console eval { .console delete 1.0 end }
wm withdraw .

# Update paths for Ixia libraries including the IxTclHal API
set env(IXTCLHAL_LIBRARY) "C:/Program Files/Ixia/TclScripts/lib/IxTcl1.0"
lappend auto_path "C:/Program Files/Ixia/"
lappend auto_path "C:/Program Files/Ixia/TclScripts/lib/IxTcl1.0"
append env(PATH) ";C:/Program Files/Ixia/"


################################################################################
# Source the necessary common functions and configuration files
################################################################################
set 	eSCRIPT_DIR [file dirname [info script]]

source	[file join $eSCRIPT_DIR . Include common-functions-log.tcl]
source	[file join $eSCRIPT_DIR . Include common-functions.tcl]
source	[file join $eSCRIPT_DIR . Include utilities.tcl]
source	[file join $eSCRIPT_DIR . Include SDHCommonLibrary.tcl]
source	[file join $eSCRIPT_DIR . Include 14xxCommonLibrary.tcl]
source	[file join $eSCRIPT_DIR . Include XMLRPC.tcl]
source	[file join $eSCRIPT_DIR . MSTPInclude MstpCommonLibrary.tcl]
source	[file join $eSCRIPT_DIR . MSTPInclude 14xxMstpLibrary.tcl]
source	[file join $eSCRIPT_DIR 14xx_MSTP_load_balancing_Config_r01a.tcl]
source	[file join $eSCRIPT_DIR 14xx_MSTP_load_balancing_Lib_r01a.tcl]

### Update paths for Ixia libraries including the IxTclHal API
set env(IXTCLHAL_LIBRARY) "C:/Program Files/Ixia/IxOS/5.20-GA/TclScripts/lib/ixTcl1.0"
lappend auto_path "C:/Program Files/Ixia/"
lappend auto_path "C:/Program Files/Ixia/IxOS/5.20-GA/TclScripts/lib/IxTcl1.0"
append env(PATH) ";C:/Program Files/Ixia/"
source "C:/Program Files/Ixia/IxOS/5.20-GA/TclScripts/bin/IxiaWish.tcl"

set testSetSw "IxTclHal version [package require IxTclHal]"
package require http
package require tdom

################################################################################
# Log file details
################################################################################

# Switch on/off logging to file. Would like to remove this eventually
set cLOGGING	1	;# 1 - Enable logging / 0 - Disable logging

# Generate log filename and directory
regexp {(\w+)_(\w+)_(\w+)} $::cSUT swVersion SwInfo3 swInfo2 SUTlogHeader
set TIME 	"[string map {/ -} [clock format [clock seconds] -format %y/%m/%d]].[string map {: -} [clock format [clock seconds] -format %T]]"

set eLOGS_DIR 	[file join $eSCRIPT_DIR .. .. Report $SUTlogHeader "report.MSTPLoadBalancing.$TIME.$SUTlogHeader"]
file mkdir $eLOGS_DIR

set eSEQ_LOG	[file join $eSCRIPT_DIR .. .. Log "sequence.MSTPLoadBalancing.$TIME.$SUTlogHeader\.txt"]

set eREP_LOG	[file join $eSCRIPT_DIR .. .. Report $SUTlogHeader report.MSTPLoadBalancing.$TIME.$SUTlogHeader "report.MSTPLoadBalancing.$TIME.$SUTlogHeader\.txt"]

################################################################################
# Load Expect extension
################################################################################
package require Expect

exp_log_user 			    0	;# Turn on/off echo logging to the user
set		::exp::winnt_debug  1	;# Show the controlled console
set		timeout             180	;# Expect timeout parameter set to 15 seconds

################################################################################
# MAIN
################################################################################
set cDEBUG      0

#----------------------------
# Declaring global variables
#----------------------------

# Define the valid equipment types currently supported by MSTP test scripts
set MSTP_EQUIP_TYPES {DS20Q DS20AD CISCO OMS1410}
set 14xx_CONNECT 1  	;# 1 - Connect to DS20 via snmp, 0 - use captured logs
set EXPORT_RESPONSE	0   ;# 1 - Export snmp responses, 0 - do not export.
set dut_port 8080
set http_protocol "http"
set XMLVersion "1.0"
#set assignedNumRoot [XMLRPC_XmlParseNumbers ./AssignedNumbers.xml]
set assignedNumRoot [XMLRPC_XmlParseNumbers AssignedNumbers.xml]
##set assignedNumRoot [XMLRPC_XmlParseNumbers AssignedNumbersPenguin.xml]
set FILENAMES {	1 macAddress
				2 configName
				3 configRevision
				4 configDigest
				5 inst
				6 instPri
				7 instDesRoot
				8 instRootPathCost
				9 instRootPort
				10 bridgePorts
				11 instIfDesRoot
				12 instIfDesBridge
				13 instDesIfPri
				14 instDesIfPort
				15 instIfState
				16 instIfRole
				17 instIfPri
				18 instIfCost}

array set EXPORT_FILENAMES $FILENAMES

set EXPORT_DIR [file join $eSCRIPT_DIR Capture]
array unset Results

###############################################################################################
##  Display Standard Report Header

set quickTestfSw "N/A"
##set sut "oms1410 release: [14xxGetSoftwareVersion $::cDUT_HOSTNAME(1)]"
set startTimeSec [clock format [clock seconds] -format "%s"]
GenerateStandardReportHeader $::cTEST_NAME $::cSCRIPT_VERSION $testSetSw $quickTestfSw $::cUSER_NAME $swVersion
###############################################################
### Configure all 14xx cards
###############################################################


if {$::cMSTI_COUNT == 64} {
	set filename "Load_Balancing_14xxConfigFile_64MSTI.tcl"
}
if {$::cMSTI_COUNT == 32} {
	set filename "Load_Balancing_14xxConfigFile_32MSTI.tcl"
}
if {$::cMSTI_COUNT == 16} {
	set filename "Load_Balancing_14xxConfigFile_16MSTI.tcl"
}

set filename [file join $eSCRIPT_DIR Config_Files $filename]

## Apply OMS1410 & MSTP Configurations
if {$::cOMS1410Config == 1} {
	if { [catch {14xxApplyConfiguration $filename} ] } {
		global errorInfo
		Mputs "$errorInfo" -c -s
		exit 1
	}
}

###############################################################
## Configure the MSTP network
###############################################################
Mputs "===================================" -c -s
Mputs "MSTP BASELINE NETWORK CONFIGURATION" -c -s
Mputs "===================================\n" -c -s
Mputs "\tTesting for $::cMSTI_COUNT MSTIs\n" -c -s

if {$::cMSTI_COUNT == 64 && $::cMSTPConfig == 1} {
	# 64 MSTIs for 138.58.12.89
	set filename "Load_Balancing_MstpBaselineConfig_1410_64MSTI_Bridge1.csv"
	set filename [file join $eSCRIPT_DIR Config_Files $filename]
	if {[catch {MstpConfigureNetwork bridge1.csv $filename networkMSTPdB -force}]} {
		global errorInfo
		Mputs $errorInfo -c -s
		exit 1
	}
	# 64 MSTIs for 138.58.12.90
	set filename "Load_Balancing_MstpBaselineConfig_1410_64MSTI_Bridge2.csv"
	set filename [file join $eSCRIPT_DIR Config_Files $filename]
	if {[catch {MstpConfigureNetwork bridge2.csv $filename networkMSTPdB -force}]} {
		global errorInfo
		Mputs $errorInfo -c -s
		exit 1
	}
}
if {$::cMSTI_COUNT == 32 && $::cMSTPConfig == 1} {
	set filename "Load_Balancing_MstpBaselineConfig_1410_32MSTI_Bridge1.csv"
	set filename [file join $eSCRIPT_DIR Config_Files $filename]
	if {[catch {MstpConfigureNetwork bridge1.csv $filename networkMSTPdB -force}]} {
		global errorInfo
		Mputs $errorInfo -c -s
		exit 1
	}
	set filename "Load_Balancing_MstpBaselineConfig_1410_32MSTI_Bridge2.csv"
	set filename [file join $eSCRIPT_DIR Config_Files $filename]
	if {[catch {MstpConfigureNetwork bridge2.csv $filename networkMSTPdB -force}]} {
		global errorInfo
		Mputs $errorInfo -c -s
		exit 1
	}
}

if {$::cMSTI_COUNT == 16 && $::cMSTPConfig == 1} {
	set filename "Load_Balancing_MstpBaselineConfig_1410.csv"
	set filename [file join $eSCRIPT_DIR Config_Files $filename]
	if {[catch {MstpConfigureNetwork bridges.csv $filename networkMSTPdB -force}]} {
		global errorInfo
		Mputs $errorInfo -c -s
		exit 1
	}
}

##############################################################
# IXIA CHASSIS CONFIGURATION
##############################################################

Mputs "==========================" -c -s
Mputs "IXIA CHASSIS CONFIGURATION" -c -s
Mputs "==========================\n" -c -s

# Apply configuration to the Ixia chassis


	if {[catch {SetupIxiaStreams $::cMSTI_COUNT}]} {
		Mputs $errorInfo -c -s
		exit 1
	}
	after 5000

	
	# Select a list of Ixia transmit ports 
	set txPortList ""
		foreach ports [lsort $::cIXIAPORTLIST] {
			regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $ports trash RXTX  num ch ca po
			set txPortList [ concat $txPortList \{$ch $ca $po\} ]
		}


### Set the number of times to run the complete test ###
for {set k 1} {$k <= $::cITERATIONS} {incr k} {

	##############################################################
	# Start transmit on all ports  
	##############################################################
	
	if {[catch {StartTransmit $txPortList}]} {
		Mputs $errorInfo -c -s
		exit 1
	}
	##############################################################
	# Set up Ixia reporting on all ports  
	##############################################################
	
	if {[catch {SetupIxiaReporting }]} {
		Mputs $errorInfo -c -s
		exit 1
	}
	after 20000
	##############################################################
	# PROVOCATIVE SECTION OF THE TEST
	##############################################################
		
	Mputs "===============================" -c -s
	Mputs "PROVOCATIVE SECTION OF THE TEST" -c -s
	Mputs "===============================\n" -c -s	
	Mputs "\tTesting Iteration $k of $::cITERATIONS" -c -s -r
	Mputs "\t-----------------------" -c -s
	Mputs "\n\tTesting Pre-start conditions..." -s -c
	
	set eLEVEL {Pre-Start Link_A_down Link_A+B_up Link_B_down Link_A+B_up2}
	
	# Pre provocative phase to check traffic before starting
	if {[catch {DataRetrieval Pre-Start resultsLog}]} {
			Mputs $errorInfo -c -s
			exit 1
		}
	
	# Provocavtive section of test
	##set port 1
	set LANWANType SDHPort
	
	# source the IP of the DUT via the file: Load_Balancing_14xxconfig.tcl 
	set filename "Load_Balancing_14xxConfigFile_16MSTI.tcl"
	source [file join $eSCRIPT_DIR Config_Files $filename]
	 
	# Reteive the slot numbers where STM cards are located from the list cCARD_LIST(1):
	#set i 1
	#foreach cardList $cCARD_LIST(1) {
	#	Mputs "\n\tcardList $cardList" -s -c
	#	if {[regexp STM [lindex $cardList 1] trash]} {
	#	set slot$i [lindex $cardList 1]
	#	incr i 
	#	}
	#}
	# For 14xx laserstate down is adminState down, where value 1 = in service and
	# value 2 = out of service. Slots refer to bridge 1 only (makes no difereence
	# either bridge will bring the link down)
	
	foreach adminState $eLEVEL {

		if {$adminState == "Link_A_down"} {
			set value 2
            set slot [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 0] 0]
            set port [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 0] 1]
		} elseif {$adminState == "Link_A+B_up"} {
			set value 1
			set slot [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 0] 0]
            set port [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 0] 1]
		} elseif {$adminState == "Link_B_down"} {
			set value 2
			set slot [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 1] 0]
            set port [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 1] 1]
		} elseif {$adminState == "Link_A+B_up2"} {
			set value 1
			set slot [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 1] 0]
            set port [lindex [lindex $cSDHCARDINTERFACES_LIST(1) 1] 1]
		} else {
			continue
		}
		
		Mputs "\n\tTesting with $adminState" -s -c
		#login
		
		# Login required to get a session id for the proc 14xxSetPortAdminStatus
		if {[catch {14xxLogIn $cDUT_HOSTNAME(1)} sessionID]} {
			Mputs $errorInfo -c -s
			exit 1
		}  
			if {[catch {14xxSetPortAdminStatus $sessionID $cDUT_HOSTNAME(1) $slot $port $value $LANWANType}]} {
			Mputs $errorInfo -c -s
			
			exit 1
		}
		Mputs "\t$cDUT_HOSTNAME(1) slot: $slot , port: $port" -c -s

		# associated logout to the previous login
		if {[catch {14xxLogOut $sessionID $cDUT_HOSTNAME(1)}]} {
			Mputs $errorInfo -c -s
			exit 1
		}
		# Check data retrieval ok
		if {[catch {DataRetrieval $adminState resultsLog}]} {
			Mputs $errorInfo -c -s
			exit 1
		}
		
	}

	##############################################################
	# Stop transmit on Ixia ports
	##############################################################
	
	if {[catch {StopTransmit $txPortList}]} {
		
		Mputs $errorInfo -c -s
		exit 1
	}

	##############################################################
	# Output total results
	##############################################################
	
	Mputs "\n\nThe provocative section has now ended. The results will now be processed" -c -s
	if {!$::cFAILING_FRAMES_ONLY} {
		Mputs "\nYou have disabled PASS reporting, only FAIL will be reported in the log!!" -c -s
	}
	Mputs "\n"
	if {[catch {ResultsCheckerandLogOutput resultsLog}]} {
		
		Mputs $errorInfo -c -s
		exit 1
	}
}

Mputs "\n"
#if {[catch {ResultsSummary resultsLog}]} {
		
#	Mputs $errorInfo -c -s
#	exit 1
#}

###### The end of the test ######
GenerateStandardReportFooter $startTimeSec
exit

