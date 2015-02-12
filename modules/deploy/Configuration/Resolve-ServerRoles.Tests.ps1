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

Import-Module -Name "$PSScriptRoot\..\..\..\PSCI.psm1"

Describe -Tag "PSCI.unit" "ServerRole" {
    InModuleScope PSCI.deploy {
        Context "when used with single role and environment" {
            It "Resolve-ServerRoles: should properly resolve local environment" {
                Initialize-Deployment

                $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

			    Environment Local {
				    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2') -RemotingCredential $remotingDefaultCredential -RunOn 'config1' -CopyTo "file"
			    }

                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('config1', 'config2')
                $resolvedRoles['WebServer'].Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles['WebServer'].RemotingCredential | Should Be $remotingDefaultCredential
                $resolvedRoles['WebServer'].RunOn | Should Be 'config1'
                $resolvedRoles['WebServer'].CopyTo | Should Be 'file'
            }
        }

        Context "when used with single role and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

		    Environment Default {
			    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1') -RemotingCredential $cred
		    }

		    Environment Local {
			    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2')
		    }

            It "Resolve-ServerRoles: should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('config1')
                $resolvedRoles['WebServer'].Nodes | Should Be @('machine1')
			    $resolvedRoles['WebServer'].RemotingCredential | Should Be $cred
            }

            It "Resolve-ServerRoles: should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local

                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('config1', 'config2')
                $resolvedRoles['WebServer'].Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles['WebServer'].Contains("RemotingCredential") | Should Be $true
            }
        }

        Context "when used with multiple roles" {
            Initialize-Deployment

            Environment Default {
			    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1')
		    }

		    Environment Local {
			    ServerRole DbServer -Configurations @('config2') -Nodes @('machine2')
		    }

            It "Resolve-ServerRoles: should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default

                $resolvedRoles.Count | Should Be 1
            
                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('config1')
                $resolvedRoles['WebServer'].Nodes | Should Be @('machine1')
            }

            It "Resolve-ServerRoles: should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local

                $resolvedRoles.Count | Should Be 2

                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('config1')
                $resolvedRoles['WebServer'].Nodes | Should Be @('machine1')

                $resolvedRoles['DbServer'] | Should Not Be $null
                $resolvedRoles['DbServer'].Configurations | Should Be @('config2')
                $resolvedRoles['DbServer'].Nodes | Should Be @('machine2')
            }
        }
        
        Context "when used with multiple rules and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

		    Environment Default {
                ServerRole WebServer -Configurations @('WebServerProvision', 'WebServerConfig', 'WebServerDeploy') -RemotingCredential $cred
                ServerRole DatabaseServer -Configurations @('CopySQLConfigurationFileProvision', 'SQLServerProvision', 'DatabaseServerDeploy', 'SSISServerDeploy') -RemotingCredential $cred
                ServerRole SSRSServer -Configurations @('SSRSServerDeploy')
		    }

		    Environment Live {
                ServerRole WebServer -Nodes @('cwpsgweb01', 'cwpsgweb02', 'cwpsgweb03', 'cwpsgweb04', 'cwpsgweb05') -Configurations @('WebServerConfig', 'WebServerDeploy') -RunOnCurrentNode -CopyTo 'C:\Deployment' -RemotingMode PSRemoting -RemotingCredential $null
                ServerRole DatabaseServer -Configurations @('DatabaseServerDeploy', 'SSISServerDeploy') -Nodes ('cwpsgsql01') -RunOnCurrentNode -CopyTo 'C:\Deployment' -RemotingMode PSRemoting -Authentication Credssp -RemotingCredential $cred
		    }

		    Environment LivePerf -BasedOn Live {
                ServerRole DatabaseServer -Configurations @('DatabaseServerDeploy')
                ServerRole SSRSServer -Nodes $null
		    }

            It "Resolve-ServerRoles: should properly resolve LivePerf environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment LivePerf

                $resolvedRoles.Count | Should Be 3

                $resolvedRoles['WebServer'] | Should Not Be $null
                $resolvedRoles['WebServer'].Configurations | Should Be @('WebServerConfig', 'WebServerDeploy')
                $resolvedRoles['WebServer'].Nodes | Should Be @('cwpsgweb01', 'cwpsgweb02', 'cwpsgweb03', 'cwpsgweb04', 'cwpsgweb05')
			    $resolvedRoles['WebServer'].RemotingCredential | Should Be $null
			    $resolvedRoles['WebServer'].CopyTo | Should Be 'C:\Deployment'

                $resolvedRoles['DatabaseServer'] | Should Not Be $null
                $resolvedRoles['DatabaseServer'].Configurations | Should Be @('DatabaseServerDeploy')
                $resolvedRoles['DatabaseServer'].Nodes | Should Be @('cwpsgsql01')
			    $resolvedRoles['DatabaseServer'].RemotingCredential | Should Be $cred

                $resolvedRoles['SSRSServer'] | Should Not Be $null
                $resolvedRoles['SSRSServer'].Configurations | Should Be @('SSRSServerDeploy')
                $resolvedRoles['SSRSServer'].Nodes | Should Be $null
            }
        }
    }
}
