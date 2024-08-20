#######################################################################################
# FILE NAME:         ATPInterface
# DESCRIPTION:       Read ambient temperature and pressure from the Feather M0
# OWNER:             Thomas Wood
# USAGE NOTES:       - All changes should keep backwards compatibility unless absoloutley
#                     neccessary
#                    - CTRL + M to collapse all regions
# KNOWN BUGS:        None
# SERIAL PARAMETERS: 9600,none,8,one
#######################################################################################


# Read-ATP
#######################################################################################
# Description: Reads the latest Ambient Temperature and Pressure readings from the 
#              device.
# Inputs:
#         $port -> COM port used for ATP sensor
#
#######################################################################################

function Read-ATP($port){

    $dataArray = @()
    $port.ReadTimeout = 5000
    $port.DtrEnable = "true"
   
    while($port.BytesToRead -ne 0){

        $port.DiscardInBuffer()

    }

    $data = $port.readline()

    $dataArray = $data -split " "

    $temp = $dataArray[0]
    $pres = $dataArray[2]
    $batt = $dataArray[4]
    $date = $dataArray[6]
    $time = $dataArray[8]

    $data = New-Object -TypeName psobject

    $data | Add-member -MemberType NoteProperty -Name Temp -Value $temp
    $data | Add-member -MemberType NoteProperty -Name Pres -Value $pres
    $data | Add-member -MemberType NoteProperty -Name Batt -Value $batt
    $data | Add-member -MemberType NoteProperty -Name Date -Value $date
    $data | Add-member -MemberType NoteProperty -Name Time -Value $time

    return $data

}
