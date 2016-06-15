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
				InstanceName = "SM01"           
				SourcePath = $Node.SqlSourcePath
				Features = 'SQLEngine,FullText,SSMS,ADV_SSMS'
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
  }
}