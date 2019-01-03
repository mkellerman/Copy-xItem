function Copy-xItem {

<#

.SYNOPSIS

    Copy File to a Remote Session.

.DESCRIPTION

    Copy File to a Remote Session. 

    By Marc R Kellerman (@mkellerman)
    http://mkellerman.github.io
    
.PARAMETER Session

    Specifies an array of sessions in which this cmdlet runs the command. Enter a variable that contains PSSession objects or a command that creates or gets the PSSession objects, such as a New-PSSession or Get-PSSession command.
        
    When you create a PSSession, Windows PowerShell establishes a persistent connection to the remote computer. Use a PSSession to run a series of related commands that share data. To run a single command or a series of unrelated commands, use the 
    ComputerName parameter. For more information, see about_PSSessions.
        
.PARAMETER Path

    Specifies the names of the files to copy. 
        
.PARAMETER Destination

    Specifies the path to the new location. To rename a copied item, include the new name in the value.

#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        [Parameter(Mandatory = $true)]
        [string[]]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    ForEach ($FilePath in $Path) {

        Try {

            $Item = Get-Item -Path $FilePath
            $SourcePath = $Item.Parent.FullName

            [object[]]$ChildItems = Get-ChildItem -Path $FilePath -Recurse:$Recurse.IsPresent -Force:$Force
            ForEach ($ChildItem in $ChildItems) {
        
                Switch ($ChildItem.GetType().Name) {
                    'DirectoryInfo' { $ItemType = 'Directory'; $base64string = $Null }
                    'FileInfo'      { $ItemType = 'File';      $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ChildItem.FullName)) }
                    Default         { Throw 'Copy-xItem : The specified item cannot be copied.'}
                }

                $DestinationFile = "$($ChildItem.Fullname)".Replace($SourcePath, $Destination)
                Write-Verbose "Performing the operation `"Copy ${ItemType}`" on target `"Item: $($ChildItem.FullName) Destination: ${DestinationFile}`"."

                Invoke-Command -Session $Session -ScriptBlock {
                    $____f1b4c794a5814fcabaf651b565546e6f = New-Item -Path $Using:DestinationFile -ItemType ${Using:ItemType} -Force:$Using:Force.IsPresent
                    If (($____f1b4c794a5814fcabaf651b565546e6f) -and (${Using:ItemType} -eq 'File')) {
                        [IO.File]::WriteAllBytes($____f1b4c794a5814fcabaf651b565546e6f.FullName, [Convert]::FromBase64String($Using:base64string))
                    }
                    Remove-Variable -Name '____f1b4c794a5814fcabaf651b565546e6f' -Force -Confirm:$False -ErrorAction SilentlyContinue
                }
        
            }
        
        } Catch { Throw $_ }

    }
}

function Copy-xFunction {

<#

.SYNOPSIS

    Copy Function to a Remote Session.

.DESCRIPTION

    Copy Function to a Remote Session. 

    By Marc R Kellerman (@mkellerman)
    http://mkellerman.github.io
    
.PARAMETER Session

    Specifies an array of sessions in which this cmdlet runs the command. Enter a variable that contains PSSession objects or a command that creates or gets the PSSession objects, such as a New-PSSession or Get-PSSession command.
        
    When you create a PSSession, Windows PowerShell establishes a persistent connection to the remote computer. Use a PSSession to run a series of related commands that share data. To run a single command or a series of unrelated commands, use the 
    ComputerName parameter. For more information, see about_PSSessions.
        
.PARAMETER Name

    Specifies the names of the functions to copy. 

#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $IsVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -eq $True

    ForEach ($FunctionName in $Name) {

        Try {

            $FunctionScriptBlock = (Get-ChildItem function: | Where-Object Name -eq $FunctionName).ScriptBlock.Ast.Extent.Text
            If (!$FunctionScriptBlock) { Throw "Copy-xFunction : The specified function '$FunctionName' was not found." }

            Invoke-Command -Session $Session -ScriptBlock {
                Write-Verbose "Importing function '${Using:FunctionName}'." -Verbose:${Using:IsVerbose}
                Invoke-Expression -Command ${Using:FunctionScriptBlock}
            }

        } Catch { Throw $_ }

    }

}

