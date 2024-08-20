#######################################################################################
# FILE NAME:         EmailFunction
# DESCRIPTION:       Manipulate emails using a specific engineering test account
# OWNER:             Thomas Wood
# USAGE NOTES:       - All changes should keep backwards compatibility unless absoloutley
#                     neccessary
#                    - CTRL + M to collapse all regions
# KNOWN BUGS:        None
# SERIAL PARAMETERS: None
#######################################################################################


# Send-Email
#######################################################################################
# Description: Sends an email to the specified recipient. The IP of the computer running the
#              script that calls this function will need to be added to the exchange server (?).
#              Contact IT to help with this.
# Inputs:
#         $to              -> Recipient of email
#         $subject         -> Subject text of email
#         $body            -> Body text of email
#         $attachement     -> Attached documents
#
#######################################################################################
# Suggested use:
#
# $to = "thomas.wood@spectrummedical.com"
# $subject = "Powershell Email Test"
# $body = "Your test has finished!"
# $attachement = "C:\Users\thomas.wood\Desktop\Powershell\document.txt" or $attachment = (get-childitem ".\[$results_dir]").fullname
#
# Send an email through powershell (e.g. when testing has completed). If no attachment is to be sent, leave blank.
#

function Send-Email ($to, $subject, $body, $attachment){

    write-host ""

    $User = "svc-eng"
    $PWord = ConvertTo-SecureString -String "Spectrum123" -AsPlainText -Force

    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

    $From = "test@spectrum.local"

    $SMTPServer = "SM-EXCH.spectrum.local"
    $SMTPPort = "587"

    if($attachment -eq $null){

        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Credential $credential
        write-host "Email sent to $to`. " -NoNewline -ForegroundColor Cyan

    }
    else{

        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -Attachments $attachment -SmtpServer $SMTPServer -port $SMTPPort -Credential $credential

        write-host "Email sent to $to`. File $attachment was attached." -NoNewline -ForegroundColor Cyan

    }

    write-host ""

}
