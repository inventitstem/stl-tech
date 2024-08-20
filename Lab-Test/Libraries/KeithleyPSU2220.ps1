#######################################################################################
# FILE NAME:         KeithleyPSU2220
# DESCRIPTION:       Reads data from the 2220 PSU and sets configuration data
# OWNER:             Thomas Wood
# USAGE NOTES:       - All changes should keep backwards compatibility unless absoloutley
#                     neccessary
#                    - CTRL + M to collapse all regions
# KNOWN BUGS:        None
# SERIAL PARAMETERS: Baudrate : 9600
#                    Parity   : None
#                    Databits : 8
#                    Stopbits : 1
#######################################################################################
#
# Read-PSU-Channel
#######################################################################################
# Description: Reads the output of the PSU
# Inputs:
#         $port              -> COM port object
#         $channel           -> PSU Output Channel. 1, 2, or 3.

function Read-PSU-Channel ([System.IO.Ports.SerialPort]$port, $channel){

    $data = New-Object -TypeName psobject

    $port.writeline("MEAS:VOLT:DC? CH$channel")
    $voltage = $port.readline()

    $data | Add-member -MemberType NoteProperty -Name Voltage -Value $voltage

    $port.writeline("MEAS:CURR:DC? CH$channel")
    $current = $port.readline()

    $data | Add-member -MemberType NoteProperty -Name Current -Value $current

    # READ CURRENT LIMITER VALUE

    $port.writeline("APPLY CH$channel")
    $port.writeline("SOURCE:OUTPUT:ENABLE?")
    $enable_state = $port.readline()

    $data | Add-member -MemberType NoteProperty -Name Enable -Value $enable_state

    return $data

}

# Write-PSU-Channel
#######################################################################################
# Description: Sets the output of the PSU.
# Inputs:
#         $port              -> COM port object
#         $channel           -> PSU Output Channel. 1, 2, or 3.
#         $voltage           -> Voltage for Channel. 1 and 2 can be max 30V, 3 can be max 5V
#         $current           -> Current mA
#         $enable            -> Enable = 1, Disable = 0

function Write-PSU-Channel ([System.IO.Ports.SerialPort]$port, $channel, $voltage, $current, $enable){

    $port.writeline("APPLY CH$channel")
    $port.writeline("SOURCE:OUTPUT:ENABLE 1")
    $port.writeline("VOLT $voltage")
    $port.writeline("CURR $current`mA")
    $port.writeline("SOURCE:OUTPUT:ENABLE $enable")
    $port.writeline("SOURCE:OUTPUT:ENABLE?")
    $eReturn = $port.readline()

    if($eReturn -eq 0){
        
        write-host Output Channel $channel Disabled. -ForegroundColor Red
        write-host ""

    }
    elseif($eReturn -eq 1){

        #write-host Output Channel $channel Enabled. V = $voltage`V I_limit = $current`mA -ForegroundColor Green
        #write-host ""

    }

    return

}

# Write-PSU-Config
#######################################################################################
# Description: Sets the config of the PSU
# Inputs:
#         $port              -> COM port object

function Write-PSU-Config ([System.IO.Ports.SerialPort]$port){

    $port.writeline("SYSTEM:REMOTE")

    $port.writeline("APPLY CH1")
    $port.writeline("SOURCE:OUTPUT:ENABLE 0")

    $port.writeline("APPLY CH2")
    $port.writeline("SOURCE:OUTPUT:ENABLE 0")

    $port.writeline("APPLY CH3")
    $port.writeline("SOURCE:OUTPUT:ENABLE 0")
    
    #$port.writeline("SYSTEM:LOCAL")

    return

}

# PSU-Output-Toggle
#######################################################################################
# Description: Toggles the main output switch of the PSU
# Inputs:
#         $port              -> COM port object
#

function PSU-Output-Toggle ([System.IO.Ports.SerialPort]$port){
    
    $port.writeline("OUTPUT?")
    $state = $port.readline()

    start-sleep -Seconds 1

    if($state -eq 0){
    
        $port.writeline("OUTPUT ON")
        write-host Output Toggled ON. -ForegroundColor Cyan
        write-host ""

    }
    elseif($state -eq 1){

        $port.writeline("OUTPUT OFF")
        Write-Host Output Toggled OFF. -ForegroundColor Cyan
        write-host ""

    }
    else{

        write-host Unknown Output State. -ForegroundColor Red

    }

}