function Copy-xModule {

<#

.SYNOPSIS

    Copy Module to a Remote Session.

.DESCRIPTION

    Copy Module to a Remote Session. 

    By Marc R Kellerman (@mkellerman)
    http://mkellerman.github.io

    Inspired by: 
    https://stackoverflow.com/questions/14441800/how-to-import-custom-powershell-module-into-the-remote-session
    Answer by Rob
    
.PARAMETER Session

    Specifies an array of sessions in which this cmdlet runs the command. Enter a variable that contains PSSession objects or a command that creates or gets the PSSession objects, such as a New-PSSession or Get-PSSession command.
        
    When you create a PSSession, Windows PowerShell establishes a persistent connection to the remote computer. Use a PSSession to run a series of related commands that share data. To run a single command or a series of unrelated commands, use the 
    ComputerName parameter. For more information, see about_PSSessions.
        
.PARAMETER Name

    Specifies the names of the modules to copy. Enter the name of the module or the name of a file in the module, such as a .psd1, .psm1, .dll, or ps1 file. File paths are optional. Wildcard characters are not permitted. 
        
    If you omit a path, Copy-xModule looks for the module in the paths saved in the PSModulePath environment variable ($env:PSModulePath).
        
    Specify only the module name whenever possible. When you specify a file name, only the members that are implemented in that file are copied. If the module contains other files, they are not pushed, and you might be missing important members of 
    the module.
        
#>

    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        [Parameter(Mandatory = $true)]
        [string[]]$Name    
    )

    $IsVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -eq $True

    ForEach ($ModuleName in $Name) {

    Try {

        $PSModuleInfo = Get-Module -Name $ModuleName
        If (!$PSModuleInfo) { Throw "Copy-xModule : The specified module '$ModuleName' was not found."; Return }

        # Provided script generates a module 'on the fly' in memory.
        # If you need to physically copy a script into a remote session, use the Copy-xItem function
        # to copy the module folder into the remove machine.

        function Get-ModuleMember([PSModuleInfo]$PSModuleInfo) { 
            [string]$ModuleMember = ""
            If ($PSModuleInfo.ExportedFunctions.Keys.Count -gt 0) { $ModuleMember += " -Function '$($PSModuleInfo.ExportedFunctions.Keys -join "', '")'" }
            If ($PSModuleInfo.ExportedAliases.Keys.Count -gt 0)   { $ModuleMember += " -Alias '$($PSModuleInfo.ExportedAliases.Keys -join "', '")'" }
            If ($PSModuleInfo.ExportedCmdlets.Keys.Count -gt 0)   { $ModuleMember += " -Cmdlet '$($PSModuleInfo.ExportedCmdlets.Keys -join "', '")'" }
            If ($PSModuleInfo.ExportedVariables.Keys.Count -gt 0) { $ModuleMember += " -Variable '$($PSModuleInfo.ExportedVariables.Keys -join "', '")'" }
            If ($ModuleMember) { Return "Export-ModuleMember${ModuleMember}"}
        }

        If ($PSModuleInfo.Definition) {
            $ModuleMember = Get-ModuleMember -PSModuleInfo $PSModuleInfo
            $ModuleDefinition = $PSModuleInfo.Definition
        } Else {
            $ModuleMember = $Null
            $ModuleDefinition = Get-Content $PSModuleInfo.Path -Raw
        }

        Invoke-Command -Session $Session -ScriptBlock {
            $____7e59ff7b21a94eca88d1073b0b150a4f = [ScriptBlock]::Create("${Using:ModuleDefinition}; ${Using:ModuleMember};")
            New-Module -Name $Using:ModuleName -ScriptBlock $____7e59ff7b21a94eca88d1073b0b150a4f | Import-Module -Force -Verbose:${Using:IsVerbose}
            Remove-Variable -Name '____7e59ff7b21a94eca88d1073b0b150a4f' -Force -Confirm:$False -ErrorAction SilentlyContinue
        }

    } Catch { Throw $_ }

    }

}
