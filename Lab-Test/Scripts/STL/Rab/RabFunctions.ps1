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
function open_ports{
    param()
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
    $Global:rabPort = new-Object System.IO.Ports.SerialPort COM4,115200,None,8,1
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

    return $serialports
}
function close_ports{
    param()

    # Close all COM ports present in the $serialports array.
                for($i=0; $i -lt $serialports.length; $i++){

    $serialports[$i].close()
    write-host $serialportsnames[$i] COM Port Closed. -foregroundcolor Green
    
    }

    # Stop Transcript
    #Stop-Transcript


    write-host ""
    write-host Complete. Script Terminated. -foregroundcolor Green

}

function read_input_buffer{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $debug_on = $false,
        [bool] $echo_on = $true,
        [bool] $strip_data = $false,
        [int] $msec_pause = 100
        )

    $return_data=@()
    start-sleep -Milliseconds $msec_pause

    #write-host $port.BytesToRead

    if($echo_on){
        $data=$port.readline()
        if($debug_on){write-host $data}
    }
    while($port.BytesToRead -gt 4){

        $data=$port.readline()
        if($debug_on){write-host $data}
        if($strip_data){
            $data_split=$data.split(":")
            if($data_split.count -gt 1){
                #write-host (($data.split(":"))[1]).trim()
                $return_data+=(($data.split(":"))[1]).trim()
            }else{
                #ignore
            }
        }else{
            #write-host Ignore
            $return_data+=$data
        }
    }

    return $return_data
    #if($strip_data){
    #    return (($data.split(":"))[1]).trim()
    #}else{
    #    return $data
    #}
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

function serial_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host Testing Serial ...
    $Port.writeline("STATUS`r")
    sleep -seconds 2

    if($echo_on){$null=$port.readline()}
    $data=$port.readline()

    write-host $data

    if($data -eq "Status command received."){
        write-host "Status Test Pass"
        return $true
    } else{
        write-host "Status Test Fail"
        return $false
    }

    return
}

function valve_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host Testing Valves ...
    #$Port.writeline("IO W 31 0`r")
    #sleep -seconds 1


    for($i=1;$i -le 9;$i++){
        $Port.writeline("valve $i 1`r")
        sleep -seconds 1
    }

    for($i=1;$i -le 9;$i++){
        $Port.writeline("valve $i 0`r")
        sleep -seconds 1
    }

    #$Port.writeline("IO W 41 1`r")
    #sleep -seconds 2

    #if($echo_on){$null=$port.readline()}
    #$data=$port.readline()

    #$Port.writeline("IO W 41 0`r")
    #sleep -seconds 2

    #write-host $data

    #if($data -eq "Status command received."){
    #    write-host "Status Test Pass"
    #    return $true
    #} else{
    #    write-host "Status Test Fail"
    #    return $false
   # }

    $Port.DiscardInBuffer()
    return
}

function heater_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $time_on = 10

    $Port.DiscardInBuffer()
    write-host Testing Heaters ...

    $Port.writeline("IO W 31 0`r")
    sleep -seconds 1


    for($i=16;$i -le 17;$i++){
        Write-host Setting heater $i on for $time_on seconds..
        $Port.writeline("IO W $i 1`r")
        sleep -seconds $time_on
        Write-host Setting heater $i off ..
        $Port.writeline("IO W $i 0`r")
    }

    $Port.DiscardInBuffer()
    return
}

