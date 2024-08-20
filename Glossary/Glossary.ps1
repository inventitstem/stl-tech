#Get File location

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
$null = $FileBrowser.ShowDialog()

$folder=($FileBrowser.filename.split("\"))
$folder_path=$folder[0..($folder.count-2)] -join "\"
$outputFile_path=($folder_path,"glossary.csv") -join "\"

$documentPath=$FileBrowser.filename

#Open Word Document
$word = New-Object -ComObject Word.application

$document=$word.Documents.Open($documentPath)

$glossary=@() # Create Glossary Array

$entry = New-Object -TypeName psobject

write-host There are $document.tables.count tables
write-host There are $document.paragraphs.count paragraphs

#Load in Master Glossary
$masterGlossaryPath="Glossary_master.csv"
$masterGlossary = import-csv -path $masterGlossaryPath

#Scan through each document to get the Acronyms
$start = $false
for($i=1;$i -le $document.paragraphs.count;$i++){
    $text=$document.paragraphs[$i].range.Text
    $text=$text.trim()

    if($text -eq "References"){
        $start = $true
        write-host Start of document detected paragrph $i
    }
    
    if($start){ # Only log if passed the Glossary section
        $textArray=@($text.split())
        write-host Paragraph $i : $textarray.count : $text 
    
        for($j=0;$j -lt $textarray.count;$j++){
            $value=$textarray[$j].trim()
            $value=$value.trim(@("(",")","[","]","{","}",",",".",":"))
            if($value -ne $null -and $value){
                write-host $j $textarray[$j] $value
                if(($value -cmatch '^[A-Z0-9]*$') -and -not ($value -cmatch '^[0-9]*$')){
                    write-host $value
                    #$value | format-hex
                    #Read-Host
                    if(($glossary | where-object {$_.item -eq $value}).count -eq 0){
                        $entry = New-Object -TypeName psobject
                        $entry | Add-member -MemberType NoteProperty -Name Item -Value $value

                        #Check to see if it is in the master glossary
                        if(($MasterGlossary | where-object {$_.item -eq $value}).count -eq 0){
                            write-host $value is not in the Master Glossary
                            #Get the input
                            $description=read-host Enter description:
                            $ignore=read-host "Enter ignore (1/0):"
                            $entry | Add-member -MemberType NoteProperty -Name Description -Value $description
                            if($ignore -ne 1){$glossary+=$entry}

                            #Update master glossary
                            $MasterEntry = New-Object -TypeName psobject
                            $MasterEntry | Add-member -MemberType NoteProperty -Name Item -Value $value
                            $MasterEntry | Add-member -MemberType NoteProperty -Name Description -Value $description
                            $MasterEntry | Add-member -MemberType NoteProperty -Name Ignore -Value $ignore
                            $MasterGlossary+=$MasterEntry

                        }else{

                            if(@($MasterGlossary | where-object {$_.item -eq $value})[0].ignore -eq 1){
                                write-host $value is in the Master Glossary and set to ignore

                            }else{
                                $description=@($MasterGlossary | where-object {$_.item -eq $value})[0].description
                                $entry | Add-member -MemberType NoteProperty -Name Description -Value $description
                                write-host $value is in the Master Glossary
                                $glossary+=$entry


                            }

                        }

                    
                    }
                    #read-host 
                }
            }
        }
    }
    
    
}

if($start){
    $glossary | sort-object -Property item

    $glossary | sort-object -Property item | export-csv -path $outputFile_path -NoTypeInformation

    $MasterGlossary | sort-object -Property item | export-csv -path $masterGlossaryPath -NoTypeInformation
}else{
    write-host References not detected and start of document
}

$document.close()

#Of course when you are done with scripting, close Word
$word.Quit()