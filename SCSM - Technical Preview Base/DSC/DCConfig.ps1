Configuration DCConfig
{

Param(
[string]
$NodeName = 'localhost',

[PSCredential]
$DomainAdminCredentials
)

Import-DscResource -ModuleName PSDesiredStateConfiguration,xActiveDirectory,xNetworking

Node $nodeName
  {
   
    LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
        }

        WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"
        }

        WindowsFeature ADDS_Install 
        { 
            Ensure = 'Present' 
            Name = 'AD-Domain-Services' 
        } 

        WindowsFeature RSAT_AD_AdminCenter 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-AdminCenter'
        }

        WindowsFeature RSAT_ADDS 
        {
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
        }

        WindowsFeature RSAT_AD_PowerShell 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-PowerShell'
        }

        WindowsFeature RSAT_AD_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-AD-Tools'
        }

        WindowsFeature RSAT_Role_Tools 
        {
            Ensure = 'Present'
            Name   = 'RSAT-Role-Tools'
        }

	  xDNSServerAddress DnsServer_Address
        {
            Address = '127.0.0.1'
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily = $Node.AddressFamily
            DependsOn = '[WindowsFeature]RSAT_AD_PowerShell'
        }      		

      xADDomain CreateForest 
        { 
            DomainName = $Node.DomainName            
            DomainAdministratorCredential = $DomainAdminCredentials
            SafemodeAdministratorPassword = $DomainAdminCredentials
            DomainNetbiosName = $Node.DomainNetBiosName
            DependsOn = '[WindowsFeature]ADDS_Install', '[WindowsFeature]DNS'
        }  
  }
}