function bl_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host Testing Serial ...

    for($i=0;$i -le 100;$i=$i+10){
        $Port.writeline("PWM W 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -seconds 1
    }

    for($i=100;$i -ge 0;$i=$i-10){
        $Port.writeline("PWM W 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -seconds 1
    }

    return
}

function dac_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $Port.DiscardInBuffer()
    write-host Testing DAC ...

    for($i=0;$i -le 4095;$i=$i+5){
        $Port.writeline("DAC W 1 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -milliseconds 10
    }

    for($i=4095;$i -ge 0;$i=$i-5){
        $Port.writeline("DAC W 1 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -milliseconds 10
    }

    return
}

function pump_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host Testing Pump ...

    $rabport.writeline("DAC W 1 1 4095`r") # To set DAC output. Is inverted. Do not set higher than 55V =? DAC
    $rabport.writeline("IO W 33 1`r") # To set boost enable circuit

    for($i=0;$i -le 100;$i=$i+10){
        $Port.writeline("PWM W 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -seconds 1
    }

    for($i=100;$i -ge 0;$i=$i-10){
        $Port.writeline("PWM W 1 $i`r")
        read_input_buffer $port $debug_on
        sleep -seconds 1
    }

    return
}

function bme680_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $Port.DiscardInBuffer()
    write-host Testing Pump ...

    $rabport.writeline("I2C R 1 0x76 0xD0`r") #
    read_input_buffer $port $debug_on

    return
}

function adc_read{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $instance,
        [int] $channel,
        [float] $factor,
        [float] $reference = 3.3
        )

    $return = New-Object -TypeName psobject

    $Port.DiscardInBuffer()
    write-host Read ADC ...

    $rabport.writeline("ADC R $instance $channel`r") #
    start-sleep -Milliseconds 100
    $result=read_input_buffer -port $port -debug_on $debug_on -echo_on $echo_on
    $adc_count=($result-split ":")[1].trim()

    $return | Add-member -MemberType NoteProperty -Name adc_count -Value $adc_count
    $return | Add-member -MemberType NoteProperty -Name factor -Value $factor
    $return | Add-member -MemberType NoteProperty -Name reference -Value $reference
    $return | Add-member -MemberType NoteProperty -Name value -Value $result

    return $return
}

function adc_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $Port.DiscardInBuffer()
    write-host Testing ADC ...

    $port.writeline("ADC R 1 1`r") #
    read_input_buffer $port $debug_on
    $port.writeline("ADC R 2 1`r") #
    read_input_buffer $port $debug_on

    return
}

function gpio_read{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel
        )

    $Port.DiscardInBuffer()
    write-host Read Input ...

    $rabport.writeline("IO R $channel`r") #
    if($echo_on){$port.readline()}
    $return_String=$port.readline()

    if($debug_on){write-host $return_string}
    
    $value=$return_String.replace("Input pin $channel`: ","").Trim()
    write-host $value.count
    if($value -eq 1){
        if($debug_on){write-host $value "TRUE"}
        return $TRUE
    }elseif($value -eq 0){
        if($debug_on){write-host $value "FALSE"}
        return $FALSE
    }else{
        if($debug_on){write-host $value "Unknown"}
        return $value
    }
}

function gpio_input_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $data = @(
        [pscustomobject]@{Name='DI_TANK_LEVEL1';Channel= 10;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL2';Channel= 11;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_6';Channel= 7;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_3';Channel= 4;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_4';Channel= 5;Value=$null}
        [pscustomobject]@{Name='DI_FAN_DRV_NFAULT';Channel= 40;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL3';Channel= 12;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL4';Channel= 13;Value=$null}
        [pscustomobject]@{Name='DI_FAN_ALERT';Channel= 35;Value=$null}
        [pscustomobject]@{Name='DI_FAN_FAULT';Channel= 36;Value=$null}
        [pscustomobject]@{Name='DI_T1_RDY';Channel= 37;Value=$null}
        [pscustomobject]@{Name='DI_T2_RDY';Channel= 38;Value=$null}
        [pscustomobject]@{Name='SUB_BTN_USER';Channel= 19;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_0';Channel= 1;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_1';Channel= 2;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_2';Channel= 3;Value=$null}
        [pscustomobject]@{Name='DI_USB_FAULT1';Channel= 25;Value=$null}
        [pscustomobject]@{Name='DI_USB_FAULT2';Channel= 27;Value=$null}
        [pscustomobject]@{Name='DI_DRV1_NFAULT';Channel= 28;Value=$null}
        [pscustomobject]@{Name='DI_DRV2_NFAULT';Channel= 29;Value=$null}
        [pscustomobject]@{Name='DI_DRV3_NFAULT';Channel= 30;Value=$null}
        [pscustomobject]@{Name='DI_FLOWMET_FAULT';Channel= 23;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_5';Channel= 6;Value=$null}
        [pscustomobject]@{Name='SUB_GPIO_7';Channel= 8;Value=$null}
    )

    $Port.DiscardInBuffer()
    write-host Testing GPIO Input ...

    for($i=0;$i -lt $data.count;$i++){
        $data[$i].value = (gpio_read -port $port -channel $data[$i].channel -debug_on $debug_on)[1]
        start-sleep -Milliseconds 10

    }

    return $data
}

function level_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true
        )

    $data = @(
        [pscustomobject]@{Name='DI_TANK_LEVEL1_J17';Sensor="Waste Level";Channel= 10;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL2_J19';Sensor="Cyclo Level";Channel= 11;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL3_J20';Sensor="IPA Level";Channel= 12;Value=$null}
        [pscustomobject]@{Name='DI_TANK_LEVEL4_J21';Sensor="Spare Level";Channel= 13;Value=$null}
    )

    $Port.DiscardInBuffer()
    write-host Testing GPIO Input ...

    $port.writeline("IO W 9 1`r")
    start-sleep -Milliseconds 1000

    for($i=0;$i -lt $data.count;$i++){
        $data[$i].value = (gpio_read -port $port -channel $data[$i].channel -debug_on $debug_on)[1]
        start-sleep -Milliseconds 10

    }
    start-sleep -Milliseconds 1000
    $port.writeline("IO W 9 0`r")

    return $data
}

