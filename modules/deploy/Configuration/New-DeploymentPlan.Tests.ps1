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

Import-Module -Name "$PSScriptRoot\..\..\..\PSCI.psm1" -Force

Describe -Tag "PSCI.unit" "New-DeploymentPlan" {
    InModuleScope PSCI.deploy {

        function config1 {}
        function config2 {}
        function config3 {}
        function config4 {}

        Configuration dsc1 {
            param ($NodeName, $Environment, $Tokens)

            Node $NodeName {
                File test {
                    DestinationPath = 'c:\test'
                }
            }
        }



        Context "when used with two environments and two server roles" {
            Initialize-Deployment

            Environment Default {
                ServerConnection WebServers -Nodes 'machine0'
			    ServerRole Web -Configurations @('config1') -ServerConnections WebServers
		    }

		    Environment Local {
                ServerConnection DbServers -Nodes 'machine2'
                ServerConnection WebServers -Nodes 'machine1','machine2' -PackageDirectory 'folder'
                
                ServerRole Database -Configurations @('config3') -ServerConnection DbServers
			    ServerRole Web -Configurations @('config1', 'config2') -RunOn 'machine1' 
		    }

            It "should properly initialize internal structures for ServerRolesFilter = WebServer" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Local' -DscOutputPath 'dscOutput' -ServerRolesFilter 'Web'

                $deploymentPlan.Count | Should Be 4

                $deploymentPlan[0].ServerRole | Should Be 'Web'
                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].ConfigurationType | Should Be 'Function'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].PackageDirectory | Should Be 'folder'
                $deploymentPlan[0].IsLocalRun | Should Be $true
                
                $deploymentPlan[1].ServerRole | Should Be 'Web'
                $deploymentPlan[1].ConfigurationName | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[1].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[1].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[1].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[1].PackageDirectory | Should Be 'folder'
                $deploymentPlan[1].IsLocalRun | Should Be $false
                

                $deploymentPlan[2].ServerRole | Should Be 'Web'
                $deploymentPlan[2].ConfigurationName | Should Be 'config2'
                $deploymentPlan[2].ConfigurationType | Should Be 'Function'
                $deploymentPlan[2].ConnectionParams | Should Not Be $null
                $deploymentPlan[2].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[2].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[2].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[2].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[2].PackageDirectory | Should Be 'folder'
                $deploymentPlan[2].IsLocalRun | Should Be $true

                $deploymentPlan[3].ServerRole | Should Be 'Web'
                $deploymentPlan[3].ConfigurationName | Should Be 'config2'
                $deploymentPlan[3].ConnectionParams | Should Not Be $null
                $deploymentPlan[3].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[3].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[3].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[3].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[3].PackageDirectory | Should Be 'folder'
                $deploymentPlan[3].IsLocalRun | Should Be $false
            }

            It "should properly initialize internal structures for ServerRolesFilter = empty" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Local' -DscOutputPath 'dscOutput'

                $deploymentPlan.Count | Should Be 5

                $deploymentPlan[0].ServerRole | Should Be 'Web'
                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].PackageDirectory | Should Be 'folder'
                $deploymentPlan[0].IsLocalRun | Should Be $true

                $deploymentPlan[4].ServerRole | Should Be 'Database'
                $deploymentPlan[4].ConfigurationName | Should Be 'config3'
                $deploymentPlan[4].ConnectionParams | Should Not Be $null
                $deploymentPlan[4].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[4].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[4].RunOnConnectionParams | Should Be $null
                $deploymentPlan[4].PackageDirectory | Should Be 'c:\PSCIPackage'
                $deploymentPlan[4].IsLocalRun | Should Be $false

            }

        }

        Context "when used with three environments inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

            Environment Default {
                ServerConnection MyServers -Nodes @('machine0')
			    ServerRole Web -Configurations @('config1') -ServerConnections MyServers
                ServerRole SSRSServer -Configurations @('config1') -ServerConnections MyServers          
		    }

		    Environment Local {
                ServerConnection WebServers -Nodes @('machine1','machine2') -RemotingMode WebDeployAgentService -RemotingCredential $cred -PackageDirectory 'folder'
                ServerConnection DbServers -Nodes @('machine2')
			    ServerRole Web -Configurations @('config1', 'config2') -RunOn 'machine1' -ServerConnections WebServers
                ServerRole Database -Configurations @('config3') -ServerConnection DbServers
		    }

		    Environment Tests -BasedOn Local {
			    ServerRole Web -Configurations @('config1') -RunOn $null -RunRemotely
                ServerRole SSAS -Configurations @('config4') -ServerConnections (ServerConnection SSASServers -Nodes machine4)
                ServerRole SSRS -ServerConnections $null
		    }

            It "should properly plan Web deployment" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput' -ServerRolesFilter 'Web'

                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'WebDeployAgentService'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].PackageDirectory | Should Be 'folder'
                $deploymentPlan[0].IsLocalRun | Should Be $true

                $deploymentPlan[1].ConfigurationName | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[1].ConnectionParams.RemotingMode | Should Be 'WebDeployAgentService'
                $deploymentPlan[1].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[1].RunOnConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[1].PackageDirectory | Should Be 'folder'
                $deploymentPlan[1].IsLocalRun | Should Be $true
            }

            It "should properly plan Database deployment" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput' -ServerRolesFilter 'Database'

                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].ConfigurationName | Should Be 'config3'
                $deploymentPlan[0].IsLocalRun | Should Be $false
            }

            It "should properly plan SSAS deployment" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput' -ServerRolesFilter 'SSAS'

                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine4'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].ConfigurationName | Should Be 'config4'
                $deploymentPlan[0].IsLocalRun | Should Be $false
            }
 
            It "should properly plan SSRS deployment" {
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput' -ServerRolesFilter 'SSRS'

                $deploymentPlan.Count | Should Be 0
            }
        }

        Context "when used with credentials" {
            Initialize-Deployment
        
            Environment Default {
                Tokens General @{
                    Credentials = ConvertTo-PSCredential -User "default" -Password "default"
                    DeploymentPath = 'C:\Deploy'
                }
            }

            Environment Tests {
                Tokens General @{
                    Credentials = ConvertTo-PSCredential -User "Test" -Password "Test"
                    DeploymentPath = 'D:\Deploy'
                }
            }

            Environment Tests {  
                ServerConnection WebServers -Nodes @('machine1') -PackageDirectory {$Tokens.General.DeploymentPath} -RemotingCredential {$Tokens.General.Credentials}
                ServerRole WebConfig -Configurations @('config1') -RunRemotely -ServerConnections WebServers
		    }

            $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput' -ServerRolesFilter 'WebConfig'

            It "should properly assign credentials" {
                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].ConnectionParams.Credential | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Credential.Username | Should Be 'Test'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].PackageDirectory | Should Be 'D:\Deploy'
                $deploymentPlan[0].IsLocalRun | Should Be $true
            }
        }

        Context "when used with token replacements" {
            Initialize-Deployment

            Environment Tests {
		        Tokens WebConfig @{
                    SessionTimeout = '30'
		            DbConnectionString = 'Server={0};Database=Test;Integrated Security=SSPI;' -f '${Node}'
	            }

                Tokens General @{
                    DeploymentPath = 'C:\Deployment'
                    Credentials = ConvertTo-PSCredential -User "Test" -Password "Test"
                }

		        Server 's01' {
			        Tokens General @{
                        DeploymentPath = 'D:\Deployment'
	                }
		        }
            }

            Environment Tests {
                ServerConnection WebServers -Nodes @('s01', 's02') -PackageDirectory {$Tokens.General.DeploymentPath} -RemotingCredential {$Tokens.General.Credentials}
                ServerRole Web -Configurations @('config1') -RunRemotely -ServerConnections WebServers
		    }

            $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Tests' -DscOutputPath 'dscOutput'

            It "should properly plan deployment" {
                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].PackageDirectory | Should Be 'D:\Deployment'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 's01'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].ConnectionParams.Credential | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Credential.Username | Should Be 'Test'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 's01'
                $deploymentPlan[0].IsLocalRun | Should Be $true

                $deploymentPlan[1].ConfigurationName | Should Be 'config1'
                $deploymentPlan[1].PackageDirectory | Should Be 'C:\Deployment'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 's02'
                $deploymentPlan[1].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[1].ConnectionParams.Credential | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Credential.Username | Should Be 'Test'
                $deploymentPlan[1].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[1].RunOnConnectionParams.Nodes[0] | Should Be 's02' 
                $deploymentPlan[1].IsLocalRun | Should Be $true
           }
       }

        Context "when used with nodes as scriptblock" {
            Initialize-Deployment

            Environment Test1 {
                Tokens General @{
                    AllNodes = @('Node1','Node2')
                }
            }

            Environment Test2 {
                Tokens General @{			    
                    AllNodes = $null
		        }
            }

            Environment Default {
                ServerRole Web -Configurations @('config1') -ServerConnections (ServerConnection WebServers -Nodes { $Tokens.General.AllNodes })
		    }

            $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Test1' -DscOutputPath 'dscOutput'

            It "should properly plan deployment" {
                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].ConfigurationName | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'Node1'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].IsLocalRun | Should Be $false

                $deploymentPlan[1].ConfigurationName | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'Node2'
                $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                $deploymentPlan[1].IsLocalRun | Should Be $false
           }
        }

        Context "when used with DSC configuration" {
            try { 
                Initialize-Deployment

                Environment Test1 {
                    ServerRole Web -Configurations 'dsc1' -ServerConnections (ServerConnection WebServers -Nodes @('node1', 'node2'))
                }

                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Test1' -DscOutputPath 'dscOutput'

                It "should properly plan deployment" {
                    $deploymentPlan.Count | Should Be 2

                    $deploymentPlan[0].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[0].ConfigurationType | Should Be 'Configuration'
                    Test-Path -Path 'dscOutput\node1\dsc1\node1.mof' -PathType Leaf | Should Be $true
                    $deploymentPlan[0].ConfigurationMofDir | Should Be (Resolve-Path -Path 'dscOutput\node1\dsc1').Path
                    
                    $deploymentPlan[0].ConnectionParams | Should Not Be $null
                    $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'node1'
                    $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[0].IsLocalRun | Should Be $false

                    $deploymentPlan[1].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[1].ConfigurationType | Should Be 'Configuration'
                    Test-Path -Path 'dscOutput\node2\dsc1\node2.mof' -PathType Leaf | Should Be $true
                    $deploymentPlan[1].ConfigurationMofDir | Should Be (Resolve-Path -Path 'dscOutput\node2\dsc1').Path
                    $deploymentPlan[1].ConnectionParams | Should Not Be $null
                    $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'node2'
                    $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[1].IsLocalRun | Should Be $false
                }
            } finally {
                Remove-Item -Path 'dscOutput' -Force -Recurse -ErrorAction SilentlyContinue
            }
        }

        Context "when used with ConfigurationSettings" {
            try { 
                Initialize-Deployment

                Environment Default {
                    ServerRole Web -Configurations 'dsc1','config1' -ServerConnections (ServerConnection WebServers -Nodes @('node1', 'node2')) -RequiredPackages 'package1'
                    ConfigurationSettings config1 -RunRemotely
                }

                Environment Test1 {
                    ConfigurationSettings dsc1 -RequiredPackages 'package2'
                }

                Environment Test2 {
                   ConfigurationSettings dsc1 -RequiredPackages { if ($NodeName -eq 'node1') { 'packagen1' } else { 'packagen2' } }
                }

                It "should properly plan deployment for Environment Default" {
                    $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment Default -DscOutputPath 'dscOutput'
                    $deploymentPlan.Count | Should Be 4

                    $deploymentPlan[0].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[0].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[0].RequiredPackages | Should Be 'package1'
                    
                    $deploymentPlan[1].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[1].ConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[1].RequiredPackages | Should Be 'package1'

                    $deploymentPlan[2].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[2].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RunOnConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RequiredPackages | Should Be 'package1'

                    $deploymentPlan[3].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[3].ConnectionParams.Nodes[0] | Should Be 'node2'
                    $deploymentPlan[3].RunOnConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[3].RequiredPackages | Should Be 'package1'
                }
                
                It "should properly plan deployment for Environment Test1" {
                    $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment 'Test1' -DscOutputPath 'dscOutput'
                    $deploymentPlan.Count | Should Be 4

                    $deploymentPlan[0].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[0].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[0].RequiredPackages | Should Be 'package2'
                    
                    $deploymentPlan[1].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[1].ConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[1].RequiredPackages | Should Be 'package2'

                    $deploymentPlan[2].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[2].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RunOnConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RequiredPackages | Should Be 'package1'

                    $deploymentPlan[3].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[3].ConnectionParams.Nodes[0] | Should Be 'node2'
                    $deploymentPlan[3].RunOnConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[3].RequiredPackages | Should Be 'package1'
                }

                It "should properly plan deployment for Environment Test1" {
                    $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment Test2 -DscOutputPath 'dscOutput'
                    $deploymentPlan.Count | Should Be 4

                    $deploymentPlan[0].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[0].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[0].RequiredPackages | Should Be 'packagen1'
                    
                    $deploymentPlan[1].ConfigurationName | Should Be 'dsc1'
                    $deploymentPlan[1].ConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                    $deploymentPlan[1].RequiredPackages | Should Be 'packagen2'

                    $deploymentPlan[2].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[2].ConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RunOnConnectionParams.Nodes | Should Be 'node1'
                    $deploymentPlan[2].RequiredPackages | Should Be 'package1'

                    $deploymentPlan[3].ConfigurationName | Should Be 'config1'
                    $deploymentPlan[3].ConnectionParams.Nodes[0] | Should Be 'node2'
                    $deploymentPlan[3].RunOnConnectionParams.Nodes | Should Be 'node2'
                    $deploymentPlan[3].RequiredPackages | Should Be 'package1'
                }
            } finally {
                Remove-Item -Path 'dscOutput' -Force -Recurse -ErrorAction SilentlyContinue
            }
        }
    }
}
