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
function ping_test{
    param(
        [string]$ip
        )

    $return = New-Object -TypeName psobject
    $timeout=$false

    $pingResult = ping $ip

    foreach($result in $pingResult.split("(,)")){
        write-host $result
        if($result.Contains("Request timed out")){
            #write-host "Time Out"
            $timeout = $true
            break
        }elseif($result.Contains("Destination host unreachable")){
            #write-host "Time Out"
            $timeout = $true
            break

        }elseif($result.Contains("%")){
            #write-host $result.split()[0]
            $dataLoss = $result.split()[0]
            
        }
    }

    $return | Add-member -MemberType NoteProperty -Name timeout -Value $timeout
    $return | Add-member -MemberType NoteProperty -Name dataloss -Value $dataloss

    return $return
}
function phy_test{
    param(
        [System.IO.Ports.SerialPort]$port
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host testing Phy ...
    $Port.writeline("mii dump 1 1")
    sleep -seconds 2

    $phy_result=@()
    $s=0
    while($Port.BytesToRead -gt 0){
        if($s -gt 10){$Port.DiscardInBuffer()}
        $line=$Port.readline()
        $phy_result+=$line
        write-host $line
        $s++
    }
    $result=@()
    for($n=1;$n -lt $phy_result.count;$n++){
        $result+=(($phy_result[$n].split("="))[1].trim())[0]

    }

    if(@($result | select -unique).count -eq 1){
        write-host Test has failed
        $phy_initialised=$false
    }else{
        write-host Test has passed
        $phy_initialised=$true

    }

    $return | Add-member -MemberType NoteProperty -Name pass -Value $phy_initialised
    $return | Add-member -MemberType NoteProperty -Name values -Value $result

    return $return
}
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

$libsPath = "..\..\Libraries"

if(!(test-path $libsPath)){

    write-host Cannot locate libraries folder at $libsPath. Press anykey to exit ... -foregroundcolor Red
    read-host
    exit 1
}

$InterfaceFunctionsLibs="MultiCompMP710086.ps1"

foreach($InterfaceFunctionsLib in $InterfaceFunctionsLibs){
    Try{

        . $libsPath/$InterfaceFunctionsLib
        write-host $InterfaceFunctionsLib file added. -foregroundcolor Green

    }
    Catch{

        write-host $InterfaceFunctionsLib file not found. Unable to proceed. Press any key to quit ... -foregroundcolor Red
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

for($i=0; $i -lt $serialports.length; $i++){

    $serialports[$i].close()
    write-host $serialportsnames[$i] COM Port Closed. -foregroundcolor Green
    
}

# Create COM port objects. 
$psuPort = new-Object System.IO.Ports.SerialPort COM4,115200,None,8,1
#$trendzPort = new-Object System.IO.Ports.SerialPort COM7,115200,None,8,1


# Load COM port objects into array for easy control
$serialports = @($psuPort)#,$trendzPort)

# Create parallel array to name COM port objects.
# Values with [] should be replaced (inclusive of []) to something more user-friendly.
$serialportsnames = @("psu")#,"trendzPort")

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
$date= $((get-date).ToString('yyyy-MM-dd'))
$datetime= $((get-date).ToString('yyyy-MM-dd_HH-mm-ss'))

#Create Results variables
#$results_dir = "Results_$date" 		#All results in single folder for each day
$results_dir = "Results_$datetime"	#All results in separate folders
$raw_data_file = "$results_dir\raw_data_$datetime.csv"
$ref_data_file = "$results_dir\ref_data_$datetime.csv"
$transcript_file = "$results_dir\transcript_$datetime.txt"

new-item -name $results_dir -ItemType Directory > $null


#Variables
$Vout=24.0
$ILimit=3.0
$hourRepeat=3 # Time between each block of test cycles
$testCycles=20 # Number of test blocks to run
$testIterations=30 # Number of tests in each block to run
$debug=$true #More verbose
$fullboot=$true # determines to wait for full boot or interrupt on UBoot
$testPowerOffTimeStart=60 # Minimum time off between test iterations
$testPowerOffTimeIncrease=0 #Increase of time off between test iterations

write-host Setting up the PSU to V = $Vout and ILimit = $ILimit ... -NoNewline
if((psu -port $psuPort -Vout $Vout -ILimit $ILimit).error -eq $false){
    write-host done -ForegroundColor Green
}else{
    write-host Error -ForegroundColor red
    read-host Press any key to continue
}
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
$testPowerOffTime=$testPowerOffTimeStart
for($t=0;$t -lt $testCycles;$t++){

    #Run test every 3hrs
    $start_time=get-date
    $end_time=$start_time.addhours($hourRepeat)

    #Run 10 tests consecutively
    for($r=0;$r -lt $testIterations;$r++){
        write-host "`n`n-------------------------`nRunning test $r"
        psu -port $psuPort -enable "ON"

        $start=get-date # Start of the test
        $end=$start.addminutes(1)

        $textarray=@()
        $bytearray = New-Object byte[] 1000

        #$trendzport.DiscardInBuffer()
        #$trendzport.DiscardOutBuffer()
        #$bootdetect=$false
        #write-host Interrupting UBoot 
        #while((get-date) -lt $end -and $bootdetect -eq $false){

        #($i=0;$i -lt 30;$i++){
            #$line=$trendzPort.readline()
            #write-host $line
    
            #if($line -match "hit"){
            #    while($trendzport.BytesToRead -gt 0){
            #        $bytesavailable=$trendzport.BytesToRead
            #        #write-host Bytes available $bytesavailable
            #        $bytesread=$trendzPort.read($bytearray,0,$bytesavailable)
                    #write-host Bytes read $bytesRead
                    #if($bytearray[$bytesRead]
            #        $text=([System.Text.Encoding]::ASCII.GetString($bytearray[0..($bytesread-1)])).split("'r")
                    #write-host Found $text.count lines
            #        for($k=0;$k -lt $text.count;$k++){
             #           if($debug){
            #                write-host $k $text[$k]
            #            }
            #            $textarray+=$text[$k]
            #            if($text[$k] -match "`b"){
            #                if(!$fullboot){$trendzPort.write("k")} #Interrupt boot sequence
            #                write-host Detected Boot
            #                $bootdetect=$true
            #                break
            #            }

            #        }
            #   }
        #}
        #if($fullboot -and $bootdetect){
            # Wait for boot to finish
        #    write-host Waiting for boot sequence to finish -nonewline
        #    $end = (get-date).AddSeconds(30)
        #    while((get-date) -lt $end){
        #        while($trendzport.BytesToRead -gt 0){
        #            $trendzPort.DiscardInBuffer()
        #            $end = (get-date).AddSeconds(30)
        #            write-host "." -nonewline
        #        } #clear buffer
        #        
        #    }
        #    write-host done.
        #    write-host Boot sequence finished. Logging in
        #    

        #    $trendzPort.writeline("root")
        #    sleep -seconds 1
        #    $trendzPort.writeline("stlqlm")

        #    $trendzPort.DiscardInBuffer()

        #    sleep -seconds 5

            #write-host Setting IP address
            #$trendzPort.writeline("ifconfig eth0 10.0.0.100")
            #$trendzPort.DiscardInBuffer()
            #sleep -seconds 1
            #$trendzPort.writeline("ifconfig eth0")

            #while($trendzPort.BytesToRead -gt 0){

            #    try{
            #        $text = $trendzPort.readline()
            #        write-host $text
            #    }catch{
            #        break;
            #    }
            #}

            #sleep -seconds 4
            
            #Ping the QLM system.
            #ping 10.0.0.100
            $pingResult = ping 10.0.0.100
            $booted=$false
            #ping 10.0.0.100
            $start_time_timeout=get-date
            write-host Pinging server $start_time_timeout -nonewline
            $end_time_timeout=$start_time_timeout.addminutes(10)
            while((get-date) -lt $end_time_timeout){
                $pingResult = ping_test 10.0.0.100
                if( $pingResult.timeout -eq $false){
                    $booted=$true
                    $boot_time = (get-date)-$start_time_timeout
                    write-host `nDevice booted at (get-date) in $boot_time.seconds seconds
                    break
                }else{
                    write-host "." -nonewline
                }
            }

            write-host
            if($booted -eq $true){
                write-host Ping test has $pingResult.dataLoss dataloss
            }else{
                write-host Ping test timed-out
            }


        #}else{

        #    $trendzPort.DiscardInBuffer()
        #    $trendzPort.DiscardOutBuffer()

        #    if($bootdetect){
        #        #read-host Stop

        #        write-host Waiting ...
        #        sleep -seconds 5

        #        while($trendzport.BytesToRead -gt 0){$trendzPort.DiscardInBuffer()} #clear buffer

        #        write-host Bytes to read $trendzPort.BytesToRead
        #        write-host Bytes to write $trendzPort.BytesTowrite

        #        write-host Loading FPGA ...

        #        $trendzPort.writeline("run load_fpga")
        #        sleep -seconds 10
        #        $s=04
        #        while($trendzPort.BytesToRead -gt 0){
        #            if($s -gt 2){$trendzPort.DiscardInBuffer()}
        #            write-host Bytes to read $s $trendzPort.BytesToRead
        #            $line=$trendzPort.readline()
        #            #write-host $line
        #            $s++
        #        }

        #        while($trendzport.BytesToRead -gt 0){$trendzPort.DiscardInBuffer()} #clear buffer

        #        $phy_pretest=phy_test -port $trendzport

        #        write-host Resetting Phy
        #        $trendzport.writeline("mw.b 0x8000003c 0x00;sleep 0.5;mw.b 0x8000003c 0x10") # reset phy

        #        sleep -Seconds 1
        #        while($trendzport.BytesToRead -gt 0){$trendzPort.DiscardInBuffer()} #clear buffer


        #        $phy_posttest=phy_test -port $trendzport
        #    }else{
        #        write-host Boot not detected

        #    }
        #}

        $psu_result= psu -port $psuPort

        $result = New-Object -TypeName psobject    


        $result | Add-member -MemberType NoteProperty -Name date -Value (get-date)
        $result | Add-member -MemberType NoteProperty -Name r -Value $r
        $result | Add-member -MemberType NoteProperty -Name t -Value $t
        $result | Add-member -MemberType NoteProperty -Name booted -Value $booted
        $result | Add-member -MemberType NoteProperty -Name dataloss -Value $pingResult.dataLoss
        $result | Add-member -MemberType NoteProperty -Name boot_time -Value $boot_time.seconds
        #$result | Add-member -MemberType NoteProperty -Name phytest1 -Value $phy_pretest.pass
        #$result | Add-member -MemberType NoteProperty -Name test1_values -Value ($phy_pretest.values -join "")
        #$result | Add-member -MemberType NoteProperty -Name phytest2 -Value $phy_posttest.pass
        #$result | Add-member -MemberType NoteProperty -Name test2_values -Value ($phy_posttest.values -join "")
        $result | Add-member -MemberType NoteProperty -Name vout -Value $psu_result.vout
        $result | Add-member -MemberType NoteProperty -Name iout -Value $psu_result.iout

        $result | export-csv -path $ref_data_file -append

        #end test

        sleep -seconds 30 #Wait for system to fully boot before power cycling

        psu -port $psuport -enable "OFF"

        write-host Waiting for $testPowerOffTime
        sleep -seconds $testPowerOffTime
        
        $testPowerOffTime = $testPowerOffTime + $testPowerOffTimeIncrease

    }

    #Wait for test cycle period
    write-host Waiting for $end_time
    while((get-date) -lt $end_time){

    }
}

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
