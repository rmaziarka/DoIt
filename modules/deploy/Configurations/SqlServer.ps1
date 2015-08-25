<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

Configuration SqlServer {
    param ($NodeName, $Environment, $Tokens)

    Import-DSCResource -ModuleName xSQLServer
    Import-DSCResource -ModuleName xStorage
    Import-DSCResource -ModuleName xDatabase

	Node $NodeName {
        WindowsFeature Net35 {
            Name = 'NET-Framework-Core'
            Source = $Tokens.InstallPaths.WindowsServer2012Iso
        }

        xMountImage MountSqlIso {
            Name = 'MountSqlIso'
            ImagePath = $Tokens.SqlServer.IsoPath
            DriveLetter = $Tokens.SqlServer.IsoMountDrive
            Ensure = 'Present'
        }

        # Note: this works in a non-deterministic way (due to xMountImage / clear-cache issues)

        xSQLServerSetup DatabaseSetup {
            SourcePath              = "$($Tokens.SqlServer.IsoMountDrive)\" # needs to be uncompressed iso
            SourceFolder            = ''
            SetupCredential         = $Tokens.Credentials.SetupCredential # this is unfortunately required
            UpdateEnabled           = 'False' # it doesn't seem to work when it's true
            UpdateSource            = ''
            Features                = 'SQLENGINE,SSMS,ADV_SSMS' # TODO: this only installed SQLENGINE!
            InstanceName            = 'MSSQLSERVER'
            SQLCollation            = 'Latin1_General_CI_AS'
            #SecurityMode            = 'Windows'
            
            InstallSQLDataDir       = 'C:\SQLServerData\Data'
            SQLUserDBLogDir         = 'C:\SQLServerData\Log'
            SQLBackupDir            = 'C:\SQLServerData\Backup'
            DependsOn               = @('[WindowsFeature]Net35', '[xMountImage]MountSqlIso')
        }

        xSQLServerFirewall DatabaseFirewall {
            Ensure                  = "Present"
            SourcePath              = $Tokens.SqlServer.IsoMountDrive
            SourceFolder            = ''
            Features                = 'SQLENGINE'
            InstanceName            = 'MSSQLSERVER'
            DependsOn               = '[xSQLServerSetup]DatabaseSetup'
        }

        xMountImage DismountSqlIso {
            Name = 'DismountSqlIso'
            ImagePath = $Tokens.SqlServer.IsoPath
            DriveLetter = $Tokens.SqlServer.IsoMountDrive
            Ensure = 'Absent'
            DependsOn = '[xSQLServerFirewall]DatabaseFirewall'
        }

    }
}
