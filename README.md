
#### Copy-xItem

````
Import-Module Copy-xItem
$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
Copy-xItem -Session $Session -Path 'C:\Workspace' -Destination 'C:\Workspace' -Recurse -Force

Invoke-Command -Session $Session -ScriptBlock { Get-ChildItem 'C:\Workspace' }
````

#### Copy-xFunction

````
Import-Module Copy-xItem
Import-Module .\Get-PendingReboot.ps1

$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
Copy-xFunction -Session $Session -Name 'Get-PendingReboot'

Invoke-Command -Session $Session -ScriptBlock { Get-PendingReboot }
````

#### Copy-xModule

````
Import-Module Copy-xItem
Import-Module .\Get-PendingReboot.ps1

$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
Copy-xModule -Session $Session -Name 'Get-PendingReboot'

Invoke-Command -Session $Session -ScriptBlock { Get-PendingReboot }
````
