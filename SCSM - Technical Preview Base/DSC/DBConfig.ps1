Configuration Main
{

Param(
[string]
$NodeName = 'localhost',

[PSCredential]
$DomainAdminCredentials
)

Import-DscResource -ModuleName PSDesiredStateConfiguration,xNetWorking,xComputerManagement,xSQlPs,xActiveDirectory,xSQLServer

Node $nodeName
  {
			
		    LocalConfigurationManager
			{
				ConfigurationMode = 'ApplyAndAutoCorrect'
				RebootNodeIfNeeded = $true
				ActionAfterReboot = 'ContinueConfiguration'
				AllowModuleOverwrite = $true

			}
			
			WindowsFeature RSAT_AD_PowerShell 
				{
					Ensure = 'Present'
					Name   = 'RSAT-AD-PowerShell'
				}
			
			xDNSServerAddress DNS_Settings
            {
				Address = $Node.DnsServerAddress
				InterfaceAlias = $Node.InterfaceAlias
				AddressFamily = $Node.AddressFamily
			}        
	  
			xComputer Join_Domain
            {
                Name = $env:COMPUTERNAME
                Credential = $DomainAdminCredentials
                DomainName = $Node.DomainName
				DependsOn = "[xDNSServerAddress]DNS_Settings"
				
            }

		    WindowsFeature NetFx35_Install
			{
				Name = "Net-FrameWork-Features"
				Ensure = "Present"
				DependsOn = '[xComputer]Join_Domain'
			}
	  
			xSQLServerSetup Install_SqlInstanceName
			{
				InstanceName = "SCCM"           
				SourcePath = $Node.SqlSourcePath
				SourceFolder = ""
				Features = 'SQLENGINE,RS,SSMS,ADV_SSMS'
				SetupCredential = $DomainAdminCredentials
				SQLSvcAccount = $DomainAdminCredentials
				SQLSysAdminAccounts = $Node.SysAdminAccounts
				DependsOn = "[WindowsFeature]NetFx35_Install"
			}

			Service StopSQLService
            {
				Name = "MSSQLSERVER"
				State = "Stopped"
				StartupType = "Disabled"
				DependsOn = "[xSQLServerSetup]Install_SqlInstanceName"
            }

			Service StopSQLAgent
            {
				Name="SQLSERVERAGENT"
				State="Stopped"
				DependsOn = "[Service]StopSQLService"
            }

			xSQLServerNetwork TCPPort
			{
				InstanceName = "SCCM"
				ProtocolName = "tcp"
				RestartService = $true
				TCPPort = "1433"
				IsEnabled = $true
				DependsOn = "[Service]StopSQLService"
			}

			WindowsFeature RDC
			{
				Name="RDC"
				Ensure="Present"
				DependsOn = "[Service]StopSQLAgent"
			}

			WindowsFeature BITS
			{
				Name="BITS"
				Ensure="Present"
				IncludeAllSubFeature = $true
				DependsOn = "[WindowsFeature]RDC"
			}

			WindowsFeature WebServer
			{
				Name="Web-Server"
				Ensure="Present"
				DependsOn = "[WindowsFeature]BITS"
			}

			WindowsFeature ISAPI
			{
				Name="Web-ISAPI-Ext"
				Ensure="Present"
				DependsOn="[WindowsFeature]WebServer"
			}

			WindowsFeature WindowsAuth
			{
				Name="Web-Windows-Auth"
				Ensure="Present"
				DependsOn="[WindowsFeature]WebServer"
			}

			WindowsFeature IISMetabase
			{
				Name="Web-Metabase"
				Ensure="Present"
				DependsOn="[WindowsFeature]WebServer"
			}

			WindowsFeature IISWMI
			{
				Name="Web-WMI"
				Ensure="Present"
				DependsOn="[WindowsFeature]WebServer"
			}

			File TempFolder
            {
            Ensure = "Present"
            Type = "Directory"
            DestinationPath = "C:\Temp"

            }
        
			Script DownloadADK
            {
            TestScript = {Test-Path C:\Temp\Installers.zip}
            SetScript = {
                $obj = New-Object -TypeName System.Net.WebClient
                $obj.DownloadFile('http://sccmprereqs.blob.core.windows.net/windows-adk/Installers.zip','C:\Temp\Installers.zip')
                        }
            GetScript = {return @{ 'Present' = $true }}
            }

			Archive UnpackADK
            {
            Ensure = "Present"
            Path = "C:\Temp\Installers.zip"
            Destination = "C:\Temp\ADKSetup"
            DependsOn = "[Script]DownloadADK"
            }

			Script InstallADK
            {
            TestScript = {
                         $obj = Get-WmiObject -Class Win32_Product | Where Name -eq "Windows Deployment Tools"
                         if ($null -eq $obj)
                            {
                                return $false
                            }
                        else
                            {
                                return $true
                            }
                         }
            SetScript = {
               $cmd =  "C:\Temp\ADKSetup\adksetup.exe /Features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool /q /norestart"
               Invoke-Expression $cmd
               $installed = $false
               do
               {

               $obj = Get-WmiObject -Class Win32_Product | Where Name -eq "Windows Deployment Tools"
               if (!($null -eq $obj))
                {
                $installed = $true
                Start-Sleep 10
                }
               }
               while ($installed -eq $false)

                        }
            GetScript = {return @{ 'Present' = $true }}
            }

			Script DownloadCM
            {
            TestScript = {Test-Path C:\Temp\CM.zip}
            SetScript = {
                $obj = New-Object -TypeName System.Net.WebClient
                $obj.DownloadFile('http://sccmprereqs.blob.core.windows.net/tp-binaries/CM.zip','C:\Temp\CM.zip')
                        }
            GetScript = {return @{ 'Present' = $true }}
            }

			Archive UnpackCM
            {
            Ensure = "Present"
            Path = "C:\Temp\CM.zip"
            Destination = "C:\Temp\CMSetup"
            DependsOn = "[Script]DownloadCM"
            }

			File CMDownloads
			{
				Ensure = "Present"
				Type = "Directory"
				DestinationPath = "C:\Temp\CMDownloads"
			}

			Script DownloadCMDownloads
            {
            TestScript = {Test-Path C:\Temp\CMDownloads.zip}
            SetScript = {
                $obj = New-Object -TypeName System.Net.WebClient
                $obj.DownloadFile('http://sccmprereqs.blob.core.windows.net/cmdownloads/CMDownloads.zip','C:\Temp\CMDownloads.zip')
                        }
            GetScript = {return @{ 'Present' = $true }}
            }

			Archive UnpackCMDownloads
            {
            Ensure = "Present"
            Path = "C:\Temp\CMDownloads.zip"
            Destination = "C:\Temp\CMDownloads"
            DependsOn = "[Script]DownloadCMDownloads"
            }

			File CMUnattend
			{
				Ensure = "Present"
				Type = "Directory"
				DestinationPath = "C:\Temp\CMUnattend"
			}

			Script DownloadCMUnattend
            {
            TestScript = {Test-Path C:\Temp\CMUnattend\CMUnattend.ini}
            SetScript = {
                $obj = New-Object -TypeName System.Net.WebClient
                $obj.DownloadFile('http://sccmprereqs.blob.core.windows.net/cm-ini/CMUnattend.ini','C:\Temp\CMUnattend\CMUnattend.ini')
                        }
            GetScript = {return @{ 'Present' = $true }}
            }

			Script ExtendSchema
            {
        TestScript = {
                    $String = Get-Content C:\ExtADSch.log | Select-String "Successfully extended the Active Directory schema"

                    if ($null -eq $String)
                        {
                            return $false
                        }
                    else
                        {
                            return $true
                        }
                    }
				SetScript = {
					$exePath = "C:\Temp\CMSetup\SMSSETUP\BIN\i386\extadsch.exe"
                    Start-Process -FilePath $exePath -NoNewWindow -Wait -RedirectStandardOutput "C:\Temp\extend.txt" | Out-Null

				}
				GetScript = {return @{ 'Present' = $true }}
                PsDscRunAsCredential = $DomainAdminCredentials
            }

			WindowsFeature UpdateServices
			{
				Ensure = "Present"
				Name = "UpdateServices"
			}

			WindowsFeature UpdateServices-WidDB
			{
				Ensure = "Present"
				Name = "UpdateServices-WidDB"
				DependsOn = "[WindowsFeature]UpdateServices"
			}

			WindowsFeature UpdateServices-Services
			{
				Ensure = "Present"
				Name = "UpdateServices-Services"
				DependsOn = "[WindowsFeature]UpdateServices-WidDB"
			}

			WindowsFeature UpdateServices-RSAT
			{
				Ensure = "Present"
				Name = "UpdateServices-RSAT"
				DependsOn = "[WindowsFeature]UpdateServices-Services"
			}

			WindowsFeature UpdateServices-API
			{
				Ensure = "Present"
				Name = "UpdateServices-API"
				DependsOn = "[WindowsFeature]UpdateServices-RSAT"
			}

			WindowsFeature UpdateServices-UI
			{
				Ensure = "Present"
				Name = "UpdateServices-UI"
				DependsOn = "[WindowsFeature]UpdateServices-API"
			}

			File UpdatesStore
			{
				Ensure = "Present"
				Type = "Directory"
				DestinationPath = "C:\Updates"
				DependsOn = "[WindowsFeature]UpdateServices-UI"
			}

			Script ConfigureWSUS
			{
				TestScript = {Test-Path C:\Temp\temp.txt}
				SetScript = {
                    $WSUSUtil = "$($Env:ProgramFiles)\Update Services\Tools\WsusUtil.exe"
                    $WSUSUtilArgs = "POSTINSTALL CONTENT_DIR=C:\Updates"
                    Start-Process -FilePath $WSUSUtil -ArgumentList $WSUSUtilArgs -NoNewWindow -Wait -RedirectStandardOutput "C:\Temp\temp.txt" | Out-Null
                            }
				GetScript = {return @{ 'Present' = $true }}
				DependsOn = "[File]UpdatesStore"
			}

			Script SysMContainer
            {
                TestScript = {Test-Path C:\myfile.txt}
                SetScript = {
                    $ObjectDomain = New-Object System.DirectoryServices.DirectoryEntry
                    $ObjectContainer = $ObjectDomain.Create("container", "CN=System Management,CN=System")
                    $ObjectContainer.SetInfo() | Out-Null
                }
                GetScript = {return @{ 'Present' = $true }}
                PsDscRunAsCredential = $DomainAdminCredentials
				DependsOn = "[Script]ConfigureWSUS"
            }

			Script InstallCM
			{
				TestScript = {Test-Path "C:\Program Files\Microsoft Configuration Manager"}
				SetScript = {
                    Set-Location C:\
					$cmd = 'C:\Temp\CMSetup\SMSSetup\Bin\x64\setup.exe' 
                    $setupArgs = '/script C:\Temp\CMUnattend\CMUnattend.ini'
					Start-Process -FilePath $cmd  -ArgumentList $setupArgs -NoNewWindow -RedirectStandardOutput "C:\Temp\install.txt" | Out-Null
                    Write-Verbose "Sleeping 60 seconds because the installation will restart WMI"
                    Start-Sleep -Seconds 60
                    Write-verbose "Hope everthing is running"
            }
				GetScript = {return @{ 'Present' = $true }}
				PsDscRunAsCredential = $DomainAdminCredentials
				DependsOn = "[Script]SysMContainer"
			}

			

			

			



			

	        
  }
}