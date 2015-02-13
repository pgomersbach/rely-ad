#ps1

# Usage:
# <powershell>
# Set-ExecutionPolicy Unrestricted -Force
# icm $executioncontext.InvokeCommand.NewScriptBlock((New-Object Net.WebClient).DownloadString('https://rely-ad.googlecode.com/git/rely_ad/files/cloud-puppet.ps1')) -ArgumentList ("rely_ad")
#</powershell>


  param(
#    [string]$role = (throw "-role is required."),
    [string]$role = "rely_ad",
    [string]$rabbithost = "localhost"
  )

  $puppet_source = "https://code.google.com/p/rely-ad/"
  $MsiUrl = "https://downloads.puppetlabs.com/windows/puppet-3.7.4-x64.msi"

  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if (! ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host -ForegroundColor Red "You must run this script as an administrator."
    Exit 1
  }

  # Install puppet - msiexec will download from the url
  $install_args = @("/qn", "/norestart","/i", $MsiUrl)
  Write-Host "Installing Puppet. Running msiexec.exe $install_args"
  $process = Start-Process -FilePath msiexec.exe -ArgumentList $install_args -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    Write-Host "Puppet installer failed."
    Exit 1
  }

  Write-Host "Puppet successfully installed."

  $GitUrl = "http://msysgit.googlecode.com/files/Git-1.8.0-preview20121022.exe"
  $TempDir = [System.IO.Path]::GetTempPath()
  $TempGit = $TempDir + "/Git-1.8.0-preview20121022.exe"
  Write-Host "Downloading Git to $TempGit"
  $client = new-object System.Net.WebClient
  $client.DownloadFile( $GitUrl, $TempGit )
  $install_args = @("/SP","/VERYSILENT","/SUPPRESSMSGBOXES","/CLOSEAPPLICATIONS","/NOICONS")
  $process = Start-Process -FilePath $TempGit -ArgumentList $install_args -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    Write-Host "Git installer failed."
    Exit 1
  }
 
  if (Test-Path "${Env:ProgramFiles(x86)}\Git\bin\git.exe") {
    $clone_args = @("clone",$puppet_source,"C:\ProgramData\PuppetLabs\puppet\etc\modules" )
    Write-Host "Cloning $clone_args"
    $process = Start-Process -FilePath "${Env:ProgramFiles(x86)}\Git\bin\git.exe" -ArgumentList $clone_args -Wait -PassThru
    if ($process.ExitCode -ne 0) {
      Write-Host "Git clone failed."
      Exit 1
    }
  }

  if ($rabbithost) {
    Set-Item -path env:FACTER_rabbithost -value $rabbithost
    Write-Host "env var  FACTER_rabbithost set to $rabbithost"
  }
  $puppet_args = @("apply","--modulepath=C:\ProgramData\PuppetLabs\puppet\etc\modules","-e","`"include $role`"" )
  Write-Host "Running puppet $puppet_args"
  $process = Start-Process -FilePath "${Env:ProgramFiles(x86)}\Puppet Labs\Puppet\bin\puppet.bat" -ArgumentList $puppet_args -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    Write-Host "Puppet apply failed."
    Exit 1
  }
