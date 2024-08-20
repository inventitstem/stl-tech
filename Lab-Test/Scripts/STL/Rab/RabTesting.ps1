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
#Remove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear(); Clear-Host

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

#$libsPath = "..\..\Libraries"

#if(!(test-path $libsPath)){
#
#    write-host Cannot locate libraries folder at $libsPath. Press anykey to exit ... -foregroundcolor Red
#    read-host
#    exit 1
#}

$InterfaceFunctionsLibs="RabFunctions.ps1"

#foreach($InterfaceFunctionsLib in $InterfaceFunctionsLibs){
    Try{

        .\RabFunctions.ps1
        write-host $InterfaceFunctionsLib file added. -foregroundcolor Green

    }
    Catch{

        write-host $InterfaceFunctionsLib file not found. Unable to proceed. Press any key to quit ... -foregroundcolor Red
        read-host
        exit 1

    }

#}



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

    for($i=0; $i -lt $serialports.length; $i++){

        $serialports[$i].close()
        write-host $serialportsnames[$i] COM Port Closed. -foregroundcolor Green
    
    }

    # Create COM port objects. 
    $Global:rabPort = new-Object System.IO.Ports.SerialPort COM5,115200,None,8,1
    #$trendzPort = new-Object System.IO.Ports.SerialPort COM4,115200,None,8,1


    # Load COM port objects into array for easy control
    $Global:serialports = @($rabPort)

    # Create parallel array to name COM port objects.
    # Values with [] should be replaced (inclusive of []) to something more user-friendly.
    $serialportsnames = @("rabPort")

    # Open all interfaces if possible. Terminate script if not.
    for($i = 0; $i -lt $serialports.length; $i++){

        Try{
            $serialports[$i].ReadTimeout = 2000
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
#$date= $((get-date).ToString('yyyy-MM-dd'))
#$datetime= $((get-date).ToString('yyyy-MM-dd_HH-mm-ss'))

#Create Results variables
#$results_dir = "Results_$date" 		#All results in single folder for each day
#$results_dir = "Results_$datetime"	#All results in separate folders
#$raw_data_file = "$results_dir\raw_data_$datetime.csv"
#$ref_data_file = "$results_dir\ref_data_$datetime.csv"
#$transcript_file = "$results_dir\transcript_$datetime.txt"

#new-item -name $results_dir -ItemType Directory > $null


#Variables



#######################################################################################
#region End
#######################################################################################

# This section terminates the script:
#     - Configure devices into default/ safe state e.g. setting MFC to 0 or switching off a PSU.
#     - Save any outstanding data
#     - Close all open interfaces

# Close all COM ports present in the $serialports array.

    # Close all COM ports present in the $serialports array.
#for($i=0; $i -lt $serialports.length; $i++){
#
#    $serialports[$i].close()
#    write-host $serialportsnames[$i] COM Port Closed. -foregroundcolor Green
    
#}

# Stop Transcript
#Stop-Transcript


#write-host ""
#write-host Complete. Script Terminated. -foregroundcolor Green


#endregion Save
#######################################################################################
