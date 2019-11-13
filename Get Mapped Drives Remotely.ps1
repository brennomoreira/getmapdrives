function Get-MappedDrives {
    [CmdletBinding()]
    param(
        [ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1})]
        [string] $ComputerName = $env:computername,
        [string] $Username = $env:username
        )

    $UNCComputerName = "\\$ComputerName"
    psexec $UNCComputerName powershell.exe -windowstyle Hidden -command 'Enable-PSRemoting -Force'

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param($ComputerName, $Username)
        new-psdrive -root HKEY_USERS -name HKU -PSProvider Registry | Out-Null

        $ProfileSIDPath = (get-childitem 'hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList') | where {"C:\users\$username" -match [regex]::Escape((Get-ItemPropertyValue -Path $_.Name.replace('HKEY_LOCAL_MACHINE','HKLM:') -Name ProfileImagePath))}
        $ProfileSID = $ProfileSIDPath.PSChildName

        foreach ($key in (Get-ChildItem HKU:\$ProfileSID\Network)) {
            $key.PSChildName
            Get-ItemPropertyValue -name RemotePath -Path $key.tostring().replace('HKEY_USERS','HKU:')
            }
        } -ArgumentList $ComputerName, $Username
    } 