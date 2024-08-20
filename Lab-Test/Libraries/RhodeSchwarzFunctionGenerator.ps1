#######################################################################################
# FILE NAME:         RhodeSchwarzFunctionGenerator
# DESCRIPTION:       Sets configuration data for the function generator
# OWNER:             Thomas Wood
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
# set-FunGen-output
#######################################################################################
# Description: Sets the output of the function generator
# Inputs:
#         $port              -> COM port object
#         $wave_type         -> Function Shape
#         $frequency         -> Frequency (Hz)
#         $amplitude         -> Amplitude (V)
#         $offset            -> Offset (V)
#         $duty_cycle        -> Duty Cycle (%)

function set-FunGen-output ([System.IO.Ports.SerialPort]$port, $wave_type, $frequency, $amplitude, $offset, $duty_cycle){

# Function Type
    if($wave_type -eq "Sine"){
    
        $port.writeline("FUNC SIN")

        #write-host Function Type Set to $wave_type. -ForegroundColor Green

    }
    elseif($wave_type -eq "Square"){
        
        $port.writeline("FUNC SQU")

        #write-host Function Type Set to $wave_type. -ForegroundColor Green

    }
    else{

        write-host Unknown `$wave_type.

    }

# Frequency
    $port.writeline("FREQ $frequency")

    #write-host Frequency Set to $frequency`Hz. -ForegroundColor Green

# Amplitude
    $port.writeline("VOLT $amplitude")

    #write-host Amplitude Set to $amplitude`V. -ForegroundColor Green

# Offset
    $port.writeline("VOLT:OFFS $offset")

    #write-host Offset Set to $offset`V. -ForegroundColor Green

# Duty Cycle
    if($wave_type -eq "Square"){

        $port.writeline("FUNC:SQU:DCYC $duty_cycle")

       # write-host Duty Cycle Set to $duty_cycle`%. -ForegroundColor Green

    }

}

# read-FunGen-output
#######################################################################################
# Description: Sets the output of the function generator
# Inputs:
#         $port              -> COM port object
#         $wave_type         -> Function Shape
#         $frequency         -> Frequency (Hz)
#         $amplitude         -> Amplitude (V)
#         $offset            -> Offset (V)
#         $duty_cycle        -> Duty Cycle (%)

function read-FunGen-output ([System.IO.Ports.SerialPort]$port){

    $port.writeline("FUNC?")
    $wave_type = $port.readline()

    if($wave_type -eq "SIN"){
        
        $wave_type = "Sine"

    }
    elseif($wave_type -eq "SQU"){

        $wave_type = "Square"

    }
    else{}

    write-host Function Type is $wave_type`. -ForegroundColor Cyan

    $port.writeline("FREQ?")
    $frequency = $port.readline()

    write-host Frequency is $frequency`Hz. -ForegroundColor Cyan

    $port.writeline("VOLT?")
    $amplitude = $port.readline()

    write-host Amplitude is $amplitude`V. -ForegroundColor Cyan

    $port.writeline("VOLT:OFFS?")
    $offset = $port.readline()

    write-host Offset is $offset`V. -ForegroundColor Cyan

    if($wave_type -eq "Square"){

        $port.writeline("FUNC:SQU:DCYC?")
        $duty_cycle = $port.readline()

        write-host Duty Cycle is $duty_cycle`%. -ForegroundColor Cyan

    }

}