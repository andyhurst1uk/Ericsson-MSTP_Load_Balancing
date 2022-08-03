
#####################################################################
#   Configure the Ixia Chassis with as many ports as in cIXIAPORTLIST
#####################################################################

proc SetupIxiaStreams {MSTIs} {
            
    ixConnectToChassis      $::cCHASSIS_IP
    ixLogin                 $::cUSER_NAME

    set VID 100
    foreach ports [lsort $::cIXIAPORTLIST] {
        regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $ports trash RXTX  num chassis card port
                        
        ixPortTakeOwnership $chassis $card $port force
        
        if {$VID == [expr 100 + $MSTIs]} {
                set VID 100
        }
                                     
        if {$RXTX == "TX"} {
                set sourceAddress       "00 00 00 01 0$num 01"
                set destAddress         "00 00 00 01 0$num 02" 
        } elseif {$RXTX == "RX"} {
                set sourceAddress       "00 00 00 01 0$num 02"
                set destAddress         "00 00 00 01 0$num 01" 
        }
                       
        ######### Card Type : 10/100/1000 STXS4-256MB ############

        card                         setDefault        
        card                         set               $chassis $card
        card                         write             $chassis $card
        
        ######### Chassis-10.243.123.25 set to $Chassis $Card $Port #########
        
        port                         setFactoryDefaults $chassis $card $port
        port                         setPhyMode        $::portPhyModeCopper $chassis $card $port
        port                         config            -receiveMode                        [expr $::portPacketGroup|$::portRxSequenceChecking]
        port                         config            -autonegotiate                      true
        port                         config            -advertise1000FullDuplex            true
        port                         config            -negotiateMasterSlave               1
        port                         set               $chassis $card $port
        stat                         setDefault        
        stat                         config            -enableBgpStats                     false
        stat                         config            -enableOspfStats                    false
        stat                         config            -enableIsisStats                    false
        stat                         config            -enableRsvpStats                    false
        stat                         config            -enableLdpStats                     false
        stat                         config            -enableIgmpStats                    false
        stat                         config            -enableOspfV3Stats                  false
        stat                         config            -enablePimsmStats                   false
        stat                         config            -enableMldStats                     false
        stat                         config            -enableStpStats                     false
        stat                         config            -enableEigrpStats                   false
        stat                         set               $chassis $card $port
        packetGroup                  setDefault        
        packetGroup                  setRx             $chassis $card $port
        ipAddressTable               setDefault        
        ipAddressTable               set               $chassis $card $port
        
        interfaceTable               select            $chassis $card $port
        interfaceTable               setDefault        
        interfaceTable               set               
        interfaceTable               clearAllInterfaces 
        protocolServer               setDefault        
        protocolServer               set               $chassis $card $port
        
        flexibleTimestamp            setDefault        
        flexibleTimestamp            set               $chassis $card $port
        
        capture                      setDefault        
        capture                      set               $chassis $card $port
        filter                       setDefault        
        filter                       config            -captureTriggerFrameSizeFrom        12
        filter                       config            -captureTriggerFrameSizeTo          12
        filter                       config            -captureFilterFrameSizeFrom         12
        filter                       config            -captureFilterFrameSizeTo           12
        filter                       config            -userDefinedStat1FrameSizeFrom      12
        filter                       config            -userDefinedStat1FrameSizeTo        12
        filter                       config            -userDefinedStat2FrameSizeFrom      12
        filter                       config            -userDefinedStat2FrameSizeTo        12
        filter                       config            -asyncTrigger1FrameSizeFrom         12
        filter                       config            -asyncTrigger1FrameSizeTo           12
        filter                       config            -asyncTrigger2FrameSizeFrom         12
        filter                       config            -asyncTrigger2FrameSizeTo           12
        filter                       set               $chassis $card $port
        filterPallette               setDefault        
        filterPallette               set               $chassis $card $port
        lappend                      portList          [list $chassis $card $port]
        
        ixWritePortsToHardware       portList                   
        set streamId 1   
        for {set i 1} {$i <= [expr $MSTIs / 4]} {incr i} {               
            #  Stream 1 config ############################################################################################################################
            stream                       setDefault        
            stream                       config            -name                               "$RXTX $VID"
            stream                       config            -numFrames                          1
            stream                       config            -ifg                                5640.0
            stream                       config            -ifgMIN                             1920.0
            stream                       config            -ifgMAX                             2560.0
            stream                       config            -ibg                                5640.0
            stream                       config            -isg                                5640.0
            stream                       config            -percentPacketRate                  $::cTRAFFIC_RATE
            stream                       config            -fpsRate                            85324.2320819
            stream                       config            -bpsRate                            46416382.2526
            stream                       config            -sa                                 "$sourceAddress"
            stream                       config            -da                                 "$destAddress"
            stream                       config            -framesize                          $::cFRAMESIZE
            stream                       config            -frameSizeMIN                       $::cFRAMESIZE
            stream                       config            -frameSizeMAX                       $::cFRAMESIZE
            stream                       config            -frameType                          "FF FF"
            stream                       config            -numDA                              16
            stream                       config            -numSA                              16

            if {$i == [expr $MSTIs / 4]} {
                stream                   config            -dma                                gotoFirst
            } else {
                stream                   config            -dma                                advance
            }
            stream                       config            -asyncIntEnable                     true
            protocol                     setDefault        
            protocol                     config            -enable802dot1qTag                  vlanSingle
            
            vlan                         setDefault        
            vlan                         config            -vlanID                             $VID
            if {![expr $i%2]} {
                vlan                         config            -userPriority                       $::cTRAFFIC_PRIORITY_HI
                vlan                         config            -maskval                            "1110XXXXXXXXXXXX"
            }
            vlan                         set               $chassis $card $port
            
            if {[port isValidFeature $chassis $card $port $::portFeatureTableUdf]} { 
                tableUdf setDefault
                tableUdf clearColumns
                tableUdf set $chassis $card $port
            }
                            
            if {[port isValidFeature $chassis $card $port $::portFeatureRandomFrameSizeWeightedPair]} { 
                weightedRandomFramesize setDefault
                weightedRandomFramesize set $chassis $card $port
            }
            
            stream                       set               $chassis $card $port $streamId
            packetGroup                  setDefault        
            packetGroup                  config            -insertSignature                    true
            packetGroup                  config            -groupId                            $streamId
            packetGroup                  setTx             $chassis $card $port $streamId
            incr                         streamId 
            incr                         VID
        }
    ixWriteConfigToHardware      portList          -noProtocolServer
    }
ixCheckLinkState             portList 
}


