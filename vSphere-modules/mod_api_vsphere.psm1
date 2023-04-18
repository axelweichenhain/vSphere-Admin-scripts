<#
    .SYNOPSIS
        Powershell module to use for scripts and interaction with vSphere components such as vCenter, vCloud Director and ESXi hosts.

    .DESCRIPTION
        This Module contains several functions which can be used to get access to vSpehre componets and to interact with a vSphere environment.
        
        Such as:
        - Connecting to one or more vCenters
        - Manipuilating VMs
        - Running Reports
        - etc.

    .EXAMPLE
        Import-Module "$PSScriptRoot\mod_api_vsphere.psm1"

    .OUTPUTS
        See documentational header of each function for detailed instructions on how to use them

    .LINK
        

    .NOTES

        Historie:
        v0.1        : 01.09.2020
                      erste laufende Version

        Author      : Axel Weichenhain
        last change : 01.09.2020
#>

function Connect-vCenter {
    <#
    .SYNOPSIS
        Function used to connect to a single specified vCenter.
        This function should be used for scripts running on container VMs as in Rancher.
        
    .DESCRIPTION
        This function can be used to connect to a single dedicated vCenter.
        E.g. to generate alamrs and sending them to Icinga.
        This function also retunrs the connection status to the given vCenter and generates an alarmstatus in case the connection fails.
        This alarm can be used in Icinga to see if the script using this function has been executed correctly.
     
    .NOTES

        Historie:
        v0.1        : 01.09.2020
                      erste laufende Version

        Author      : Axel Weichenhain
        last change : 01.09.2020

    .INPUTS
        none

    .OUTPUTS
        Retunrcode showing exit staus of function    
    
        Can be used as follows:
        if($vcenter_connection -notlike "*0*"){
            write-host "not connected"
            do stuff to exit script or whatever
        }
        else{
            write-host "connected"
            do the real stuff
        }

    .PARAMETER FQDN_VCENTER
        FQDN of vCenter which needs to bbe connected

    .PARAMETER USR_VCENTER
        Specifies ADM Account Name

    .PARAMETER PWD_VCENTER
        Specifies password

    .EXAMPLE
        $vcenter_connection = Connect-vCenter -fqdn_vcenter "hostname.domain.fqdn" -usr_vcenter "username" -pwd_vcenter "password" 
        or
        $vcenter_connection = Connect-vCenter "hostname.domain.fqdn" "username" "password" 

        Can also be used to connect to multiple vCenters even with sepearate user credentials by calling function seperately for each vCenter:
        $vcenter_connectionA = Connect-vCenter "hostname-a.domain.fqdn" "usernameA" "passwordA" 
        $vcenter_connectionB = Connect-vCenter "hostname-b.domain.fqdn" "usernameB" "passwordB" 

#>

    # defining parameters to use with function
    param (
        [Parameter(HelpMessage = "FQDN vCenter", Mandatory = $true, Position = 0)][string] $fqdn_vcenter, # FQDN of vCenter to connect (e.g.: hostname.domain.fqdn)
        [Parameter(HelpMessage = "Username", Mandatory = $true, Position = 1)][string] $usr_vcenter, # Username for vCenter connection 
        [Parameter(HelpMessage = "Password", Mandatory = $true, Position = 2)][string] $pwd_vcenter                 # Password for vCenter connection
    )
    # reset exit status
    $exitstatus = 0
    # connect to given vCenter
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tConnecting to vCenter: $($fqdn_vcenter)"
    connect-viserver -server $fqdn_vcenter -user $usr_vcenter -Password $pwd_vcenter -Force
    # checking if connected vCenter can be accessed and information can be reteived
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tTesting Connection to vCenter: $($fqdn_vcenter)"
    $connectioncheck = Get-Datacenter -Server $fqdn_vcenter 
    # if no information can be retreived
    if ($null -eq $connectioncheck) {
        # return critical icinga status
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tConnection failed for vCenter: $($fqdn_vcenter)"
        $exitstatus = 2
    }
    else {
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tSuccessfully connected to vCenter: $($fqdn_vcenter)"
        $exitstatus = 0
    }
    # return icinga exit status
    return $exitstatus
}

