#######################################################################################
# FILE NAME:         Filename
# DESCRIPTION:       Description
# OWNER:             Name
# USAGE NOTES:       - All changes should keep backwards compatibility unless absoloutley
#                     neccessary
#                    - CTRL + M to collapse all regions
#                    - Any other setup information e.g. particular hardware etc.
# KNOWN BUGS:        Bug information
# SERIAL PARAMETERS: Baudrate : 115200
#                    Parity   : None
#                    Databits : 8
#                    Stopbits : 1
#######################################################################################


# Function1
#######################################################################################
# Description: Description of function 1
# Inputs: [name] -> [variable type] [Description]
#        $port               -> COM Port object
#        $input1             -> Byte Command
#        $input2             -> Byte Datalength
#        $input3             -> Byte Array Data
# Return: [name] -> [variable type] [Description]
#        Object.Value1       -> Boolean Has a total frame been recieved
#        Object.Value2       -> Integer Length of returned data OK
#        Object.Value3       -> String State of device

#function function1 ([System.IO.Ports.SerialPort]$port,[byte]$input1,[byte]$input2,[byte[]]$input3) {
    # Explicitly state the variable type in function declaration.

	#Write the Command to the device

	#Read the response from the device
 
    #Parse Any data

    #Create an object that has multiple properties if you want to return multiple values.
    # $rxmsg = New-Object -TypeName psobject

    # Add property members to the object
    # $rxmsg | Add-member -MemberType NoteProperty -Name Data -Value1 $data1
    # $rxmsg | Add-member -MemberType NoteProperty -Name Data -Value2 $data2
    # $rxmsg | Add-member -MemberType NoteProperty -Name Data -Value3 $data3


    #return data to script.Always consider returning a value especially error data so that it can be detected when a function/ device has failed.
    # return $rxmsg
    
#}