###############################################################
# Set the total sampling period and the sampling rate within it
###############################################################

proc DataRetrieval {laserstate resultsLog} {
    upvar 1 $resultsLog results
    set iteration 0
    set total $::cSAMPLE_RATE
    
    while {$total <= $::cSAMPLE_PERIOD} {
    ##### "AFTER" to create delay between samples
        after $::cSAMPLE_RATE
        incr iteration 1
        ixPuts -nonewline ".."   
        set results($laserstate,iterNum) $iteration
        foreach port $::cIXIAPORTLIST {
            regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $port trash RXTX  num ch ca po
            if {$RXTX == "RX"} {
                get_port_stats $ch $ca $po $iteration results $laserstate
            }
        }
        set total [mpexpr $total + $::cSAMPLE_RATE]
        set results($laserstate,totalTime) $total
    }
}
#########################################################################
# Find the received bit rates
#########################################################################

proc get_port_stats {ch ca po iteration resultsLog laserstate} {
        upvar 1 $resultsLog results
        packetGroupStats get $ch $ca $po 0 $::cSTREAMSPERPORT
        after 500
        packetGroupStats get $ch $ca $po 0 $::cSTREAMSPERPORT
        for {set groupID 1} {$groupID <= $::cSTREAMSPERPORT} {incr groupID} {
                
            packetGroupStats getGroup $groupID
            #set packetgroupstats [packetGroupStats getGroup $groupID]
            #Mputs "$packetgroupstats" -c -s 
            set results(res_$laserstate,$iteration,$po,$groupID) [mpexpr [packetGroupStats cget -bitRate]/(1000000*1.0)]
            set readTimeStamp [packetGroupStats cget -readTimeStamp]
            set results(res_$laserstate,$iteration,$po,$groupID,timing) [mpexpr ($readTimeStamp/(1000000000000*0.1)*0.1)]
            #Mputs "$results(res_$laserstate,$iteration,$po,$groupID,timing)" -c -s 
        }
}
#########################################################################
# Takes the results array, calculates and outputs the results to the log
#########################################################################

