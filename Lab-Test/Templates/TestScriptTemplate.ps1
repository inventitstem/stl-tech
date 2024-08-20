#######################################################################################
# File: [File name]
# Req.: [Other scripts required to run this script. device functions.ps1 will be required for all scripts]
#       [Need to change PC permissions to be able to run scripts. This is done by changing the execution policy.]
#       [This is should be set to RemoteSigned and recommended scope is User. You will need to run Powershell in Administrator Mode to do this]
#       [Set-ExecutionPolicy -ExecutionPolicy remotesigned -scope CurrentUser]
# Auth: [Script author's name]
# Desc: [Basic description of the function of the script]
#     
# Date: [Date created]
#######################################################################################
# Coding Standard
# Text Colours : Green=Pass/OK, Red=Not OK/Fail, Yellow=Warning. All other information should be default

# Clear values in IDE from previous script run
#######################################################################################
Remove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear(); Clear-Host

#######################################################################################
#region Setup
#######################################################################################

# This section sets up the script environment. Typically it will serve 3 purposes:
#     - Call any suporting script files/libraries
#     - Define and start any interfaces/connected sensors/serial ports
#     - Create any file path definitions including new folders.
#
# The script should fail if anyone of these steps fails as the environment is not fully setup

# Call support script files
#######################################################################################
# Ensure that all the libraries that you wish to include are stored in a folder called libraries in the directory that the script is being run from
# The script will then load these libraries

$libsPath = ".\Libraries"

if(!(test-path $libsPath)){

    write-host Cannot locate libraries folder at $libsPath. Press anykey to exit ... -foregroundcolor Red
    read-host
    exit 1
}

$InterfaceFunctionsLibs=Get-ChildItem $libsPath

foreach($InterfaceFunctionsLib in $InterfaceFunctionsLibs){
    Try{

        . $InterfaceFunctionsLib.fullname
        write-host $InterfaceFunctionsLib.fullname file added. -foregroundcolor Green

    }
    Catch{

        write-host $InterfaceFunctionsLib.fullname file not found. Unable to proceed. Press any key to quit ... -foregroundcolor Red
        read-host
        exit 1

    }

}

# Interface Setup
#######################################################################################

#Close any existing serial ports that are left open from previous script execution.
for($i=0; $i -lt $serialports.length; $i++){

    try
    {
        $serialports[$i].open()
    }
    catch
    {
        write-host $serialports[$i].portname Port is already open
    }
    finally{
        $serialports[$i].close()
    }
    
}

# Create COM port objects. Values with [] must be replaced (inclusive of []) as per comms device specification. These can be found in the InterfaceFunctions.ps1 script.
$port1 = new-Object System.IO.Ports.SerialPort [COM Port],[Baudrate],[Parity],[Data Bits],[Stop Bit(s)]
$port2 = new-Object System.IO.Ports.SerialPort [COM Port],[Baudrate],[Parity],[Data Bits],[Stop Bit(s)]
$port3 = new-Object System.IO.Ports.SerialPort [COM Port],[Baudrate],[Parity],[Data Bits],[Stop Bit(s)]

# Load COM port objects into array for easy control
$serialports = @($port1, $port2, $port3)

# Create parallel array to name COM port objects.
# Values with [] should be replaced (inclusive of []) to something more user-friendly.
$serialportsnames = @("[$port1]","[$port2]","[$port3]")

# Open all interfaces if possible. Terminate script if not.
for($i = 0; $i -lt $serialports.length; $i++){

    Try{
        $serialports[$i].ReadTimeout = 500
        $serialports[$i].open()
        
        write-host $serialportsnames[$i] COM Port Initialised. -foregroundcolor Green
    
    }
    Catch{

        write-host Error Opening $serialportsnames[$i] COM Port.
        
        $serialports[$i].close()

        exit 1

    }

}

# File path definition
#######################################################################################

#Create date time string for naming of results files.
$date= $((get-date).ToString('yyyy-MM-dd'))
$datetime= $((get-date).ToString('yyyy-MM-dd_HH-mm-ss'))

#Create Results variables
$results_dir = "Results_$date" 		#All results in single folder for each day
#$results_dir = "Results_$datetime"	#All results in separate folders
$raw_data_file = "$results_dir\raw_data_$datetime.csv"
$ref_data_file = "$results_dir\ref_data_$datetime.csv"
$transcript_file = "$results_dir\transcript_$datetime.txt"

new-item -name $results_dir -ItemType Directory > $null

# Start Transcript to log terminal 
#######################################################################################
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null #Stop any script that has started
$ErrorActionPreference = "Continue"
Start-Transcript -path $transcript_file -append

#endregion Setup
#######################################################################################

#######################################################################################
#region Test
#######################################################################################

# This section will configure interfaces either automatically or prompt user input to configure devices.
# Data can then be sampled from connected sensors/devices once equipment is configured.
# The results can then be sorted/ordered and basic analysis completed to aid data analyis (usually import in excel)

# Considerations should be:
#     - If timings/ pauses are used in the script to control flow and sequencing
#       careful consideration should be given so that there is adequate time for
#       actions to complete before the script moves onto the next action.
#     - All lines on the script take a finite amount of time. For interactions with
#       sensors, this can be significant e.g. upto 1second.
#     - Results saved regulary rather than in bulk at end of script prevent the loss of
#       test data.
#     - Saving data as an array of objects allows easy manipulation of data, however saving and printing data as an object is easier to transfer to Excel.
#     - Some basic analysis of data is very beneficial to data analysis 
#       e.g. caclulating average and range of 100 samples
#     - Log as much information as possible in results particulary to do with errors.
#       Errors can then be easily traced.

# Example:
# Gas sensor needs to be tested for accuracy across different flow rates of gas.
# Calibrated test gases from external bottles are used to test the gas with an MFC to set flow rate.
# -For each test gas
# --Prompt User to connect gas
# -- For each flow rate
# --- Pause to allow sensor to stabilise
# --- Take 100 samples of gas sensor every 500ms
# --- Append raw data to results file
# --- Calculate Average and Range of samples for Gas and Flow rate
# --- Append calculated average and range to results file. 

#endregion Test
#######################################################################################


#######################################################################################
#region End
#######################################################################################

# This section terminates the script:
#     - Configure devices into default/ safe state e.g. setting MFC to 0 or switching off a PSU.
#     - Save any outstanding data
#     - Close all open interfaces

# Close all COM ports present in the $serialports array.
for($i=0; $i -lt $serialports.length; $i++){

    $serialports[$i].close()
    write-host $serialportsnames[$i] COM Port Closed. -foregroundcolor Green
    
}

# Stop Transcript
Stop-Transcript


write-host ""
write-host Complete. Script Terminated. -foregroundcolor Green

#endregion Save
#######################################################################################
