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

Import-Module -Name "$PSScriptRoot\..\..\..\..\PSCI.psd1" -Force

Describe -Tag "PSCI.unit" "ServerRole" {
    InModuleScope PSCI.deploy {

        Mock Write-Log { 
            Write-Host "$Message"
            if ($Critical) {
                throw ("Exception: " + $Message)
            }
        }

        function TestFunc { }
        function TestFunc2 { }
        Configuration TestDSC { }
        Configuration TestDSC2 { }
        Configuration TestDSC3 { }

        $remotingDefaultCredential = (ConvertTo-PsCredential -User 'UserName' -Password 'Password')

        Context "when using single role and environment" {
            Initialize-Deployment

            Environment Local {
                ServerConnection Web1 -Nodes @('machine1','machine2') -RemotingCredential $remotingDefaultCredential -PackageDirectory 'c:\dir'
                ServerRole Web -Steps @('TestFunc', 'TestDSC') -RunOn 'machine1' -ServerConnections Web1
            }
            $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

            It "should properly resolve local environment" {
                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.RunOn | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $remotingDefaultCredential
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'c:\dir'
            }
        }

        Context "when using scriptblocks instead of actual values" {

            Initialize-Deployment

            Environment Local {
                ServerConnection Web1 -Nodes { @('machine1','machine2') } -RemotingCredential { $remotingDefaultCredential }
                ServerRole Web -Steps { 'TestFunc' } -ServerConnections { 'Web1' }
            }

            $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

            It "should resolve scripted tokens for Nodes but not for RemotingCredential" {
                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be 'TestFunc'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential -is [scriptblock] | Should Be $true
            }
        }

        Context "when using in-place ServerConnection" {
            Initialize-Deployment

            Environment Local {   
                ServerRole Web -Steps { 'TestFunc' } -ServerConnections (ServerConnection Web1 -Nodes { @('machine1','machine2') } -RemotingCredential { $remotingDefaultCredential })
            }

            $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}


            It "should resolve in-place ServerConnection" {
                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be 'TestFunc'
                $resolvedRoles.Web.ServerConnections.Count| Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'Web1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential -is [scriptblock] | Should Be $true
            }
        }

        Context "when referencing a non-existing Configuration" {
            Initialize-Deployment

            Environment Local {
                ServerRole Web -Steps @('NotExisting')
            }

            $fail = $false
            try  {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}
            } catch { 
                $fail = $true
            }

            It "should fail" {
                $fail | Should Be $true
            }
        }

        Context "when using a single role and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

            Environment Default {
                ServerRole Web -Steps @('TestFunc') -ServerConnections (ServerConnection machine1 -Nodes machine1 -RemotingCredential $cred)
            }

            Environment Local {
                ServerRole Web -Steps @('TestFunc', 'TestDSC') -ServerConnections (ServerConnection -Name 'm1' -Nodes @('machine1','machine2'))
            }

            It "should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $cred
            }

            It "should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'm1'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('machine1', 'machine2')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
            }
        }

        Context "when used with multiple roles" {
            Initialize-Deployment

            Environment Default {
                ServerRole Web -Steps @('TestFunc') -ServerConnections (ServerConnection machine1 -Nodes machine1)
            }

            Environment Local {
                ServerRole Database -Steps @('TestDSC') -ServerConnections (ServerConnection machine2 -Nodes machine1)
            }

            It "should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 1
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'
            }

            It "should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'machine1'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'machine2'
            }
        }
        
        Context "when used with multiple rules and environment inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

            Environment Default {
                ServerConnection WebServers -Nodes @('localhost') -RemotingCredential $cred 
                ServerConnection DatabaseServers -Nodes @('localhost') -RemotingCredential $cred
                ServerConnection SSRSServers -Nodes $null

                ServerRole Web -Steps TestFunc -ServerConnections WebServers
                ServerRole Database -Steps 'TestDSC' -ServerConnections DatabaseServers
                ServerRole SSRS -Steps @('TestFunc') -ServerConnections SSRSServers
                ServerRole NoConf -ServerConnection WebServers
            }

            Environment Live {
                ServerConnection WebServers -Nodes @('web01', 'web02') -PackageDirectory 'C:\Deployment' -RemotingMode PSRemoting -RemotingCredential $null
                ServerConnection DatabaseServers -Nodes @('db01') -RemotingMode PSRemoting -Authentication Credssp -RemotingCredential $cred
                ServerConnection SSRSServers -Nodes @('ssrs01') 

                ServerRole Web -Steps TestFunc2 -RunRemotely
                ServerRole Database -Steps TestDSC2 -RunRemotely 
            }

            Environment LivePerf -BasedOn Live {
                ServerConnection WebServers -PackageDirectory 'C:\Deployment2'
                ServerConnection SSRSServers -Nodes $null

                ServerRole Database -Steps TestDSC3
                
            }

            It "should properly resolve Live environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Live -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 3

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be 'TestFunc2'
                $resolvedRoles.Web.RunRemotely | Should Be $true
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('web01', 'web02')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'C:\Deployment'
                
                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be 'TestDSC2'
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'db01'
                $resolvedRoles.Database.ServerConnections.RemotingCredential | Should Be $cred

                $resolvedRoles.SSRS | Should Not Be $null
                $resolvedRoles.SSRS.Steps.Name | Should Be 'TestFunc'
                $resolvedRoles.SSRS.ServerConnections.Count | Should Be 1
                $resolvedRoles.SSRS.ServerConnections.Nodes | Should Be 'ssrs01'
                $resolvedRoles.SSRS.ServerConnections.RemotingCredential | Should Be $null
            }

            It "should properly resolve LivePerf environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment LivePerf -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2

                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be 'TestFunc2'
                $resolvedRoles.Web.RunRemotely | Should Be $true
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be @('web01', 'web02')
                $resolvedRoles.Web.ServerConnections.RemotingCredential | Should Be $null
                $resolvedRoles.Web.ServerConnections.PackageDirectory | Should Be 'C:\Deployment2'
                
                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be 'TestDSC3'
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'db01'
                $resolvedRoles.Database.ServerConnections.RemotingCredential | Should Be $cred
            }
        }

        Context "when used with BasedOn" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes machine1 -RemotingMode WebDeployHandler
                ServerConnection DbServer -Nodes machine2 -BasedOn WebServer
                ServerConnection DbServer2 -Nodes $null -BasedOn WebServer
                ServerRole Web -Steps @('TestFunc') -ServerConnections WebServer
                ServerRole Database -Steps @('TestDSC') -ServerConnections DbServer
                ServerRole Database2 -Steps @('TestDSC') -ServerConnections DbServer2 # this should be ignored because DbServer2 will have no Nodes
            }

            Environment Local {
                ServerConnection DbServer -Nodes machine3 -BasedOn $null
                ServerRole Database2 -Steps @('TestDSC') -ServerConnections (ServerConnection DbServer4 -BasedOn DbServer)
                ServerRole Database3 -Steps @('TestDSC') -ServerConnections (ServerConnection DbServer5 -BasedOn DbServer2 -Nodes machine4)
            }

            It "should properly resolve Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 2
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'DbServer'
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'machine2'
                $resolvedRoles.Database.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'
            }

            It "should properly resolve Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}

                $resolvedRoles.Count | Should Be 4
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'

                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be @('TestDSC')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'DbServer'
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'machine3'
                $resolvedRoles.Database.ServerConnections.RemotingMode | Should Be 'PSRemoting'

                $resolvedRoles.Database2 | Should Not Be $null
                $resolvedRoles.Database2.Steps.Name | Should Be @('TestDSC')
                $resolvedRoles.Database2.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database2.ServerConnections.Name | Should Be 'DbServer4'
                $resolvedRoles.Database2.ServerConnections.Nodes | Should Be 'machine3'
                $resolvedRoles.Database2.ServerConnections.RemotingMode | Should Be 'PSRemoting'

                $resolvedRoles.Database3 | Should Not Be $null
                $resolvedRoles.Database3.Steps.Name | Should Be @('TestDSC')
                $resolvedRoles.Database3.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database3.ServerConnections.Name | Should Be 'DbServer5'
                $resolvedRoles.Database3.ServerConnections.Nodes | Should Be 'machine4'
                $resolvedRoles.Database3.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'
            }
        }

        Context "when used with invalid BasedOn" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes machine1 -RemotingMode WebDeployHandler
                ServerConnection DbServer -Nodes machine1 -BasedOn Invalid
                ServerRole Web -Steps @('TestFunc') -ServerConnections DbServer
            }

            It "should throw exception" {
                $fail = $false
                try { 
                    $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}
                } catch {
                    $fail = $true
                }

                $fail | Should Be $true
            }
        }

        Context "when used with tokens" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes { $Tokens.nodes.node } -RemotingMode WebDeployHandler
                ServerRole Web -Steps @('TestFunc') -ServerConnections WebServer
            }

            $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{'nodes' = @{'node' = 'machine1'}}

            It "should properly substitute tokens" {
                $resolvedRoles.Count | Should Be 1
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'machine1'
                $resolvedRoles.Web.ServerConnections.RemotingMode | Should Be 'WebDeployHandler'
            }
        }

        Context "when used with filters" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes @('node1', 'node2')
                ServerRole Web -Steps @('TestFunc', 'TestDSC') -ServerConnections WebServer
                ServerRole Database -Steps @('TestFunc') -ServerConnections WebServer
                ServerRole Database2 -Steps @('TestFunc2') -ServerConnections WebServer
            }

            $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{} `
                             -StepsFilter 'TestFunc' -ServerRolesFilter @('Web', 'Database') -NodesFilter 'node1'

            It "should properly resolve roles" {
                $resolvedRoles.Count | Should Be 2
            
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Web.ServerConnections.Count | Should Be 1
                $resolvedRoles.Web.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Web.ServerConnections.Nodes | Should Be 'node1'
                $resolvedRoles.Database | Should Not Be $null
                $resolvedRoles.Database.Steps.Name | Should Be @('TestFunc')
                $resolvedRoles.Database.ServerConnections.Count | Should Be 1
                $resolvedRoles.Database.ServerConnections.Name | Should Be 'WebServer'
                $resolvedRoles.Database.ServerConnections.Nodes | Should Be 'node1'
            }

        }

        Context "when used with StepSettings" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServer -Nodes 'node1'
                ServerRole Web -Steps @('TestFunc', 'TestDSC') -ServerConnections WebServer -RunRemotely

                StepSettings TestFunc -RequiredPackages 'package1'
            }

            Environment Local {
                ConfigurationSettings TestFunc -RunRemotely:$false
            }

            It "should properly resolve roles for Default environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Default -ResolvedTokens @{}
                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.Steps.Type | Should Be @('Configuration', 'Function')
                $resolvedRoles.Web.Steps[0].RequiredPackages | Should Be 'package1'
                $resolvedRoles.Web.Steps[1].RequiredPackages | Should Be $null
                $resolvedRoles.Web.Steps[0].RunRemotely | Should Be $true
                $resolvedRoles.Web.Steps[1].RunRemotely | Should Be $true
                
            }

            It "should properly resolve roles for Local environment" {
                $resolvedRoles = Resolve-ServerRoles -AllEnvironments $Global:Environments -Environment Local -ResolvedTokens @{}
                $resolvedRoles.Count | Should Be 1
                $resolvedRoles.Web | Should Not Be $null
                $resolvedRoles.Web.Steps.Name | Should Be @('TestFunc', 'TestDSC')
                $resolvedRoles.Web.Steps.Type | Should Be @('Configuration', 'Function')
                $resolvedRoles.Web.Steps[0].RequiredPackages | Should Be @('package1')
                $resolvedRoles.Web.Steps[1].RequiredPackages | Should Be $null
                $resolvedRoles.Web.Steps[0].RunRemotely | Should Be $false
                $resolvedRoles.Web.Steps[1].RunRemotely | Should Be $true
            }
            
        }

    }
}