proc ResultsCheckerandLogOutput {resultsLog} {
    Mputs "============" -c -s
    Mputs "TEST RESULTS" -c -s
    Mputs "============" -c -s    
    set LEVEL {Pre-Start Link_A_down Link_A+B_up Link_B_down Link_A+B_up2}
    upvar 1 $resultsLog results
      
    foreach adminState $LEVEL {
        set results($adminState,P_F) PASS
        switch $adminState {
                Pre-Start {set adminStateTitle "Pre-start"}
                Link_A_down {set adminStateTitle "Link A Down"}
                Link_A+B_up {set adminStateTitle "Link A and B Up"}
                Link_B_down {set adminStateTitle "Link B Down"}
                Link_A+B_up2 {set adminStateTitle "Link A and B Up pt.2"}
        }

        set title "$adminStateTitle Test Results"
        Mputs "\n\n\t$title" -c -s
        Mputs "\t[Underline [string length $title] -]\n" -c -s
        
        Mputs "\t[format %-6s Iter.] [format %-6s Port] [format %-6s PGID] [format %-17s "Rx rate (Mb/s)"] [format %-17s "Target (Mb/s)"] [format %-17s "Time"] Pass/fail" -c -s
        Mputs "\t-------------------------------------------------------------------------------------------" -c -s
   
        set results($adminState,failCount) 0
        set results($adminState,Count) 0
        for {set i 1} {$i <= $results($adminState,iterNum)} {incr i} {
  
            foreach PORT [lsort $::cIXIAPORTLIST] {
                regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $PORT trash RXTX  num chassis card port
                         
                if {$RXTX == "RX"} {
                    for {set groupID 1} {$groupID <= $::cSTREAMSPERPORT} {incr groupID} {
                        set recieveValue $results(res_$adminState,$i,$port,$groupID)
                        incr results($adminState,Count)
                        if {[expr $groupID%2] != 0 && ($adminState == "Link_A_down" || $adminState == "Link_B_down")} { 

                            set expectedRate 0
                            set TOLERANCE_HI [mpexpr 0 + $::cTARGET*($::cTOLERANCE/(100*1.0))]
                            set TOLERANCE_LO 0
                        } else {
                            set expectedRate $::cTARGET
                            set TOLERANCE_HI [mpexpr $::cTARGET + $::cTARGET*($::cTOLERANCE/(100*1.0))]
                            set TOLERANCE_LO [mpexpr $::cTARGET - $::cTARGET*($::cTOLERANCE/(100*1.0))]
                        }
                                            
                        if {$recieveValue > $TOLERANCE_HI} {
                            set results($adminState,P_F) FAIL
                            incr results($adminState,failCount)
                            Mputs "\t[format %-6s $i] [format %-6s $port] [format %-6s $groupID]\
                            [format %-17s $recieveValue] [format %-17s $expectedRate]\
                            [format %-17s $results(res_$adminState,$i,$port,$groupID,timing)] [format %-10s "Fail:Hi"]" -c -s
                        } elseif {$recieveValue < $TOLERANCE_LO} {
                            set results($adminState,P_F) FAIL
                            incr results($adminState,failCount)
                            Mputs "\t[format %-6s $i] [format %-6s $port] [format %-6s $groupID]\
                            [format %-17s $recieveValue] [format %-17s $expectedRate]\
                            [format %-17s $results(res_$adminState,$i,$port,$groupID,timing)] [format %-10s "Fail:Lo"]" -c -s
                        } else {
                            if {$::cFAILING_FRAMES_ONLY} {
                                Mputs "\t[format %-6s $i] [format %-6s $port] [format %-6s $groupID]\
                                [format %-17s $recieveValue] [format %-17s $expectedRate]\
                                [format %-17s $results(res_$adminState,$i,$port,$groupID,timing)] [format %-10s "Pass   "]" -c -s
                            }
                        }
                    }
                }
            }
        }
    }
    ########################################################################
    # Sunmmary of Results
    ########################################################################
    Mputs "\n\n" -c -s
    Mputs "\tTested under the following conditions:" -c -s
    Mputs "\tTraffic rate = $::cTRAFFIC_RATE 0 Mbit/sec" -c -s
    Mputs "\tTarget = $::cTARGET Mbit/sec" -c -s
    Mputs "\tTest period = [mpexpr ($::cSAMPLE_PERIOD/1000)] seconds" -c -s
    Mputs "\tSample rate = [mpexpr ($::cSAMPLE_RATE/1000)] seconds" -c -s
    Mputs "\tTraffic Priority (Hi) = $::cTRAFFIC_PRIORITY_HI" -c -s
    Mputs "\tTraffic Priority (Lo) = 0" -c -s
    Mputs "\tTolerance = $::cTOLERANCE %" -c -s
    Mputs "\n\n" -c -s
    Mputs "\tSummary of Results" -c -s -r
    Mputs "\t------------------" -c -s -r
    Mputs "\t[format %-15s Test] [format %-10s Status] [format %-10s Count] [format %-10s "Failed"]" -c -s -r
    Mputs "\t--------------------------------------------" -c -s -r
                       
        foreach adminState $LEVEL {
                               
                    if {$results($adminState,P_F) == "FAIL"} {
                        Mputs "\t[format %-15s $adminState] [format %-10s Fail] [format %-10d $results($adminState,Count)]\
                        [format %-10d $results($adminState,failCount)]" -c -s -r
                    } else {
                        Mputs "\t[format %-15s $adminState] [format %-10s Pass] [format %-10d $results($adminState,Count)] [format %-10d 0]" -c -s -r
                    }
        }
        Mputs "\n\n" -c -s -r
}