function Connect-vCenter_group {
    <#
    .SYNOPSIS
        Function used to connect to a all vCenters in a SSO environment.
        This function should be used for scripts running on container VMs as in Rancher.
        
    .DESCRIPTION
        This function can be used to connect to all prod vCenters in SSO environment.
        E.g. to generate alamrs and sending them to Icinga.
        This function also retunrs the connection status to the given vCenter and generates an alarmstatus in case the connection fails.
        This alarm can be used in Icinga to see if the script using this function has been executed correctly.
     
    .NOTES
        Historie:
        v0.1        : 01.09.2020
                      erste laufende Version

        Author      : Axel Weichenhain
        last change : 01.09.2020

    .INPUTS
        none

    .OUTPUTS
        Retunrcode showing exit staus of function    
    
        Can be used as follows:
        if($vcenter_connection -notlike "*0*"){
            write-host "not connected"
            do stuff to exit script or whatever
        }
        else{
            write-host "connected"
            do the real stuff
        }

    .PARAMETER USR_VCENTER
        Specifies ADM Account Name

    .PARAMETER PWD_VCENTER
        Specifies password

    .EXAMPLE
        $vcenter_connection = Connect-vCenter_group -usr_vcenter "username" -pwd_vcenter "password" 
        or
        $vcenter_connection = Connect-vCenter_group "username" "password" 

#>

    # paramter definition
    param (
        [Parameter(HelpMessage = "Username", Mandatory = $true, Position = 0)][string] $usr_vcenter, # Username for vCenter connection (e.g.: asl\adm.user)
        [Parameter(HelpMessage = "Password", Mandatory = $true, Position = 1)][string] $pwd_vcenter         # Password for vCenter connection
    )
    # resetting exit status
    $exitstatus = 0
    # list of all production vcenters in osssso.local
    $vcentersMCIVProd = @(
        "hostname-a.domain.fqdn",
        "hostname-b.domain.fqdn",
        "hostname-c.domain.fqdn"
    )
    # for each vcenter in vcenter list
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tConnecting to all SSO vCenters"
    foreach ($vcenter in $vcentersMCIVProd) {
        # connect to vcenter
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tConnecting to vCenter: $($vcenter)"
        connect-viserver -server $vCenter -user $usr_vcenter -Password $pwd_vcenter -Force
        # checking if data can be retreived
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tChecking Connection to vCenter: $($vcenter)"
        $connectioncheck = Get-Datacenter -Server $vcenter
        # if no data can be retrieved
        if ($null -eq $connectioncheck) {
            write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tConnection failed for vCenter: $($vcenter)"
            # set exit status to "critical" for optional use in icinga
            $exitstatus = 2
            # disconnect all vcenters which have been already connected
            write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tDisconnecting all vCenter which have been connected so far"
            Disconnect-AllVC
            # return exit code for later use in calling script
            return $exitstatus
            # exit function
            break
        }
    }
}

function Disconnect-AllVC {
    <#
    .SYNOPSIS
        Function used disconnect from ALL connected vCenters
        
    .DESCRIPTION
        This function can be used to disconnect from ALL vCenters
        
    .NOTES
        Historie:
        v0.1        : 01.09.2020
                      erste laufende Version

        Author      : Axel Weichenhain
        last change : 01.09.2020

    .INPUTS
        none

    .OUTPUTS
        none

    .PARAMETER NONE
    
    .EXAMPLE
        Disconnect-AllVC

    #>
    
    # disconnect all vCenters
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tDisconnecting..."
    Disconnect-VIServer * -Confirm:$false
}

