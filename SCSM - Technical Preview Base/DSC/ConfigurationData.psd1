@{
	AllNodes = @(
       @{
            NodeName="*"
            RetryCount = 30
            RetryIntervalSec = 30			
         },

		@{
			NodeName = 'localhost'
			PSDscAllowDomainUser = $true
			PSDscAllowPlainTextPassword = $true
			DomainName = 'scsmtp.lab'
            DomainNetBIOSName = 'SCSMTP'
			DNSServerAddress = '10.0.0.4'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
		}
	)
}