#########################################################
# This section is called to run the Ixia ports.
#It requires the list of RX and TX ports.
#########################################################

proc StartTransmit {txPortList} {
		
	global eSEQ_LOG eREP_LOG
	
	# Start the transmit
	Mputs "Starting transmit on ports:" -s -c
    Mputs "$txPortList " -s -c
	if {[ixStartTransmit txPortList]} {
		Mputs "Could not start transmit on $txPortList"  -s -c
	}
    Mputs "Completed" -s -c
}
#########################################################
# This section is called to run the Ixia ports.
#It require the l;ist of RX and TX ports.
#########################################################

proc StopTransmit {txPortList} {
		
	global eSEQ_LOG eREP_LOG

	# Stop the transmit
	Mputs "\nStop the transmit"  -s -c
	if {[ixStopTransmit txPortList]} {
		Mputs "Could not stop transmit on $txPortList"  -s -c
	}
	Mputs "Completed" -s -c
}

################################################################################
# The "SetupIxiaReporting" process takes the Port and Streams arrays and
# enables Packet Group Stats for those ports, this allows stats reporting
# on a per stream basis.
################################################################################

proc SetupIxiaReporting  {} {
    Mputs "\nStarting report procedure...." -s -c

    # Loops each port to turn on reporting
    foreach port $::cIXIAPORTLIST {
        regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $port trash RXTX  num ch ca po
        # Turning on the packet group reporting command
        
        if {[ixStartPortPacketGroups $ch $ca $po]} {
                
                
           return -code error -errorinfo "Unable to start the Packet group!"
        }
    }
    # 2 second delay to allow results to be populated to Ixia chassis
    after 2000
    Mputs "Completed" -s -c
    return 1
}

################################################################################
# The "ShutdownIxiaReporting" process takes the Port and Streams arrays and
# Disables Packet Group Stats for those ports, this allows stops reporting on
# specified streams.
################################################################################

proc ShutdownIxiaReporting {} {
        
# Loops each port to stop reporting

    foreach port $::cIXIAPORTLIST {
        regexp {(\w+)_(\d+) (\d+) (\d+) (\d+)} $port trash RXTX  num ch ca po
        # Stoping the packet group reporting command
        
        if {[ixStopPortPacketGroups $ch $ca $po]} {
                
                
           return -code error -errorinfo "Unable STOP the Packet group Stat!"
        }
    }
    
return 1
}
