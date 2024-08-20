
# FILE NAME:         MultiCompMP710086
# DESCRIPTION:       Reads data from the MultiComp MP710086 & MP710087
# OWNER:             Rich Gray
# USAGE NOTES:       - All changes should keep backwards compatibility unless absoloutley
#                     neccessary
#                    - CTRL + M to collapse all regions
# KNOWN BUGS:        None
# SERIAL PARAMETERS: Baudrate : 115200
#                    Parity   : None
#                    Databits : 8
#                    Stopbits : 1
#######################################################################################
#
# Read-PSU-Channel
#######################################################################################
# Description: Enables the output  the output of the PSU
# Inputs:
#         $port              -> COM port object
#         $enable           -> PSU Output Channel. 1, 2, or 3.

function PSU{
    param(
        [System.IO.Ports.SerialPort]$port,
        $enable,
        [float]$VOut,
        [float]$ILimit
        )

    #Error
    if(-not $port){write-host No port specified -ForegroundColor red;return 0}
    #Setup
    $error=$false
    $result = New-Object -TypeName psobject    

    # Measure
    $port.writeline("MEAS:VOLT?")
    $Voltage = $port.readline()

    $port.writeline("MEAS:CURR?")
    $Current = $port.readline()

    $port.writeline("MEAS:POW?")
    $Power = $port.readline()

    $result | Add-member -MemberType NoteProperty -Name VOut -Value $Voltage
    $result | Add-member -MemberType NoteProperty -Name IOut -Value $Current
    $result | Add-member -MemberType NoteProperty -Name POut -Value $Power


    # Voltage set
    if($VOut -ne $null -and $Vout){
        write-host Setting Voltage Limit to $VOut
        $port.writeline("Volt $VOut")
        #if($port.readline() -eq 1){
        #    $result | Add-member -MemberType NoteProperty -Name VOutSetOk -Value $true
        #}else{
        #    $result | Add-member -MemberType NoteProperty -Name VOutSetOk -Value $false
        #    $error=$true
        #}

    }

    # CurrentLimit set
    if($ILimit -ne $null -and $ILimit){
        write-host Setting Current Limit to $ILimit
        $port.writeline("CURR:LIM $ILimit")
        #if($port.readline() -eq 1){
        #    $result | Add-member -MemberType NoteProperty -Name ILimitSetOk -Value $true
        #}else{
        #    $result | Add-member -MemberType NoteProperty -Name ILimitSetOk -Value $false
        #    $error=$true
        #}
    }

    # Output enable
    if($enable -ne $null -and $enable){
        write-host Setting output to $enable ...
        $port.writeline("OUTP $enable")
        #if($port.readline() -eq 1){
        #    $result | Add-member -MemberType NoteProperty -Name EnableSetOk -Value $true
        #} else{
        #    $result | Add-member -MemberType NoteProperty -Name EnableSetOk -Value $false
        #    $error=$true
        #}
    }
    
    $result | Add-member -MemberType NoteProperty -Name error -Value $error
    return $result

    }
