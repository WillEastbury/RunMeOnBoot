# Define the path to the file crlf separated list of machines and the file to remove
$vmListFilePath = "C:\machine_list.txt"
$fileToRemove = "C$\windows\filenamepathhere.sys"

# Function to process each VM
function Process-VM {
    param (
        [string]$vmName
    )

    # Attempt to connect to the VM at 1-second intervals
    while ($true) {
        try {
            # Test the connection to the VM using ping
            if (Test-Connection -ComputerName $vmName -Count 1 -Quiet) {
                Write-Host "Connected to VM $vmName"

                # Construct the network path to the file
                $networkPath = "\\$vmName\$fileToRemove"

                # Remove the file
                Remove-Item -Path $networkPath -Force
                Write-Host "File removed from $vmName"
                break
            } else {
                Write-Host "Unable to connect to VM $vmName. Retrying in 1 second..."
                Start-Sleep -Seconds 1
            }
        } catch {
            Write-Host "Error connecting to VM $vmName: $_"
            Start-Sleep -Seconds 1
        }
    }
}

# Read the list of VMs from the file
$vmList = Get-Content -Path $vmListFilePath

# Loop through each VM and process it
foreach ($vmName in $vmList) {
    Write-Host "Processing VM: $vmName"
    Process-VM -vmName $vmName
}
