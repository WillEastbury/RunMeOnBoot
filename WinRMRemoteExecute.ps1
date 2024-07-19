# This code is completely untested - i have no domain joined winrm machines - but it might work on premises. 
# Use at your own risk. 

# Define the path to the file crlf separated list of machines and the file to remove
$vmListFilePath="C:\machine_list.txt"
$fileToRemove="C:\filenamepathhere.sys"
# Define the PowerShell command to execute on each VM
$commandToExecute = { param($vmName) Write-Host "Executing command on $vmName"; Remove-Item -Path "$fileToRemove" }

# Function to process each VM
function Process-VM {
    param (
        [string]$vmName,
        [scriptblock]$command
    )

    # Attempt to connect to the VM at 1-second intervals
    while ($true) {
        try {
            # Test the connection to the VM
            Test-Connection -ComputerName $vmName -Count 1 -ErrorAction Stop
            Write-Host "Connected to VM $vmName"

            # Execute the command on the VM
            Invoke-Command -ComputerName $vmName -ScriptBlock $command -ArgumentList $vmName
            break
        } catch {
            Write-Host "Unable to connect to VM $vmName. Retrying in 1 seconds..."
            Start-Sleep -Seconds 1
        }
    }
}

# Read the list of VMs from the file
$vmList = Get-Content -Path $vmListFilePath

# Loop through each VM and process it
foreach ($vmName in $vmList) {
    Write-Host "Processing VM: $vmName"
    Process-VM -vmName $vmName -command $commandToExecute
}