function i2c_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel
        )

    Write-host I2C Test Not yet implemented
}

function spi_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel
        )
    $Port.DiscardInBuffer()
    Write-host Testing SPI interface $Channel

    write-host 0x00 to Configuration Register 0x00
    $rabport.writeline("SPI W $channel 0x00 0x00`r")
    Start-Sleep -Milliseconds 10
    read_input_buffer -port $rabport -echo_on $echo_on -debug_on $debug_on

    write-host Read Configuration Register 0x00
    $rabport.writeline("SPI R $channel 0x00`r")
    Start-Sleep -Milliseconds 10
    $value1=read_input_buffer -port $rabport -echo_on $echo_on -debug_on $debug_on -strip_data $true
    write-host Value Written is $value1

    write-host 0x01 to Configuration Register 0x00
    $rabport.writeline("SPI W $channel 0x01 0x01`r")
    Start-Sleep -Milliseconds 10
    read_input_buffer -port $rabport -echo_on $echo_on -debug_on $debug_on

    write-host Read Configuration Register 0x00
    $rabport.writeline("SPI R $channel 0x00`r")
    Start-Sleep -Milliseconds 10
    $value2=read_input_buffer -port $rabport -echo_on $echo_on -debug_on $debug_on -strip_data $true
    write-host Value Written is $value2

    $Port.DiscardInBuffer()


    return
}

function i2c_mux{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0
        )
        
    $port.DiscardInBuffer()

    $port.writeline("IO W 39 1`r") #Make sure device is not in reset
    start-sleep -Milliseconds 50
    read_input_buffer -port $port -debug_on $debug_on

    switch ($channel){
        0 { $code = 1}
        1 { $code = 2}
        2 { $code = 4}
        default { write-host "Channel $channel not recognised";return 0}
    }
    write-host Setting I2C MUX to channel $channel...
    $port.writeline("I2C_MUX W $code`r")
    start-sleep -Milliseconds 50
    read_input_buffer -port $port -debug_on $debug_on

    $port.writeline("I2C_MUX R`r")
    start-sleep -Milliseconds 50
    $result=read_input_buffer -port $port -debug_on $debug_on -strip_data $true

    if($result -eq $code){
        write-host "Channel set to $channel"
        return $true
    }else{
        write-host "Error of result $result"
        return $false
    }

    
}

function flow_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0
        )
        
    $port.DiscardInBuffer()

    $port.writeline("IO W 22 0`r") #Turn power On
    start-sleep -Milliseconds 50
    read_input_buffer -port $port -debug_on $debug_on


    write-host Setting I2C MUX to channel $channel...
    $port.writeline("I2C R 2 0X80 0X00`r")
    start-sleep -Milliseconds 50
    read_input_buffer -port $port -debug_on $debug_on

    return
    
}

function pump_control{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 1,
        [bool] $on = $false,
        [bool] $off = $false,
        [int] $adc = 3000
        )
        
    $port.DiscardInBuffer()

    if($on){
        write-host Enable pump drive
        $port.writeline("IO W 33 1`r") #Enable Fan Global On
        read_input_buffer -port $rabPort -debug_on $true
    }

    $port.writeline("DAC W $channel 1 $adc`r") #Enable Fan Global On
    read_input_buffer -port $rabPort -debug_on $true
    
    if($off){
        write-host Disable pump drive
        $port.writeline("IO W 33 0`r") #Enable Fan Global On
        read_input_buffer -port $rabPort -debug_on $true
    }

    return
    
}

