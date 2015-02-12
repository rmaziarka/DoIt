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

Describe -Tag "PSCI.unit" "New-DeploymentPlan" {
    InModuleScope PSCI.deploy {
        Context "when used with two environments and two server roles" {
            Initialize-Deployment

            Environment Default {
			    ServerRole WebServer -Configurations @('config1') -Nodes @('machine0')
		    }

		    Environment Local {
                ServerRole DbServer -Configurations @('config3') -Nodes @('machine2')
			    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2') -RunOn 'machine1' -CopyTo 'folder'               
		    }

            function config1 {}
            function config2 {}
            function config3 {}

            It "should properly initialize internal structures for ServerRolesFilter = WebServer" {
                $environment = 'Local'

                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'WebServer'

                $deploymentPlan.Count | Should Be 4

                $deploymentPlan[0].ServerRole | Should Be 'WebServer'
                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].CopyTo | Should Be 'folder'
                $deploymentPlan[0].IsLocalRun | Should Be $true
                
                $deploymentPlan[1].ServerRole | Should Be 'WebServer'
                $deploymentPlan[1].Configuration.Name | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[1].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[1].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[1].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[1].CopyTo | Should Be 'folder'
                $deploymentPlan[1].IsLocalRun | Should Be $false
                

                $deploymentPlan[2].ServerRole | Should Be 'WebServer'
                $deploymentPlan[2].Configuration.Name | Should Be 'config2'
                $deploymentPlan[2].ConnectionParams | Should Not Be $null
                $deploymentPlan[2].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[2].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[2].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[2].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[2].CopyTo | Should Be 'folder'
                $deploymentPlan[2].IsLocalRun | Should Be $true

                $deploymentPlan[3].ServerRole | Should Be 'WebServer'
                $deploymentPlan[3].Configuration.Name | Should Be 'config2'
                $deploymentPlan[3].ConnectionParams | Should Not Be $null
                $deploymentPlan[3].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[3].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[3].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[3].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[3].CopyTo | Should Be 'folder'
                $deploymentPlan[3].IsLocalRun | Should Be $false
            }

            It "should properly initialize internal structures for ServerRolesFilter = empty" {
                $environment = 'Local'

                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath

                $deploymentPlan.Count | Should Be 5

                $deploymentPlan[0].ServerRole | Should Be 'WebServer'
                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].CopyTo | Should Be 'folder'
                $deploymentPlan[0].IsLocalRun | Should Be $true

                $deploymentPlan[4].ServerRole | Should Be 'DbServer'
                $deploymentPlan[4].Configuration.Name | Should Be 'config3'
                $deploymentPlan[4].ConnectionParams | Should Not Be $null
                $deploymentPlan[4].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[4].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[4].RunOnConnectionParams | Should Be $null
                $deploymentPlan[4].CopyTo | Should BeNullOrEmpty
                $deploymentPlan[4].IsLocalRun | Should Be $false

            }

        }

        Context "when used with three environments inheritance" {
            Initialize-Deployment
            $cred = ConvertTo-PSCredential -User "Test" -Password "Test"

            Environment Default {
			    ServerRole WebServer -Configurations @('config1') -Nodes @('machine0')
                ServerRole SSRSServer -Configurations @('config1') -Nodes @('machine0')           
		    }

		    Environment Local {
			    ServerRole WebServer -Configurations @('config1', 'config2') -Nodes @('machine1','machine2') -RunOn 'machine1' -CopyTo 'folder' -RemotingMode WebDeployAgentService -RemotingCredential $cred
                ServerRole DbServer -Configurations @('config3') -Nodes @('machine2')
		    }

		    Environment Tests -BasedOn Local {
			    ServerRole WebServer -Configurations @('config1') -RunOn 'machine4' -CopyTo 'folder2'
                ServerRole SSASServer -Configurations @('config4') -Nodes @('machine4')
                ServerRole SSRSServer -Nodes $null
		    }

            function config1 {}
            function config2 {}
            function config3 {}
            function config4 {}

            $environment = 'Tests'
            
            It "should properly plan WebServer deployment" {
                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'WebServer'

                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'WebDeployAgentService'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine4'
                $deploymentPlan[0].CopyTo | Should Be 'folder2'
                $deploymentPlan[0].IsLocalRun | Should Be $false

                $deploymentPlan[1].Configuration.Name | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[1].ConnectionParams.RemotingMode | Should Be 'WebDeployAgentService'
                $deploymentPlan[1].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[1].RunOnConnectionParams.Nodes[0] | Should Be 'machine4'
                $deploymentPlan[1].CopyTo | Should Be 'folder2'
                $deploymentPlan[1].IsLocalRun | Should Be $false
            }

            It "should properly plan DbServer deployment" {
                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'DbServer'

                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine2'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].Configuration.Name | Should Be 'config3'
                $deploymentPlan[0].IsLocalRun | Should Be $false
            }

            It "should properly plan SSASServer deployment" {
                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'SSASServer'

                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine4'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].Configuration.Name | Should Be 'config4'
                $deploymentPlan[0].IsLocalRun | Should Be $false
            }
 
            It "should properly plan SSRSServer deployment" {
                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'SSRSServer'

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
                ServerRole WebConfig -Configurations @('config1') -Nodes @('machine1') -RunOnCurrentNode -CopyTo {$Tokens.General.DeploymentPath} -RemotingCredential {$Tokens.General.Credentials}
		    }

            function config1 {}

            $environment = 'Tests'

            It "should properly assign credentials" {
                $dscOutputPath = 'dscOutput'
                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath -ServerRolesFilter 'WebConfig'

                $deploymentPlan.Count | Should Be 1

                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].ConnectionParams.Credential | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Credential.Username | Should Be 'Test'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 'machine1'
                $deploymentPlan[0].CopyTo | Should Be 'D:\Deploy'
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
                ServerRole WebServer -Configurations @('config1') -Nodes @('s01', 's02') -RunOnCurrentNode -CopyTo {$Tokens.General.DeploymentPath} -RemotingCredential {$Tokens.General.Credentials}
		    }

            function config1 {}

            It "should properly plan deployment" {
                $environment = 'Tests'
                $dscOutputPath = 'dscOutput'

                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath

                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].CopyTo | Should Be 'D:\Deployment'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 's01'
                $deploymentPlan[0].ConnectionParams.RemotingMode | Should Be 'PSRemoting'
                $deploymentPlan[0].ConnectionParams.Credential | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Credential.Username | Should Be 'Test'
                $deploymentPlan[0].RunOnConnectionParams | Should Not Be $null
                $deploymentPlan[0].RunOnConnectionParams.Nodes[0] | Should Be 's01'
                $deploymentPlan[0].IsLocalRun | Should Be $true

                $deploymentPlan[1].Configuration.Name | Should Be 'config1'
                $deploymentPlan[1].CopyTo | Should Be 'C:\Deployment'
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
                ServerRole WebServer -Configurations @('config1') -Nodes { $Tokens.General.AllNodes }
		    }

            function config1 {}

            It "should properly plan deployment" {
                $environment = 'Test1'
                $dscOutputPath = 'dscOutput'

                $deploymentPlan = New-DeploymentPlan -AllEnvironments $Global:Environments -Environment $environment -DscOutputPath $dscOutputPath

                $deploymentPlan.Count | Should Be 2

                $deploymentPlan[0].Configuration.Name | Should Be 'config1'
                $deploymentPlan[0].ConnectionParams | Should Not Be $null
                $deploymentPlan[0].ConnectionParams.Nodes[0] | Should Be 'Node1'
                $deploymentPlan[0].RunOnConnectionParams | Should Be $null
                $deploymentPlan[0].IsLocalRun | Should Be $false

                $deploymentPlan[1].Configuration.Name | Should Be 'config1'
                $deploymentPlan[1].ConnectionParams | Should Not Be $null
                $deploymentPlan[1].ConnectionParams.Nodes[0] | Should Be 'Node2'
                $deploymentPlan[1].RunOnConnectionParams | Should Be $null
                $deploymentPlan[1].IsLocalRun | Should Be $false
           }
       }
    }
}
