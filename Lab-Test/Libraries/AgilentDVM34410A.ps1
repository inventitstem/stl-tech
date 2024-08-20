###############################################################################
# FILE NAME:         AgilentDVM34410A.ps1
# DESCRIPTION:       Reads data from the Agilent DVM
# OWNER:             Richard Gray
# USAGE NOTES:       - All changes should keep backwards compatibility unless
#                      absoloutely neccessary
#                    - CTRL + M to collapse all regions
#                    - Device is setup with Prologix GPIB to USB adapter.
#                      Because this is a parallel interface the Baudrate isn't
#                      actually important.
#                    GPIB adapter is assumed to be configured with matching 
#                    address & auto-read set to 'true'
# KNOWN BUGS:        None
# SERIAL PARAMETERS: Baudrate : 115200
#                    Parity   : None
#                    Databits : 8
#                    Stopbits : 1
###############################################################################

# read-agilent
###############################################################################
# Description: Reads from the GBIG port on the DVM
# Inputs:
#        $port       -> COM Port object
# Return:
#        Measurement value (double precision floating point)

function read-agilent ([System.IO.Ports.SerialPort]$port){

    # Flush buffer - any stale non-numerio characters will crash [double] cast
    $port.DiscardInBuffer()
    $port.WriteLine("READ?")
    $string=$port.ReadLine()
    $value=[double]$string
    return $value
}

# Set34410AMeasMode
###############################################################################
# Description: Selects the specified measurement mode on the DMM
#              The DMM will return a measurement value, this is discarded.
#              Read the live measurement values with read-agilent().
# Inputs:
#   $port   -> COM Port object
#   $mode   [string] One of the following: (will be inserted verbatim in the SCPI query)
#               CAP         (Capacitance)
#               CURR:AC     (AC current)
#               CURR:DC     (DC current)
#               FREQ        (Frequency)
#               FRES        (4-wire reistance)
#               RES         (2-wire resistance)
#               VOLT:AC     (AC voltage)
#               VOLT:DC     (DC voltage)
#               (other measurements require further configuration & are not currently suported)
#   $range  [string] Either a numeric value specifying the range, or AUTO
# Return:   $TRUE on success, $FALSE on timeout

function Set34410AMeasMode ([System.IO.Ports.SerialPort]$port, [string]$mode, [string]$range){

    [string]$CommandString = "MEAS:"
    $CommandString += $mode
    $CommandString += "? "
    $CommandString += $range
    
    $port.WriteLine($CommandString)
    # Wait for response
    $waitingResponse=$TRUE
    $Status = $TRUE
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    while($waitingResponse){
        if($port.BytesToRead -gt 0) {
            # Discard returned measurement
            $null = $port.ReadLine()
            $waitingResponse = $FALSE
        }
        if($stopWatch.ElapsedMilliseconds -ge 2000 ){
            $waitingResponse = $FALSE
            $Status = $FALSE
            write-host "Set34410AMeasMode timed out"
        }
    }
    
    return $status
}

# Get34410AInfo
###############################################################################
# Description: Requests the DMM's ident string
# Inputs:
#   $port   -> COM Port object
# Return:   psObject
#            Mfg    [string]
#            Model  [string]
#            Serial [string]
#            Rev    [string]

function Get34410AInfo ([System.IO.Ports.SerialPort]$port){
    $output = New-Object -TypeName PSObject
    $output | Add-member -MemberType NoteProperty -Name Mfg    -Value "INVALID"
    $output | Add-member -MemberType NoteProperty -Name Model  -Value "INVALID"
    $output | Add-member -MemberType NoteProperty -Name Serial -Value "INVALID"
    $output | Add-member -MemberType NoteProperty -Name Rev    -Value "INVALID"

    $port.WriteLine("*IDN?")
    # Wait for response
    $waitingResponse=$TRUE
    $Status = $TRUE
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    while($waitingResponse){
        if($port.BytesToRead -gt 0) {
            $ResponseString=$port.ReadLine()
            $waitingResponse = $FALSE
        }
        if($stopWatch.ElapsedMilliseconds -ge 2000 ){
            $waitingResponse = $FALSE
            $Status = $FALSE
            write-host "Get34410AInfo timed out"
        }
    }
    if($Status) {
        $FieldStrings = $ResponseString.split(',')
        $output.Mfg    = $FieldStrings[0]
        $output.Model  = $FieldStrings[1]
        $output.Serial = $FieldStrings[2]
        $output.Rev    = $FieldStrings[3]
    }
    
    return $output
}

# #################### END OF FILE AgilentDVM34410A.ps1 #######################
