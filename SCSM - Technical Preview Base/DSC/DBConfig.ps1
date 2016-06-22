Configuration Main
{

Param(
[string]
$NodeName = 'localhost',

[PSCredential]
$DomainAdminCredentials
)

Import-DscResource -ModuleName PSDesiredStateConfiguration,xNetWorking,xComputerManagement,xSQlPs

Node $nodeName
  {
			
		    LocalConfigurationManager
			{
				ConfigurationMode = 'ApplyAndAutoCorrect'
				RebootNodeIfNeeded = $true
				ActionAfterReboot = 'ContinueConfiguration'
				AllowModuleOverwrite = $true

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
	  
			xSqlServerInstall Install_SqlInstanceName
			{
				InstanceName = "SCCM"           
				SourcePath = $Node.SqlSourcePath
				Features = 'SQLEngine,SSRS,SSMS,ADV_SSMS'
				SqlAdministratorCredential = $DomainAdminCredentials
				DependsOn = "[WindowsFeature]NetFx35_Install"
				UpdateEnabled = $true
				SysAdminAccounts = $Node.SysAdminAccounts
			}

			Service StopSQLService
            {
				Name = "MSSQLSERVER"
				State = "Stopped"
				StartupType = "Disabled"
				DependsOn = "[xSQLServerInstall]Install_SqlInstanceName"
            }

			Service StopSQLAgent
            {
				Name="SQLSERVERAGENT"
				State="Stopped"
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

			

	        
  }
}