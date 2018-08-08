<#
	.SYNOPSIS
	PowerCLI get hba active and dead paths
	.EXAMPLE
	
	
	
	.NOTES
	raoconnor 08/08/18
	http://vblog.hochsticher.de/?p=334
	
	
#>


  <#
      .SYNOPSIS
      It shows the HBA's with it's Paths (Active, Dead)
      .DESCRIPTION
      You can check a single Host, a Cluster or even a DataCenter to show it's HBA's and their active paths.
      Check the Driver Name (and edit in Line 93) in case of trouble.
      .EXAMPLE

      Get-HostActiveStoragePaths -Host <host>
      Get-HostActiveStoragePaths -Host<host>-*
      Get-HostActiveStoragePaths -Cluster <Cluster>
      Get-HostActiveStoragePaths -DataCenter <Datacenter>

     .EXAMPLE Output

      VMHost  Device Active Dead
      ------  ------ ------  ----
      Host-01 vmhba1      0     4
      Host-01 vmhba2      4     0

   #>
   
   


  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$false, Position=0)]
    [System.String]
    $ESXHost = "",
    
    [Parameter(Mandatory=$false, Position=1)]
    [System.String]
    $Cluster = "",
    
    [Parameter(Mandatory=$false, Position=2)]
    [System.String]
    $DataCenter = ""
  )
  
  #Check which Variable is filled
  if([string]::IsNullOrEmpty($ESXHost)) {               
  } else {            
    #Write-Host "Set vobject" 
    $vobject = (Get-VMHost $ESXHost)  | Sort-Object -Property Name              
  }
  
  if([string]::IsNullOrEmpty($Cluster)) {             
  } else {            
    #Write-Host "Set vobject" 
    $vobject = (Get-Cluster $Cluster| Get-VMHost)  | Sort-Object -Property Name            
  }
  
  if([string]::IsNullOrEmpty($DataCenter)) {            
  } else {            
    #Write-Host "Set vobject"
    $vobject = (Get-DataCenter $DataCenter| Get-VMHost)  | Sort-Object -Property Parent,Name              
  }
  
 if([string]::IsNullOrEmpty($vobject)) {            
    Write-Host "Given string is NULL or EMPTY" -ForegroundColor Red
	Write-Host "Add variable: -ESXhost, -Cluster, -Datacenter:" -ForegroundColor Yellow
	Write-Host "Get-HostActiveStoragePaths -Host <host>" 
    Write-Host "Get-HostActiveStoragePaths -Cluster <Cluster>" 
    Write-Host "Get-HostActiveStoragePaths -DataCenter <Datacenter>" 
	
	
	}
	
  
  foreach($vmhost in ($vobject)){
    
    $esx = Get-VMHost -Name $vmhost
    $report = @()
    # fc or fnic for UCS VIC-Cards
    foreach($hba in ($esx.ExtensionData.Config.StorageDevice.HostBusAdapter | where{$_.Driver -match 'fc' -or  $_.Driver -match 'fnic'})){
      $paths = @()
      foreach($lun in $esx.ExtensionData.Config.StorageDevice.MultipathInfo.Lun){
        $paths += $lun.Path | where{$_.Adapter -match "$($hba.Device)" -and $_.Adapter -match 'FibreChannel'}
      }
      $groups = $paths | Group-Object -Property PathState
      $report += $hba | Select @{N='VMHost';E={$esx.Name}},Device,
      @{N='Active';E={($groups | where{$_.Name -eq 'active'}).Count}},
      @{N='Dead';E={($groups | where{$_.Name -eq 'dead'}).Count}}
    }
    Write-Host "Cluster: "$vmhost.Parent
    $report | ft -AutoSize
    
  }
