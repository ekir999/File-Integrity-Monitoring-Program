$logIntegrityFile = 'C:\Users\emiliokiryakos\OneDrive\Desktop\FIM (File Integrity Monitoring with Powershell)\integrity_log_file.txt'

$emailFrom = "1ek44253@gmail.com"
$emailTo = "1ek44253@gmail.com"
$emailSubject = "File Integrity Monitoring Alert"
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpUsername = "1ek44253@gmail.com"
$smtpPassword = "sq4kpt3fA!wowhoho1A!"

$constantMonitoredFolders = @(
    'C:\Users\emiliokiryakos\OneDrive\Desktop\FIM (File Integrity Monitoring with Powershell)\files'
)

function Write-LogEntry($message) {
    $logEntry = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
    Add-Content -Path $logIntegrityFile -Value $logEntry
}

function Get-FileHash($path) {
    return (Get-FileHash -Path $path -Algorthim SHA256).Hash
}

function Store-InitalHashes {
    $hashStore = @{}
    foreach ($folder in $constantMonitoredFolders) {
        Get-ChildItem -Path $folder -Recurse | ForEach-Object {
            $hashStore[$_.FullName] = Get-FileHash -path $_.FullName
        }
    }
    return $hashStore
}

function Check-FileIntegrity($initialHashes) {
    $changedFiles = @{}
    foreach ($folder in $constantMonitoredFolders) {
        Get-ChildItem -Path $folder -Recurse | ForEach-Object {
            $currentHash = Get-FileHash -path $_.FullName
            if ($initialHashes[$_.FullName] -ne $currentHash) {
                $changedFiles[$_.FullName] = $currentHash
                $message = "File changed: {0}" -f $_.FullName
                Write-LogEntry -message $message
                
                # Send email notification
                $emailBody = "The following file has been changed:`n`n{0}" -f $_.FullName
                Send-EmailNotification -message $emailBody
            }
        }
    }
    return $changedFiles
}

function Send-EmailNotification($message) {
    try {
        $emailBody = $message
        $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
        $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUsername, $smtpPassword)
        $mail = New-Object System.Net.Mail.MailMessage($emailFrom, $emailTo, $emailSubject, $emailBody)
        $smtp.Send($mail)
    }
    catch {
        Write-LogEntry -message "Failed to send email notification: $_"
    }
}

$scriptPath = $MyInvocation.MyCommand.Path
$initialScriptHash = Get-FileHash -Path $scriptPath -Algorithm SHA256

function Verify-ScriptIntegrity {
    $currentScriptHash = Get-FileHash -Path $scriptPath -Algorithm SHA256
    if ($currentScriptHash.Hash -ne $initialScriptHash.Hash) {
        $message = "The file integrity monitoring script has been tampered with!"
        Write-LogEntry -message $message
        Write-Host $message -ForegroundColor Red
        $emailBody = "The file integrity monitoring script has been tampered with!"
        Send-EmailNotification -message $emailBody
    }
}

# -------------------------------- Main Program -------------------------------- #
if ([string]::IsNullOrEmpty($smtpServer) -or
    [string]::IsNullOrEmpty($smtpUsername) -or
    [string]::IsNullOrEmpty($smtpPassword)) {
    Write-Host "Email notification is not configured. Please update the script with your SMTP settings." -ForegroundColor Yellow
} else {
    while ($true) {
        $input = Read-Host "Enter '1' (Constant Set of Files to Monitor) or 'q' to quit"
        if ($input -eq '1') {
            Write-Host "Creating Log File if it doesn't exist within the specified path"
            if (!(Test-Path -Path $logIntegrityFile)) {
                New-Item -Path $logIntegrityFile -ItemType File | Out-Null
            }
            Write-Host "Monitoring constant files and folders"
            $initialHashes = Store-InitalHashes
            while ($true) {
                $changedFiles = Check-FileIntegrity($initialHashes)
                if ($changedFiles.Count -gt 0) {
                    Write-Host "The following files have changed:"
                    $changedFiles.GetEnumerator() | ForEach-Object {
                        Write-Host $_.Key
                    }
                }
                Verify-ScriptIntegrity
                Start-Sleep -Seconds 3600
            }
        }
        elseif ($input -eq 'q') {
            Write-Host "Quitting"
            break
        }
        else {
            Write-Host "Invalid Command, Please try again"
        }
    }
}
# ------------------------------------------------------------------------------ #