

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
        [Parameter(Mandatory = $true, Position=0)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        [Parameter(Mandatory = $true, Position=1)]
        [string]$Name
    )

    $PSModuleInfo = Get-Module -Name $Name
    If (!$PSModuleInfo) { Throw "Copy-Module : The specified module '$Name' was not copied because no valid module file was found in any module directory."; Return }

    function Invoke-Export([string] $Name, $Dictionary) { 
        If ($Dictionary.Keys.Count -gt 0) {
            Return " -$Name $($Dictionary.Keys -Join ",")"
        }
    }

    $ExportedFunctions = Invoke-Export "Function" $PSModuleInfo.ExportedFunctions
    $ExportedAliases   = Invoke-Export "Alias" $PSModuleInfo.ExportedAliases
    $ExportedCmdlets   = Invoke-Export "Cmdlet" $PSModuleInfo.ExportedCmdlets
    $ExportedVariables = Invoke-Export "Variable" $PSModuleInfo.ExportedVariables
    
    $ExportModuleMember = "Export-ModuleMember $ExportedFunctions $ExportedAliases $ExportedCmdlets $ExportedVariables"

    $Command  = "If (Get-Module -Name $Name) { Remove-Module -Name $Name };`r`n"
    $Command += "New-Module -Name $Name { $($PSModuleInfo.Definition); $ExportModuleMember; } | Import-Module;"
    
    Invoke-Command -Session $Session -ScriptBlock { Invoke-Expression $Using:Command }

}