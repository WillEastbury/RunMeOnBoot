#!/bin/bash

# Define variable for resource group
RESOURCE_GROUP="PUTYOURRGNAMEHERE"
COMMAND="rm deletethisfile"

# Function to get the power state of a VM
get_vm_power_state() {
    local vm_name=$1
    az vm show -d --query "powerState" --name "$vm_name" -g "$RESOURCE_GROUP" -o tsv
}

# Function to get the VM agent status time
get_vm_agent_status_time() {
    local vm_name=$1
    az vm get-instance-view --name "$vm_name" -g "$RESOURCE_GROUP" --query "instanceView.vmAgent.statuses[0].time" -o tsv
}

# Function to process each VM
process_vm() {
    local vm_name=$1

    # Wait until the VM is "Running"
    while true; do
        power_state=$(get_vm_power_state "$vm_name")
        if [ "$power_state" == "VM running" ]; then
            break
        else
            echo "Waiting for VM $vm_name to be in 'Running' state. Current state: $power_state"
            sleep 3
        fi
    done

    # Get the initial agent status time
    initial_agent_status_time=$(get_vm_agent_status_time "$vm_name")
    echo "Initial agent status time for VM $vm_name: $initial_agent_status_time"

    # Wait until the agent status time is incrementing
    while true; do
        current_agent_status_time=$(get_vm_agent_status_time "$vm_name")
        echo "Current agent status time for VM $vm_name: $current_agent_status_time"
        if [ "$initial_agent_status_time" != "$current_agent_status_time" ]; then
            break
        else
            echo "Waiting for agent status time to increment for VM $vm_name..."
            sleep 1
        fi
    done

    # Execute the command once the conditions are met
    echo "Conditions met for VM $vm_name. Executing the command."
    az vm run-command invoke --command-id RunPowerShellScriptcs --name "$vm_name" -g "$RESOURCE_GROUP" --scripts "$COMMAND"
}

# Get the list of all VMs in the resource group
vm_list=$(az vm list -g "$RESOURCE_GROUP" --query "[].name" -o tsv)

# Loop through each VM and process it
for vm_name in $vm_list; do
    echo "Processing VM: $vm_name"
    process_vm "$vm_name"
done

