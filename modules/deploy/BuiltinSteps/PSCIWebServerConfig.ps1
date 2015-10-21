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

Configuration PSCIWebServerConfig {

    <#
    .SYNOPSIS
    Configures IIS - creates application pools / websites / virtual directories / web applications.

    .DESCRIPTION
    This is DSC configuration, so it should be invoked locally (but can also be invoked with -RunRemotely).
    It uses following tokens (every entry is optional):
    - **ApplicationPool** - hashtable (or array of hashtables) describing configuration of Application Pools, each entry should contain following keys:
      - **Name** (mandatory)
      - **Identity** - one of ApplicationPoolIdentity, LocalSystem, LocalService, NetworkService, SpecificUser (default: ApplicationPoolIdentity)
      - **Credential** - PSCredential, used only if Identity = SpecificUser

    - **Website** - hashtable (or array of hashtables) describing configuration of Websites, each entry should contain following keys:
      - **Name** (mandatory)
      - **Port** (mandatory)
      - **PhysicalPath** (mandatory)
      - **ApplicationPool** (default: DefaultAppPool) - note if application pool is configured in the same step, also proper ACLs to PhysicalPath will be added.
    
    - **VirtualDirectories** - hashtable (or array of hashtables) describing configuration of Virtual Directories created under websites, each entry should contain following keys:
      - **Name** (mandatory)
      - **PhysicalPath** (mandatory)
      - **Website** (mandatory)

    - **WebApplications** - hashtable (or array of hashtables) describing configuration of Web Applications, each entry should contain following keys:
      - **Name** (mandatory)
      - **PhysicalPath** (mandatory)
      - **Website** (mandatory)
      - **ApplicationPool** (default: <inherited from site>) - note if application pool is configured in the same step, also proper ACLs to PhysicalPath will be added.

    See also [xWebAdministration](https://github.com/PowerShell/xWebAdministration).

    .EXAMPLE
    ```
    Import-Module "$PSScriptRoot\..\PSCI\PSCI.psd1" -Force

    # clear any old Environment definitions - required only for -NoConfigFiles deployments
    $Global:Environments = @{}

    Environment Local { 
        ServerConnection WebServer -Nodes localhost
        ServerRole Web -Steps 'PSCIWebServerConfig' -ServerConnection WebServer

        Tokens Web @{
            ApplicationPool = @( @{ Name = 'MyWebAppPool'; Identity = 'ApplicationPoolIdentity' },
                                 @{ Name = 'MySecondAppPool'; Identity = 'ApplicationPoolIdentity' }
                                 #@{ Name = 'MyThirdAppPool'; Identity = 'SpecificUser'; Credential = { $Tokens.Credentials.MyCredential } }
                              )
            Website = @( @{ Name = 'MyWebsite'; Port = 801; PhysicalPath = 'c:\inetpub\wwwroot\MyWebsite'; ApplicationPool = 'MyWebAppPool' },
                         @{ Name = 'MySecondWebsite'; Port = 802; PhysicalPath = 'c:\inetpub\wwwroot\MySecondWebsite'; ApplicationPool = 'MySecondAppPool' }
                       )
            #VirtualDirectory = @{ Name = 'MyVirtualDir'; PhysicalPath = 'c:\inetpub\wwwroot\MyWebSite\VirtualDir'; Website = 'MyWebsite' }
            WebApplication = @{ Name = 'MyApp'; PhysicalPath = 'c:\inetpub\wwwroot\MyApp'; Website = 'MyWebsite'; ApplicationPool = 'MyWebAppPool' }
        }

    }

    Install-DscResources -ModuleNames 'xWebAdministration', 'cIIS', 'cACL'

    try { 
        Start-Deployment -Environment Local -NoConfigFiles
    } catch {
        Write-ErrorRecord
    }
    ```
    Configures IIS according to the settings specified in 'Web' tokens section.

    #>

    Import-DSCResource -Module cIIS
    Import-DSCResource -Module cACL

    Node $AllNodes.NodeName {

        $applicationPool = Get-TokenValue -Name 'ApplicationPool'
        $website = Get-TokenValue -Name 'Website'
        $virtualDirectory = Get-TokenValue -Name 'VirtualDirectory'
        $webApplication = Get-TokenValue -Name 'WebApplication'

        if (!$applicationPool -and !$website -and !$virtualDirectory -and $webApplication) {
            Write-Log -Warn "No configuration specified for PSCIWebServerConfig. Please ensure there is at least one token entry with name 'ApplicationPool', 'Website', 'VirtualDirectory' or 'WebApplication'."
            return
        }

        # we need to ensure each File resource has unique key
        $directoriesToCreate = @{}

        foreach ($webAppPool in $applicationPool) {
            if (!$webAppPool.Name) {
                throw "Missing web application pool name - token 'ApplicationPool', key 'Name'"
            }
            $username = ''
            $password = ''
            if (!$webAppPool.Identity) {
                $webAppPool.Identity = 'ApplicationPoolIdentity'
            } elseif ($webAppPool.Identity -eq 'SpecificUser') {
                if (!$webAppPool.Credential) {
                    throw "Identity is set to 'SpecificUser' but Credential has not been provided - token 'ApplicationPool' (name '$($webAppPool.Name)'), key 'Credential'."
                }
                if ($webAppPool.Credential -isnot [PSCredential]) {
                    throw "Invalid credential type: $($webAppPool.Credential.GetType().ToString()) - token 'ApplicationPool' (name '$($webAppPool.Name)'), key 'Credential'."
                }
                $username = $webAppPool.Credential.UserName
                $password = $webAppPool.Credential.GetNetworkCredential().Password
            }

            Write-Log -Info "Preparing application pool '$($webAppPool.Name)', IdentityType '$($webAppPool.Identity)', Username '$username'"

            if ($username) { 
                cAppPool "AppPool_$($webappPool.Name)" { 
                    Name = $webAppPool.Name
                    Ensure = 'Present'
                    ManagedRuntimeVersion = 'v4.0'
                    ManagedPipelineMode = 'Integrated'
                    StartMode = 'AlwaysRunning'
                    IdentityType = $webAppPool.Identity
                    UserName = $username
                    Password = $password
                }
            } else {
                cAppPool "AppPool_$($webappPool.Name)" { 
                    Name = $webAppPool.Name
                    Ensure = 'Present'
                    ManagedRuntimeVersion = 'v4.0'
                    ManagedPipelineMode = 'Integrated'
                    StartMode = 'AlwaysRunning'
                    IdentityType = $webAppPool.Identity
                }
            }
        }

        foreach ($site in $Website) {
            if (!$site.Name) {
                throw "Missing site name - token 'Website', key 'Name'"
            }
            if (!$site.PhysicalPath) {
                throw "Missing site physical path - token 'Website' (name '$($site.Name)'), key 'PhysicalPath'"
            }
            if (!$site.Port) {
                throw "Missing site port - token 'Website' (name '$($site.Name)'), key 'Port'"
            }
            if (!$site.ApplicationPool) {
                $site.ApplicationPool = 'DefaultAppPool'
            }

            $matchingWebAppPool = $applicationPool.Where({ $_.Name -ieq $site.ApplicationPool })

            # TODO: SSL

            Write-Log -Info "Preparing website '$($site.Name)', Port '$($site.Port), PhysicalPath '$($site.PhysicalPath)', ApplicationPool '$($site.ApplicationPool)'"

            $depends = @()
            if (!$directoriesToCreate.ContainsKey($site.PhysicalPath)) { 
                File "WebsiteDir_$($site.Name)" {
                    DestinationPath = $site.PhysicalPath
                    Ensure = 'Present'
                    Type = 'Directory'
                }
                $directoriesToCreate[$site.PhysicalPath] = $true
                $depends += "[File]WebsiteDir_$($site.Name)"
            }

            if ($matchingWebAppPool) {
                $depends += "[cAppPool]AppPool_$($matchingWebAppPool.Name)"
            }

            cWebsite "Website_$($site.Name)" { 
                Name   = $site.Name
                Ensure = 'Present'
                State  = 'Started'
                BindingInfo = OBJ_cWebBindingInformation { 
                    Port = $site.Port
                }
                PhysicalPath = $site.PhysicalPath
                ApplicationPool = $site.ApplicationPool
                DependsOn = $depends
            }

            if (!$matchingWebAppPool) { 
                Write-Log -Warn "Web application pool ('$($site.ApplicationPool)') is not configured (website '$($site.Name)') - ACL will not be set. Please add this pool to 'ApplicationPool' token."
            } else {
                $aclUserName = $null
                if ($matchingWebAppPool.Identity -eq 'ApplicationPoolIdentity') {
                    $aclUserName = "IIS AppPool\$($matchingWebAppPool.Name)"
                } elseif ($matchingWebAppPool.Identity -eq 'SpecificUser') {
                    $aclUserName = $matchingWebAppPool.Credential.UserName
                } 

                if ($aclUserName) { 
                    Write-Log -Info "Preparing ACL - R for directory '$($site.PhysicalPath)' to user '$aclUserName'"

                    cSimpleAcl "WebsiteAcl_$($site.Name)" {
                        Path = $site.PhysicalPath
                        Ensure = 'Present'
                        Username = $aclUserName
                        Permission = 'Read'
                        Type = 'Allow'
                        Inherit = $true
                        DependsOn = "[cWebsite]Website_$($site.Name)"
                    }
                }
            }
        }

        foreach ($virtualDir in $virtualDirectory) {
            if (!$virtualDir.Name) {
                throw "Missing virtual directory name - token 'VirtualDirectory', key 'Name'"
            }
            if (!$virtualDir.PhysicalPath) {
                throw "Missing virtual directory physical path - token 'VirtualDirectory' (name '$($virtualDir.Name)'), key 'PhysicalPath'"
            }
            if (!$virtualDir.Website) {
                throw "Missing virtual directory website - token 'VirtualDirectory' (name '$($virtualDir.Name)'), key 'Website'"
            }

            $depends = @()
            if (!$directoriesToCreate.ContainsKey($virtualDir.PhysicalPath)) { 
                File "VirtualDirectoryDir_$($virtualDir.Name)" {
                    DestinationPath = $virtualDir.PhysicalPath
                    Ensure = 'Present'
                    Type = 'Directory'
                }
                $directoriesToCreate[$virtualDir.PhysicalPath] = $true
                $depends += "[File]VirtualDirectoryDir_$($virtualDir.Name)"
            }

            cWebVirtualDirectory "VirtualDirectory_$($virtualDir.Name)" {
                Name = $virtualDir.Name
                Website = $virtualDir.Website
                WebApplication = ''
                PhysicalPath = $virtualDir.PhysicalPath
                Ensure = 'Present'
                DependsOn = $depends
            }

        }
      
        foreach ($webApp in $webApplication) {
            if (!$webApp.Name) {
                throw "Missing web application name - token 'WebApplication', key 'Name'"
            }
            if (!$webApp.PhysicalPath) {
                throw "Missing web application physical path - token 'WebApplication' (name '$($webApp.Name)'), key 'PhysicalPath'"
            }
            if (!$webApp.Website) {
                throw "Missing web application website - token 'WebApplication' (name '$($webApp.Name)'), key 'Website'"
            }
            
            $matchingWebsite = $website.Where({ $_.Name -ieq $webApp.Website })
            $matchingWebAppPool = $applicationPool.Where({ $_.Name -ieq $webApp.ApplicationPool })

            Write-Log -Info "Preparing web application '$($webApp.Name)', PhysicalPath '$($webApp.PhysicalPath)', Website '$($webApp.Website)', ApplicationPool '$($webApp.ApplicationPool)'"

            $depends = @()
            if (!$directoriesToCreate.ContainsKey($webApp.PhysicalPath)) { 
                File "WebApplicationDir_$($webApp.Name)" {
                    DestinationPath = $webApp.PhysicalPath
                    Ensure = 'Present'
                    Type = 'Directory'
                }
                $directoriesToCreate[$webApp.PhysicalPath] = $true
                $depends += "[File]WebApplicationDir_$($webApp.Name)"
            }

            if ($matchingWebsite) {
                $depends += "[cWebsite]Website_$($site.Name)"
            }

            cWebApplication "WebApplication_$($webApp.Name)" {
                Name = $webApp.Name
                Ensure = 'Present'
                Website = $webApp.Website
                WebAppPool = $webApp.ApplicationPool
                PhysicalPath = $webApp.PhysicalPath
                DependsOn = $depends
            }

            if (!$matchingWebAppPool) { 
                Write-Log -Warn "Web application pool ('$($webAppPool.ApplicationPool)') is not configured (web application '$($webApp.Name)') - ACL will not be set. Please add this pool to 'ApplicationPool' token."
            } else {
                $aclUserName = $null
                if ($matchingWebAppPool.Identity -eq 'ApplicationPoolIdentity') {
                    $aclUserName = "IIS AppPool\$($matchingWebAppPool.Name)"
                } elseif ($matchingWebAppPool.Identity -eq 'SpecificUser') {
                    $aclUserName = $matchingWebAppPool.Credential.UserName
                } 

                if ($aclUserName) { 
                    Write-Log -Info "Preparing ACL - R for directory '$($site.PhysicalPath)' to user '$aclUserName'"

                    cSimpleAcl "WebApplicationAcl_$($webApp.Name)" {
                        Path = $webApp.PhysicalPath
                        Ensure = 'Present'
                        Username = $aclUserName
                        Permission = 'Read'
                        Type = 'Allow'
                        Inherit = $true
                        DependsOn = "[cWebApplication]WebApplication_$($webApp.Name)"
                    }
                }
            }
        }
    }
}