function fan_control{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0
        )
        
    $port.DiscardInBuffer()

    
    i2c_mux -port $port -channel 2 #Set I2C Mux

    $port.writeline("IO W 34 1`r") #Enable Fan Global On
    read_input_buffer

    # Set the fan controller to be in Manual RPM mode to test the Tacho input
    # Address is 0xA4

    # Read Status_Word (0x79)
    
    $port.writeline("I2C R 2 0x4A 0x99`r") # Read Manufacturers information (0x99) Should equal 0x4D
    read_input_buffer
    
    $port.writeline("I2C R 2 0x4A 0x00 0xFF`r") # Set page to all pages.
    read_input_buffer

    
    $port.writeline("I2C R 2 0x4A 0x3A 0xC0`r") # Set the Fan_config_1_2 command Byte (0x3A) = 0xC0 = Fan enable, RPM control, 1 Tach pulse per rev
    read_input_buffer

    $port.writeline("I2C R 2 0x4A 0x3B 0x7FFF`r") # Or set the FAN_COMMAND_1 = Set to 100% Duty Cycle = 0x7FFF
    read_input_buffer 

    #Set page to 12 for intertnal temp measurement

    #Set page to 17 for ADC value 0 Repeat for page 18,19,20,21,22

    write-host Not yet implemented

    return
    
}

function light_control{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0
        )
        
    $port.DiscardInBuffer()

    write-host Not yet implemented

    return
    
}

function usb_control{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0
        )
        
    $port.DiscardInBuffer()

    write-host Not yet implemented

    return
    
}