function Get-VMFolderPath {  
    <#
    .SYNOPSIS
        Function used to get folder name of specified VM-object (can be multiple VMs)

    .DESCRIPTION
        This function can be used to get the folder name where a given VM lies in.

    .EXAMPLE
        $folder = get-vm -name "vmname" | get-VMFolderPath
        $folder = get-vm | get-VMFolderPath

    .OUTPUTS
        Folder name of given VM

    .NOTES

        Historie:
        v0.1        : 01.09.2020
                      erste laufende Version

        Author      : Axel Weichenhain
        last change : 01.09.2020
    #>

    Begin {} 
    Process {  
        foreach ($vm in $Input) {  
            write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tGetting folderpath for VM: $($vm)"
            $DataCenter = $vm | Get-Datacenter  
            $DataCenterName = $DataCenter.Name  
            $VMname = $vm.Name  
            $VMParentName = $vm.Folder  
            if ($VMParentName.Name -eq "vm") {  
                $FolderStructure = "{0}\{1}" -f $DataCenterName, $VMname  
                $FolderStructure  
                Continue  
            }
            else {  
                $FolderStructure = "{0}\{1}" -f $VMParentName.Name, $VMname  
                $VMParentID = Get-Folder -Id $VMParentName.ParentId  
                do {  
                    $ParentFolderName = $VMParentID.Name  
                    if ($ParentFolderName -eq "vm") {  
                        $FolderStructure = "$DataCenterName\$FolderStructure"  
                        $FolderStructure  
                        break  
                    } 
                    $FolderStructure = "$ParentFolderName\$FolderStructure"  
                    $VMParentID = Get-Folder -Id $VMParentID.ParentId  
                }
                until ($VMParentName.ParentId -eq $DataCenter.Id) 
            } 
        } 
    } 
    End {} 
} 

function Get-InventoryPlus {
    [cmdletbinding()]
    param(
        [VMware.VimAutomation.ViCore.Types.V1.VIServer]$Server = $Global:DefaultVIServer,
        [String]$NoValue = ''
    )
    function Get-ViBlueFolderPath {
        [cmdletbinding()]
        param(
            [VMware.Vim.ManagedEntity]$Item
        )
        $hidden = 'Datacenters', 'vm'
        if ($Item -is [VMware.Vim.VirtualMachine]) {
            $Item.UpdateViewData('Parent')
            $parent = $Item.Parent  
        }
        elseif ($Item -is [VMware.Vim.VirtualApp]) {
            $Item.UpdateViewData('ParentFolder')
            $parent = $Item.ParentFolder
        }
        if ($parent) {
            $path = @($Item.Name)
            while ($parent) {
                $object = Get-View -Id $parent -Property Name, Parent
                if ($hidden -notcontains $object.Name) {
                    $path += $object.Name
                }
                if ($object -is [VMware.Vim.VirtualApp]) {
                    $object.UpdateViewData('ParentFolder')
                    if ($object.ParentFolder) {
                        $parent = $object.ParentFolder
                    }
                    else {
                        $object.UpdateViewData('ParentVapp')
                        if ($object.ParentVapp) {
                            $parent = $object.ParentVapp
                        }
                    }
                }
                else {
                    $parent = $object.Parent
                }
            }
            [array]::Reverse($path)
            return "/$($path -join '/')"
        }
        else {
            return $NoValue
        }
    }
    function Get-ObjectInfo {
        [cmdletbinding()]
        param(
            [parameter(ValueFromPipeline)]
            [VMware.Vim.ManagedEntity]$Object
        )
        Begin {
            $hidden = 'Datacenters', 'vm', 'host', 'network', 'datastore', 'Resources'
        }
        Process {
            if ($hidden -notcontains $Object.Name) {
                $props = [ordered]@{
                    Name     = $Object.Name
                    Type     = $Object.GetType().Name
                    BluePath = $NoValue
                }
                $blueFolder = $false
                $isTemplate = $false
                if ($object -is [VMware.Vim.Folder]) {
                    $object.UpdateViewData('ChildType')
                    if ($Object.ChildType -contains 'VirtualMachine') {
                        $blueFolder = $true
                    }
                }
                $path = @($Object.Name)
                $parent = $Object.Parent
                if ($object -is [VMware.Vim.VirtualMachine] -or $object -is [VMware.Vim.VirtualApp]) {
                    $props['BluePath'] = Get-VIBlueFolderPath -Item $Object
                    if ($Object -is [VMware.Vim.VirtualMachine]) {
                        $Object.UpdateViewData('ResourcePool', 'Config.Template')
                        if ($Object.Config.Template) {
                            $parent = $Object.Parent
                            $props['Type'] = 'Template'
                            $isTemplate = $true
                        }
                        else {
                            $parent = $Object.ResourcePool
                        }
                    }
                }
                while ($parent) {
                    $Object = Get-View -Id $Parent -Property Name, Parent
                    $parent = $Object.Parent
                    if ($hidden -notcontains $Object.Name) {
                        $path += $Object.Name
                    }
                }
                [array]::Reverse($path)
                $path = "/$($path -join '/')"
                $props.Add('Path', $path)
                if ($blueFolder) {
                    $props['BluePath'] = $props['Path']
                    $props['Path'] = $NoValue        
                }     
                if ($isTemplate) {
                    $props['Path'] = $NoValue
                }
                New-Object PSObject -Property $props
            }
        }
    }

    $sView = @{
        Id       = 'ServiceInstance'
        Server   = $Server
        Property = 'Content.ViewManager', 'Content.RootFolder'
    }
    $si = Get-view @sView
    $viewMgr = Get-View -Id $si.Content.ViewManager
    $contView = $viewMgr.CreateContainerView($si.Content.RootFolder, $null, $true)
    $contViewObj = Get-View -Id $contView
    Get-View -Id $contViewObj.View -Property Name, Parent | Where-Object { $hidden -notcontains $_.Name } | Get-ObjectInfo
}

