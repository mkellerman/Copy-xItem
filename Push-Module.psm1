

function Push-Module {

<#

.SYNOPSIS

    Push Module to a Remote Session.

.DESCRIPTION

    Push Module to a Remote Session. 

    By Marc R Kellerman (@mkellerman)

    Original Code from: 
    https://stackoverflow.com/questions/14441800/how-to-import-custom-powershell-module-into-the-remote-session
    
.PARAMETER Session

    Specifies an array of sessions in which this cmdlet runs the command. Enter a variable that contains PSSession objects or a command that creates or gets the PSSession objects, such as a New-PSSession or Get-PSSession command.
        
    When you create a PSSession , Windows PowerShell establishes a persistent connection to the remote computer. Use a PSSession to run a series of related commands that share data. To run a single command or a series of unrelated commands, use the 
    ComputerName parameter. For more information, see about_PSSessions.
        
.PARAMETER Name

    Specifies the names of the modules to push. Enter the name of the module or the name of a file in the module, such as a .psd1, .psm1, .dll, or ps1 file. File paths are optional. Wildcard characters are not permitted. 
        
    If you omit a path, Push-Module looks for the module in the paths saved in the PSModulePath environment variable ($env:PSModulePath).
        
    Specify only the module name whenever possible. When you specify a file name, only the members that are implemented in that file are copied. If the module contains other files, they are not pushed, and you might be missing important members of 
    the module.
        
#>

    Param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $False)]
        [switch]$Persist        
    )

    function Copy-File ($Session, $FilePath, $DestinationPath) {

        $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($FilePath))
        Invoke-Command -Session $Session -ScriptBlock {
            [IO.File]::WriteAllBytes($Using:DestinationPath, [Convert]::FromBase64String($Using:base64string))
        }

    }

    Try {

        $PSModuleInfo = Get-Module -Name $Name
        If (!$PSModuleInfo) { Throw "Push-Module : The specified module '$Name' was not pushed because no valid module file was found in any module directory."; Return }

        $ModuleName = $PSModuleInfo.Name
        $ModuleBase = Get-ChildItem -Path $PSModuleInfo.ModuleBase | Select -Expand FullName
        $RemoteBase = Invoke-Command -Session $Session -ScriptBlock { New-Item "$PSHome\Modules\${Using:ModuleName}" -ItemType Directory -Force } | Select -Expand FullName

        $ChildItem = Get-ChildItem -Path $ModuleBase -Recurse
        ForEach ($Item in $ChildItem) {
            $RemotePath = "$RemoteBase\$($Item.FullName.Substring($ModuleBase.Length + 1))"
            Switch ($Item.Attributes) {
            "Directory" { Invoke-Command -Session $Session -ScriptBlock { New-Item $Using:RemotePath -ItemType Directory -Force } | Out-Null }
            "Archive"   { Copy-File -Session $Session -FilePath $Item.FullName -DestinationPath $RemotePath }
            }
        }

    } Catch {
        Throw $_
    }

    Invoke-Command -Session $Session -ScriptBlock {
        Import-Module $Using:RemoteBase\$Using:ModuleName -Force
    }

    If (!$Persist) {
      Invoke-Command -Session $Session -ScriptBlock {
        Remove-Item -Path $Using:RemoteBase -Force -Recurse
      }
    }

}