function pump_adc_read{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 0,
        [int] $sample_size = 100
        )


    $port.DiscardInBuffer()

    $return_data=@()
    

    #$port.writeline("ADC`r")

    for($i=0;$i -le $sample_size;$i++){
        $return = New-Object -TypeName psobject
        $port.writeline("ADC`r")
        $data=read_input_buffer -port $port -echo_on $echo_on -debug_on $debug_on -strip_data $true
        if($data.count -ne 3){write-host Error $data.count fields and should be 3}
        $return | Add-member -MemberType NoteProperty -Name Pressure -Value $data[0]
        $return | Add-member -MemberType NoteProperty -Name Current -Value $data[1]
        $return | Add-member -MemberType NoteProperty -Name Voltage -Value $data[2]

        $return_data+=$return
    }

    return $return_data
 }

 function pump_adc_test{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 1,
        [int] $sample_size = 100
        )


    $port.DiscardInBuffer()

    $return_data=@()
    $dac=4095

    #Set DAC Count to Max = 0V
    $port.writeline("DAC W $channel 1 $dac`r")
    read_input_buffer -port $port

    #Enable the Voltage Output

    $port.writeline("IO W 33 1`r")
    read_input_buffer -port $port
    
    #$data=pump_adc_read -port $Port -debug_on $false
    #$port.writeline("ADC`r")

    for($dac=3048;$dac -ge 2047; $dac=$dac-100){
        write-host Setting DAC to $dac
        $port.writeline("DAC W $channel 1 $dac`r")
        read_input_buffer -port $port -debug_on $debug_on
        start-sleep -Seconds 5

        for($i=0;$i -le $sample_size;$i++){
        #write-host Sampling data $i/$sample_size
        $return = New-Object -TypeName psobject
        $port.writeline("ADC`r")
        $data=read_input_buffer -port $port -echo_on $echo_on -debug_on $debug_on -strip_data $true
        if($data.count -ne 3){write-host Error $data.count fields and should be 3}
        $return | Add-member -MemberType NoteProperty -Name Channel -Value $channel
        $return | Add-member -MemberType NoteProperty -Name DAC -Value $dac
        $return | Add-member -MemberType NoteProperty -Name Sample -Value $i

        $return | Add-member -MemberType NoteProperty -Name Pressure -Value $data[0]
        $return | Add-member -MemberType NoteProperty -Name Current -Value $data[1]
        $return | Add-member -MemberType NoteProperty -Name Voltage -Value $data[2]

        $return_data+=$return
    }
    }
    
    #Set DAC Count to Max = 0V
    $dac=4095
    $port.writeline("DAC W $channel 1 $dac`r")
    read_input_buffer -port $port

    $port.writeline("IO W 33 0`r")
    read_input_buffer -port $port

    return $return_data
 }

 function pump_adc_test2{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 1,
        [int] $sample_size = 100
        )


    $port.DiscardInBuffer()

    $return_data=@()
    $VDrive=15

    $pwm=0.88
    $freq=20000

    #Set DAC Count to Max = 0V
    write-host Setting Vdrive to $vdrive
    #$port.writeline("boost $channel $Vdrive`r")
    $port.writeline("pumpd $channel $pwm $freq $Vdrive`r")
    $null=read_input_buffer -port $port -msec_pause 1000

    
    #Enable the Voltage Output

    #$port.writeline("IO W 33 1`r")
    #read_input_buffer -port $port
    
    #$data=pump_adc_read -port $Port -debug_on $false
    #$port.writeline("ADC`r")

    #for($Vdrive=0;$Vdrive -le 22; $Vdrive=$Vdrive+2){
    for($freq=18000;$freq -le 25000; $freq=$freq+20){
        write-host Setting VDrive to $VDrive
        #$port.writeline("boost $channel $Vdrive`r")
        $port.writeline("pumpd $channel $pwm $freq $Vdrive`r")
        $null=read_input_buffer -port $port -debug_on $debug_on -msec_pause 1000
        start-sleep -Seconds 5

        for($i=0;$i -lt $sample_size;$i++){
            #write-host Sampling data $i/$sample_size
            $return = New-Object -TypeName psobject
            $port.writeline("adc`r")
            $data=read_input_buffer -port $port -echo_on $echo_on -debug_on $debug_on -strip_data $true

            if($data.count -ne 6){write-host Error $data.count fields and should be 6 -ForegroundColor Red}
            $return | Add-member -MemberType NoteProperty -Name Channel -Value $channel
            $return | Add-member -MemberType NoteProperty -Name DAC -Value $dac
            $return | Add-member -MemberType NoteProperty -Name VDrive -Value $VDrive
            $return | Add-member -MemberType NoteProperty -Name Pwm -Value $pwm
            $return | Add-member -MemberType NoteProperty -Name Freq -Value $freq
            $return | Add-member -MemberType NoteProperty -Name Sample -Value $i

            $return | Add-member -MemberType NoteProperty -Name Voltage1 -Value ($data[0].split(" "))[0]
            $return | Add-member -MemberType NoteProperty -Name Current1 -Value ($data[1].split(" "))[0]
            $return | Add-member -MemberType NoteProperty -Name Pressure1 -Value ($data[2].split(" "))[0]

            $return_data+=$return
        }
    }
    
    #Set DAC Count to Max = 0V
    $Vdrive=0
    $freq=2000
    #$port.writeline("boost $channel $Vdrive`r")
    $port.writeline("pumpd $channel $pwm $freq $Vdrive`r")
    $null=read_input_buffer -port $port -debug_on $debug_on -msec_pause 1000

    #$port.writeline("IO W 33 0`r")
    #read_input_buffer -port $port

    return $return_data
 }

 function pressure_test2{
    param(
        [System.IO.Ports.SerialPort]$port,
        [bool] $echo_on = $true,
        [bool] $debug_on = $true,
        [int] $channel = 1,
        [int] $sample_size = 100
        )

    $VOffset=1.25
    $VSupply=2.5
    $Psi2mbar=68.9476
    $PsiFSS=30
    $Sensitivity=10.9

    $port.DiscardInBuffer()

    $return_data=@()


    for($i=0;$i -lt $sample_size;$i++){
            #write-host Sampling data $i/$sample_size
            $return = New-Object -TypeName psobject
            $port.writeline("adc`r")
            $data=read_input_buffer -port $port -echo_on $echo_on -debug_on $debug_on -strip_data $true

            if($data.count -ne 6){write-host Error $data.count fields and should be 6 -ForegroundColor Red}
            $return | Add-member -MemberType NoteProperty -Name Channel -Value $channel
            $return | Add-member -MemberType NoteProperty -Name Sample -Value $i

            $return | Add-member -MemberType NoteProperty -Name Voltage1 -Value ($data[0].split(" "))[0]
            $return | Add-member -MemberType NoteProperty -Name Current1 -Value ($data[1].split(" "))[0]
            $return | Add-member -MemberType NoteProperty -Name VPressure1 -Value ($data[2].split(" "))[0]
            $return | Add-member -MemberType NoteProperty -Name Pressure1 -Value ((((($data[2].split(" "))[0])-1.25)*1000)/0.63)

            $return_data+=$return
        }
    

    return $return_data
 }