Function Enable-MemHotAdd($vm) {
    $vmview = Get-vm $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "mem.hotadd"
    $extra.Value = "true"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Disable-MemHotAdd($vm) {
    $vmview = Get-VM $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "mem.hotadd"
    $extra.Value = "false"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Enable-vCpuHotAdd($vm) {
    $vmview = Get-vm $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "vcpu.hotadd"
    $extra.Value = "true"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Disable-vCpuHotAdd($vm) {
    $vmview = Get-vm $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "vcpu.hotadd"
    $extra.Value = "false"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Enable-vCpuHotRemove($vm) {
    $vmview = Get-vm $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "vcpu.hotremove"
    $extra.Value = "true"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Disable-vCpuHotRemove($vm) {
    $vmview = Get-vm $vm | Get-View 
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    $extra = New-Object VMware.Vim.optionvalue
    $extra.Key = "vcpu.hotremove"
    $extra.Value = "false"
    $vmConfigSpec.extraconfig += $extra

    $vmview.ReconfigVM_Task($vmConfigSpec)
}

Function Disable-MemReservation($vm) {
    $vmview = Get-vm $vm | Get-View 
    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.MemoryAllocation = New-Object VMware.Vim.ResourceAllocationInfo
    $spec.MemoryAllocation.Reservation = 0
    $spec.DeviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (0)
    $spec.MemoryReservationLockedToMax = $false
    $spec.CpuFeatureMask = New-Object VMware.Vim.VirtualMachineCpuIdInfoSpec[] (0)
    $vmview.ReconfigVM_Task($spec)
}

Function Disable-CPUReservation($vm) {
    Get-VM -Name $vm | Get-VMResourceConfiguration | Set-VMResourceConfiguration -CpuReservationMhz 0 -ErrorAction SilentlyContinue
}

Function Get-VIScheduledTasks {
    <# 
        .SYNOPSIS 
            Funktion zum Auslesen von Scheduled Tasks im vCenter
    
        .DESCRIPTION 
            Diese Funktion kann verwendet werden, um in einem vCenter alle geplanten Tasks auszulesen
    
        .NOTES  
            Historie:   v0.1    : 26.08.2021
                                  erste laufende Version
                            
            Author :    Axel Weichenhain, CC IT-Infrastructure
            
            last change         : 26.08.2021
                                  Dokumentation des Skripts
                                
        .INPUTS 
            keine
    
        .OUTPUTS 
            keine
    
        .PARAMETER Full
            # Note: When returning the full View of each Scheduled Task, all date times are in UTC
    
        .EXAMPLE
            # To find all tasks that failed to execute last run
            Get-VIScheduledTasks | ?{$_.State -ne 'success'}
    #>
    PARAM ( [switch]$Full )
    
    # Wenn Parameter Full angegeben wurde
    if ($Full) {
        # Komplette Informationen aller Scheduled Tasks im vCenter abrufen
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tParameter FULL being used to get all Task information"
        (Get-View ScheduledTaskManager).ScheduledTask | ForEach-Object { (Get-View $_).Info } 
    }
    # Wenn kein Parameter angegeben wurde
    else {
        # Holt nur die allgemeinen Header und konvertiert alle Date/Times entsprechend der lokalen Einstellungen
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tGetting Task information"
        (Get-View ScheduledTaskManager).ScheduledTask | ForEach-Object { (Get-View $_ -Property Info).Info } |
        Select-Object Name, Description, Enabled, Notification, LastModifiedUser, State, Entity,
        @{N = "EntityName"; E = { (Get-View $_.Entity -Property Name).Name } },
        @{N = "LastModifiedTime"; E = { $_.LastModifiedTime.ToLocalTime() } },
        @{N = "NextRunTime"; E = { $_.NextRunTime.ToLocalTime() } },
        @{N = "PrevRunTime"; E = { $_.LastModifiedTime.ToLocalTime() } },
        @{N = "ActionName"; E = { $_.Action.Name } }
    }
}
    
Function Get-VMScheduledSnapshots {
    <# 
        .SYNOPSIS 
            Funktion zum Auslesen von Scheduled Snapshots im vCenter
    
        .DESCRIPTION 
            Diese Funktion kann verwendet werden, um in einem vCenter alle geplanten Snapshot Tasks auszulesen
    
        .NOTES  
            Historie:   v0.1    : 26.08.2021
                                  erste laufende Version
                            
            Author :    Axel Weichenhain, CC IT-Infrastructure
            
            last change         : 26.08.2021
                                  Dokumentation des Skripts
                                
        .INPUTS 
            keine
    
        .OUTPUTS 
            keine
    
        .PARAMETER keine
    
        .EXAMPLE
            # To find all snapshots that are not scheduled to run again:
            Get-VMScheduledSnapshots | ?{$_.NextRunTime -eq $null}
    #>
    # Holt alle Scheduled Tasks vom Typ "CrateSnapshot_Task" mit Info VMName, Taskname, nächste Ausführung und Mailadresse für Benachrichtigung
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tGetting all scheduled tasks with type CREATESNAPSHOT"
    Get-VIScheduledTasks | Where-Object { $_.ActionName -eq 'CreateSnapshot_Task' } | Select-Object @{N = "VMName"; E = { $_.EntityName } }, Name, NextRunTime, Notification
}
    
Function New-VMScheduledSnapshot {
    <#    
        .SYNOPSIS 
            Funktion zum Erstellen von Scheduled Snapshot Tasks im vCenter
    
        .DESCRIPTION 
            Diese Funktion kann verwendet werden, um in einem vCenter geplante Tasks anzulegen, um Snapshots zu erstellen
    
        .NOTES  
            Historie:   v0.1    : 26.08.2021
                                  erste laufende Version
                            
            Author :    Axel Weichenhain, CC IT-Infrastructure
            
            last change         : 26.08.2021
                                  Dokumentation des Skripts
                                
        .INPUTS 
            keine
    
        .OUTPUTS 
            keine
    
        .PARAMETER vmName
            Gibt den Namen der VM an, für die ein Task eingerichtet werden soll
    
        .PARAMETER runTime
            Gibt Datum und Uhrzeit an, zu der der Task ausgeführt werden soll
    
        .PARAMETER notifyEmail
            gibt die Notification Mail Adresse an, an die eine Info gehen soll
    
        .PARAMETER taskname
            Gibt den Namen des Tasks an
            Standard ist: Admin-Script Scheduled Snapshot <Datum der Skriptausführung>
    
        .PARAMETER SnapKeep
            Gibt an, wie lange der Snapshot aufbewahrt werden soll (KEEP24, KEEP48, KEEP72)
    
        .EXAMPLE
            # Create a snapshot of the VM test002 at 9:40AM on 3/2/13
            New-VMScheduledSnapshot test002 "3/2/13 9:40AM"
    
            # Create a snapshot and send an email notification
            New-VMScheduledSnapshot test002 "3/2/13 9:40AM" myemail@mydomain.com
    
            # Use all of the options and name the parameters
            New-VMScheduledSnapshot -vmname 'test001' -runtime '3/2/13 9:40am' -notifyemail 'myemail@mydomain.com' -taskname 'My scheduled task of test001'
    #>
    # Parameterabfrage für Funktion
    PARAM (
        [string]$vmName, # Name der VM
        [string]$runTime, # Datum / Uhrzeot für nächste Ausführung
        [string]$notifyEmail = $null, # Mailadresse, die bei Ausführung informiert werden soll
        [string]$taskName = "$vmName - Admin-Script Scheduled Snapshot - $date", # Name des Tasks (Name der VM - Beschreibung - Date/Time Ausführung Skript)
        [string]$SnapKeep = "KEEP24" # Dauer der Aufbewahrng des Snapshots (Snapshot Description)
    )
        
    # Überprüfen, ob es die genannte VM überhaupt gibt.
    $vm = (get-view -viewtype virtualmachine -property Name -Filter @{"Name" = "^$($vmName)$" }).MoRef
    # wenn es die VM nicht gibt, abbrechen
    if (($vm | Measure-Object).Count -ne 1 ) { "Unable to locate a specific VM $vmName"; break }
        
    # Überprüfung von übergebener Date/Time und Konvertierung in UTC, wenn icht möglich abbrechen
    try { $castRunTime = ([datetime]$runTime).ToUniversalTime() } catch { "Unable to convert runtime parameter to date time value"; break }
    # wenn Date/Time in der Vergangenheit liegt, abbrechen
    if ( [datetime]$runTime -lt (Get-Date) ) { "Single run tasks can not be scheduled to run in the past. Please adjust start time and try again."; break }
        
    # Prüfen, ob es schon einen Task mit dem gleichen Namen gibt. Wenn ja, abbrechen
    if ( (Get-VIScheduledTasks | Where-Object { $_.Name -eq $taskName } | Measure-Object).Count -eq 1 ) { "Task Name `"$taskName`" already exists. Please try again and specify the taskname parameter"; break }
        
    # Neue Konfigurationsspezifikation zusammenbauen
    $spec = New-Object VMware.Vim.ScheduledTaskSpec
    $spec.name = $taskName # Name des Tasks
    $spec.description = "Snapshot of $vmName scheduled for $runTime" # Beschreibung des Tasks
    $spec.enabled = $true # Task enablen
    if ( $notifyEmail ) { $spec.notification = $notifyEmail } # WEnn Benachrichtigungsmail angegeben wurde, diese setzen
    ($spec.scheduler = New-Object VMware.Vim.OnceTaskScheduler).runAt = $castRunTime # Date/Time für nächste Ausführung setzen
    ($spec.action = New-Object VMware.Vim.MethodAction).Name = "CreateSnapshot_Task" # Neuen Task vom Typ CreateSnapshot_Task erstellen
    $spec.action.argument = New-Object VMware.Vim.MethodActionArgument[] (4) # Argumente übergeben
    ($spec.action.argument[0] = New-Object VMware.Vim.MethodActionArgument).Value = "$vmName - Admin-Script Scheduled Snapshot - $date" # Taskname
    ($spec.action.argument[1] = New-Object VMware.Vim.MethodActionArgument).Value = $snapkeep # Task Beschreibung (Aufbewahrungsdauer)
    ($spec.action.argument[2] = New-Object VMware.Vim.MethodActionArgument).Value = $false # Angabe, ob RAM mit gesnapshottet werden soll
    ($spec.action.argument[3] = New-Object VMware.Vim.MethodActionArgument).Value = $false # Angebe, ob Quiescing erfolgen soll (benötigt VMware Tools)
    # Task erzeugen
    [Void](Get-View -Id ‘ScheduledTaskManager-ScheduledTaskManager’).CreateScheduledTask($vm, $spec)
    # Prüfen, ob Task angelegt wurde
    Get-VMScheduledSnapshots | Where-Object { $_.Name -eq $taskName }
}
    
Function Remove-VIScheduledTask {
    <#   
        .SYNOPSIS 
            Funktion zum Löschen von Scheduled Tasks im vCenter
    
        .DESCRIPTION 
            Diese Funktion kann verwendet werden, um in einem vCenter geplante Tasks zu löschen
    
        .NOTES  
            Historie:   v0.1    : 26.08.2021
                                  erste laufende Version
                            
            Author :    Axel Weichenhain, CC IT-Infrastructure
            
            last change         : 26.08.2021
                                  Dokumentation des Skripts
                                
        .INPUTS 
            keine
    
        .OUTPUTS 
            keine
    
        .PARAMETER keine
            
    
        .EXAMPLE
            # This example will find all VM Scheduled Snapshots which 
            # are not scheduled to run again, then remove each one by name.
            Get-VMScheduledSnapshots | ?{$_.NextRunTime -eq $null} | %{ Remove-VIScheduledTask $_.Name }
            
    #>
    # Parameterabfrage für Funktion
    PARAM ([string]$taskName) # Name des zu löschenden Tasks
    # Angegebenen Task löschen
    (Get-View -Id ((Get-VIScheduledTasks -Full | Where-Object { $_.Name -eq $taskName }).ScheduledTask)).RemoveScheduledTask()
}

function RemoveDS {
    <#
    .SYNOPSIS
        Funktion zur sauberen Entferung einer LUN

    .DESCRIPTION
        Diese Funktion kann verwenet werden, um eine, oder mittels einer Schleife alle, Datasstoress zu entfernen

    .NOTES

        Historie:
        v0.1        : 14.11.2020
                      erste laufende Version
 
        Author      : Axel Weichenhain
        
        last change : 14.11.2020
                      Anpassung Skript und Einführung Modus A und B
    #>

    PARAM (
        [string]$datastore # Name des Datastores
    )
    $exitstatus = 0
    # Storage IO Control zurücksetzen
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tRessetting SSIOC for Datastore:`t$($datastore)"
    get-datastore $datastore | Set-Datastore -StorageIOControlEnabled $false
    # Host Cluster ermitteln, an denen der Datastore hängt
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tGetting all DRS Cluster where Datastore is presented to"
    $hostclusters = Get-Datastore $datastore | Get-VMHost | Get-Cluster
    if ($hostclusters.count -gt 1) {
        $exitstatus = 2
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tERROR: Datastore is presented to more than one DRS Clusster. Exiting Script!"
        return $exitstatus
        break
    }
    else {
        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tFound only one Cluster - continueing"
        # Create one time use array
        $obj = @()
        # Create the array headers
        $obj = "" | Select-Object Datastore, Cluster, Missinghosts 
        # Get each host in the cluster this datastore is presented to
        $dshosts = Get-Datastore $datastore | Get-VMHost | Where-Object { $_.Parent -eq $hostclusters } 
        # Get all hosts in the cluster
        $clusterhosts = Get-Cluster $hostclusters | Get-VMHost 
        # Compare all hosts in the cluster to the hosts the datastore is presented to
        $missinghosts = Compare-Object -ReferenceObject $clusterhosts -DifferenceObject $dshosts -PassThru 
        # If there are several missing hosts, the output of Compare-Object will be an array which isn't CSV friendly. This just breaks the array apart and delimits with a semicolon
        $missinghosts = $missinghosts -join ';' 
        # if there are misssing hosts
        if ($missinghosts) {
            $exitstatus = 2
            write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tERROR: Datastore is missing on Hosts:`t$($missinghosts)"
            return $exitstatus
            break
        }
        else {
            $current_host = 0
            foreach ($esx in $dshosts) {
                $current_ds = 0
                $current_host += 1
                write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tWorking on ESXi-Host $($current_host) of $($dshosts.count):`t$($esx.name)"
                # Für jeden Datastore 
                foreach ($datastore in $datastores) {
                    $current_ds += 1
                    # Hole Datastore des aktuellen ESX
                    $dsesx = Get-Datastore $datastore -RelatedObject $esx
                    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tWorking on Datastore $($current_ds) of $($datastores.count):`t$($dsesx)"
                    # Hole Canonical Name
                    $canonicalName = $dsesx.ExtensionData.Info.Vmfs.Extent[0].DiskName
                    # Hole Storeage Infos
                    $storSys = Get-View $esx.Extensiondata.ConfigManager.StorageSystem
                    # Hole Device passend zum Canonical Name
                    $device = $storsys.StorageDeviceInfo.ScsiLun | where-object { $_.CanonicalName -eq $canonicalName }
                    # Wenn mit Device alles OK
                    if ($device.OperationalState[0] -eq 'ok') {
                        # unmount disk
                        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tUnmounting Datastore:`t$($dsesx)"
                        $StorSys.UnmountVmfsVolume($dsesx.ExtensionData.Info.Vmfs.Uuid)
                        # Detach disk
                        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tDetaching Datastore:`t$($dsesx)"
                        $storSys.DetachScsiLun($device.Uuid)
                    }   
                    else {
                        write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tSkipping Datastore as is is not operational:`t$($dsesx)"
                    }
                }
            }
        } 
    }
    # Wenn alle Datastores aus Liste auf allen Hosts abgearbeitet wurden, Rescan der HBAs durchführen, um Anzeige zu aktualisieren
    write-output "$(Get-Date)`t$((Get-PSCallStack)[0].Command)`tRescanning all HBAs in Cluster:`t$($hostclusters)"
    $clusterhosts | Get-VMHostStorage -RescanAllHba -RescanVmfs
    return $exitstatus
}

function Get-DatastoreCompliance {
    $objReport = @() 
    $datastores = Get-Datastore #Gather all Datastores for this vCenter
    foreach ($datastore in $datastores) {
        $hostclusters = Get-Datastore $datastore | Get-VMHost | Get-Cluster #Get each cluster this datastore is presented to
        foreach ($hostcluster in $hostclusters) {
            $obj = @() #Create one time use array
            $obj = "" | Select-Object Datastore, Cluster, Missinghosts #Create the array headers
            $dshosts = Get-Datastore $datastore | Get-VMHost | Where-Object { $_.Parent -eq $hostcluster } #Get each host in the cluster this datastore is presented to
            $clusterhosts = Get-Cluster $hostcluster | Get-VMHost #Get all hosts in the cluster
            $missinghosts = Compare-Object -ReferenceObject $clusterhosts -DifferenceObject $dshosts -PassThru #Compare all hosts in the cluster to the hosts the datastore is presented to
            $missinghosts = $missinghosts -join ';' #If there are several missing hosts, the output of Compare-Object will be an array which isn't CSV friendly. This just breaks the array apart and delimits with a semicolon
            if (!$missinghosts) {
                $missinghosts = "None"
            } #If no hosts are missing, enter "None" instead of a blank value
            $obj.Datastore = $datastore #Add the datastore name to the array
            $obj.Cluster = $hostcluster #Add the ESXi Cluster name to the array
            $obj.Missinghosts = $missinghosts #Add the missing hosts to the array
            $objReport += $obj #Add values from one time use array to the function's output array
        }
    }
    $objReport #Output the final array
}
    