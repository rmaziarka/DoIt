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

Import-Module -Name "$PSScriptRoot\..\..\..\..\PSCI.psm1"

Describe -Tag "PSCI.unit" "ServerRole" {
    InModuleScope PSCI.deploy {
        Context "when used with single role and environment" {
           It "ServerRole: should properly initialize internal structures" {
                Initialize-Deployment

                $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

			    Environment Local {
				    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2') -RemotingCredential $remotingDefaultCredential -RunOn 'config1' -CopyTo "file"
			    }

                $Environments.Count | Should Be 1
                $Environments.Local | Should Not Be $null
                $Environments.Local.BasedOn | Should Be 'Default'

                $Environments.Local.ServerRoles | Should Not Be $null
                $Environments.Local.ServerRoles.Count | Should Be 1
                $Environments.Local.ServerRoles.WebServer | Should Not Be $null
                $Environments.Local.ServerRoles.WebServer.Configurations | Should Be @('config1', 'config2')
                $Environments.Local.ServerRoles.WebServer.Nodes | Should Be @('machine1', 'machine2')
                $Environments.Local.ServerRoles.WebServer.RemotingCredential | Should Be $remotingDefaultCredential
                $Environments.Local.ServerRoles.WebServer.RunOn | Should Be 'config1'
                $Environments.Local.ServerRoles.WebServer.CopyTo | Should Be 'file'
            }
        }

        Context "when used with single role and environment inheritance" {
           It "ServerRole: should properly initialize internal structures" {
                Initialize-Deployment
                $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

			    Environment Default {
				    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1') -RemotingCredential $cred
			    }

			    Environment Local {
				    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2')
			    }

                $Environments.Count | Should Be 2
                $Environments.Default | Should Not Be $null
                $Environments.Default.BasedOn | Should Be ''
                $Environments.Default.ServerRoles.Count | Should Be 1
                $Environments.Default.ServerRoles.WebServer.Configurations | Should Be 'config1'
                $Environments.Default.ServerRoles.WebServer.Nodes | Should Be 'machine1'
                $Environments.Default.ServerRoles.WebServer.RemotingCredential | Should Be $cred

                $Environments.Local | Should Not Be $null
                $Environments.Local.BasedOn | Should Be 'Default'
                $Environments.Local.ServerRoles.Count | Should Be 1
                $Environments.Local.ServerRoles.WebServer.Configurations | Should Be @('config1', 'config2')
                $Environments.Local.ServerRoles.WebServer.Nodes | Should Be @('machine1', 'machine2')
                $Environments.Local.ServerRoles.WebServer.ContainsKey('RemotingCredential') | Should Be $false
            }

            It "ServerRole: should override with empty parameter" {
                Initialize-Deployment
                $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

			    Environment Default {
				    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1') -RemotingCredential $cred
			    }

			    Environment Local {
				    ServerRole WebServer -Configurations $null -Nodes $null -RemotingCredential $null -RunOn $null -CopyTo $null -Authentication $null
			    }

                $Environments.Count | Should Be 2
                $Environments.Default | Should Not Be $null
                $Environments.Default.BasedOn | Should Be ''
                $Environments.Default.ServerRoles.Count | Should Be 1
                $Environments.Default.ServerRoles.WebServer.Configurations | Should Be 'config1'
                $Environments.Default.ServerRoles.WebServer.Nodes | Should Be 'machine1'
                $Environments.Default.ServerRoles.WebServer.RemotingCredential | Should Be $cred

                $Environments.Local | Should Not Be $null
                $Environments.Local.BasedOn | Should Be 'Default'
                $Environments.Local.ServerRoles.Count | Should Be 1
                $Environments.Local.ServerRoles.WebServer.Configurations | Should Be $null
                $Environments.Local.ServerRoles.WebServer.ContainsKey('Nodes') | Should Be $true
                $Environments.Local.ServerRoles.WebServer.Nodes | Should Be $null
                $Environments.Local.ServerRoles.WebServer.ContainsKey('RemotingCredential') | Should Be $true
                $Environments.Local.ServerRoles.WebServer.RemotingCredential | Should Be $null
                $Environments.Local.ServerRoles.WebServer.ContainsKey('RunOn') | Should Be $true
                $Environments.Local.ServerRoles.WebServer.RunOn | Should Be ''
                $Environments.Local.ServerRoles.WebServer.ContainsKey('CopyTo') | Should Be $true
                $Environments.Local.ServerRoles.WebServer.CopyTo | Should Be $null
                $Environments.Local.ServerRoles.WebServer.ContainsKey('Authentication') | Should Be $true
                $Environments.Local.ServerRoles.WebServer.Authentication | Should Be ''
            }
        }

        Context "when used with multiple roles" {
           It "ServerRole: should properly initialize internal structures" {
                Initialize-Deployment

                Environment Default {
				    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1')
			    }

			    Environment Local {
				    ServerRole DbServer -Configurations @('config2') -Nodes @('machine2')
			    }

                $Environments.Count | Should Be 2
                $Environments.Default | Should Not Be $null
                $Environments.Default.BasedOn | Should Be ''
                $Environments.Default.ServerRoles.Count | Should Be 1
                $Environments.Default.ServerRoles.WebServer.Configurations | Should Be 'config1'
                $Environments.Default.ServerRoles.WebServer.Nodes | Should Be 'machine1'

                $Environments.Local | Should Not Be $null
                $Environments.Local.BasedOn | Should Be 'Default'
                $Environments.Local.ServerRoles.Count | Should Be 1
                $Environments.Local.ServerRoles.DbServer.Configurations | Should Be 'config2'
                $Environments.Local.ServerRoles.DbServer.Nodes | Should Be 'machine2'
            }
        }

          Context "when multiple roles defined in one environment" {
           It "ServerRole: roles order should be retained" {
                Initialize-Deployment

                Environment Default {
				    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1')
                    ServerRole DbServer -Configurations @('config2') -Nodes @('machine2')
			    }

                Environment Local {
                    ServerRole DbServer -Configurations @('config2') -Nodes @('machine2')
				    ServerRole WebServer -Configurations @('config1') -Nodes @('machine1')
			    }


                $Environments.Count | Should Be 2
                $Environments.Default | Should Not Be $null
                $Environments.Default.BasedOn | Should Be ''
                $Environments.Default.ServerRoles.Count | Should Be 2
                $Environments.Default.ServerRoles[0].Name | Should Be 'WebServer'
                $Environments.Default.ServerRoles[1].Name | Should Be 'DbServer'

                $Environments.Default.ServerRoles.WebServer.Configurations | Should Be 'config1'
                $Environments.Default.ServerRoles.WebServer.Nodes | Should Be 'machine1'
                $Environments.Default.ServerRoles.DbServer.Configurations | Should Be 'config2'
                $Environments.Default.ServerRoles.DbServer.Nodes | Should Be 'machine2'

                $Environments.Local.ServerRoles.WebServer.Configurations | Should Be 'config1'
                $Environments.Local.ServerRoles.WebServer.Nodes | Should Be 'machine1'
                $Environments.Local.ServerRoles.DbServer.Configurations | Should Be 'config2'
                $Environments.Local.ServerRoles.DbServer.Nodes | Should Be 'machine2'
            }
        }
    }
}
