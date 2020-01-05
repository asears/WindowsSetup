

<#

    .Synopsis
    Converts a PowerShell object to a Markdown table.
    
    .Description
    Converts a PowerShell object to a Markdown table.

    .Parameter InputObject 
    PowerShell object to be converted
   
    .Example 
    ConvertTo-Markdown -InputObject (Get-Service)

    Converts a list of running services on the local machine to a Markdown table

    .Example
    ConvertTo-Markdown -InputObject (Import-CSV "C:\Scratch\lwsmachines.csv") | Out-File "C:\Scratch\file.markdown" -Encoding "ASCII"

    Converts a CSV file to a Markdown table

    .Example
    Import-CSV "C:\Scratch\lwsmachines.csv" | ConvertTo-Markdown | Out-File "C:\Scratch\file2.markdown" -Encoding "ASCII"

    Converts a CSV file to a markdown table via the pipeline.

    .Notes
    Ben Neise 10/09/14
    Aaron Calderon 06/09/2016 Added new line `n on each line printed

    #>
Function ConvertTo-Markdown {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]$collection
    )

    Begin {
        $items = @()
        $columns = @{}
    }

    Process {
        ForEach($item in $collection) {
            $items += $item

            $item.PSObject.Properties | %{
	        if ($_.Value -eq $null) {
		    $_.Value = ""
	        }
                if(-not $columns.ContainsKey($_.Name) -or $columns[$_.Name] -lt $_.Value.ToString().Length) {
                    $columns[$_.Name] = $_.Value.ToString().Length
                }
            }
        }
    }

    End {
        ForEach($key in $($columns.Keys)) {
            $columns[$key] = [Math]::Max($columns[$key], $key.Length)
        }

        $header = @()
        ForEach($key in $columns.Keys) {
            $header += ('{0,-' + $columns[$key] + '}') -f $key
        }
        $($header -join ' | ') + "" # `n for text files

        $separator = @()
        ForEach($key in $columns.Keys) {
            $separator += '-' * $columns[$key]
        }
        $($separator -join ' | ') + ""# `n for text files


        ForEach($item in $items) {
            $values = @()
            ForEach($key in $columns.Keys) {
                $values += ('{0,-' + $columns[$key] + '}') -f $item.($key)
            }
            $($values -join ' | ') + ""# `n for text files
        }
    }
} 
Set-Location -Path $env:SystemDrive\
Clear-Host
$Error.Clear()
Import-Module -Name posh-git -ErrorAction SilentlyContinue
if (-not($Error[0])) {
    $DefaultTitle = $Host.UI.RawUI.WindowTitle
    $GitPromptSettings.BeforeText = '('
    $GitPromptSettings.BeforeForegroundColor = [ConsoleColor]::Cyan
    $GitPromptSettings.AfterText = ')'
    $GitPromptSettings.AfterForegroundColor = [ConsoleColor]::Cyan
    function prompt {
        if (-not(Get-GitDirectory)) {
            $Host.UI.RawUI.WindowTitle = $DefaultTitle
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }
        else {
            $realLASTEXITCODE = $LASTEXITCODE
            Write-Host 'PS ' -ForegroundColor Green -NoNewline
            Write-Host "$($executionContext.SessionState.Path.CurrentLocation) " -ForegroundColor Yellow -NoNewline
            Write-VcsStatus
            $LASTEXITCODE = $realLASTEXITCODE
            return "`n$('$' * ($nestedPromptLevel + 1)) "
        }
    }
}
else {
    Write-Warning -Message 'Unable to load the Posh-Git PowerShell Module'
}

$computers = "mycomputer"

$array = @()

foreach($pc in $computers){

    $computername=$pc.computername

    #Define the variable to hold the location of Currently Installed Programs

    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 

    #Create an instance of the Registry Object and open the HKLM base key

    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername) 

    #Drill down into the Uninstall key using the OpenSubKey Method

    $regkey=$reg.OpenSubKey($UninstallKey) 

    #Retrieve an array of string that contain all the subkey names

    $subkeys=$regkey.GetSubKeyNames() 

    #Open each Subkey and use GetValue Method to return the required values for each

    foreach($key in $subkeys){

        $thisKey=$UninstallKey+"\\"+$key 

        $thisSubKey=$reg.OpenSubKey($thisKey) 

        $obj = New-Object PSObject

        $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername

        $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))

        $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))

        $obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))

        $obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))

        $array += $obj

    } 

}

#$array | Where-Object { $_.DisplayName } | select ComputerName, DisplayName, DisplayVersion, Publisher |  ConvertTo-Markdown |  Foreach {$_.TrimEnd()} | where {$_ -ne ""}

$array | Where-Object { $_.DisplayName } | select  DisplayName,Empty-String   | ConvertTo-Markdown |  Foreach {$_.TrimEnd()} | where {$_ -ne ""} | Sort-Object