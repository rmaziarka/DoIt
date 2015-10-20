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


configuration PSCIWindowsFeatures {

    <#
    .SYNOPSIS
    Ensures specific Windows Features are installed.

    .DESCRIPTION
    It uses following tokens:
    - **IsClientWindows** - if true, features will be installed using dism, otherwise Add-WindowsFeature (the latter is available only on Windows Server)
    - **WindowsFeatures** - array of windows features to add. 
    
    To list available feature names on client you can use `dism /online /Get-Features`. On server `Get-WindowsFeature`.

    .EXAMPLE
    ```
    Import-Module "$PSScriptRoot\..\PSCI\PSCI.psd1" -Force

    Environment Local { 
        ServerConnection WebServer -Nodes localhost
        ServerRole Web -Steps 'PSCIWindowsFeatures' -ServerConnection WebServer

        Tokens Web @{
            IsClientWindows = $true
            WindowsFeatures = 'IIS-WebServerRole', 'IIS-ASPNET45', 'IIS-WindowsAuthentication'
        }
    }

    Install-DscResources -ModuleNames xDismFeature

    Start-Deployment -Environment Local -NoConfigFiles
    ```
    Install specified roles using PSCI configuration DSL.

    .EXAMPLE
    ```
    PSCIWindowsFeatures -OutputPath 'test' -ConfigurationData @{ AllNodes = @( @{ 
        NodeName = 'localhost'; 
        Tokens = @{ 
            IsClientWindows = $true
            WindowsFeatures = 'IIS-WebServerRole', 'IIS-ASPNET45', 'IIS-WindowsAuthentication'
        }
    } ) }

    Start-DscConfiguration -Path 'test' -ComputerName localhost -Wait -Force -Verbose
    ```
    Install specified roles manually running DSC configuration.
    #>

    Import-DSCResource -Module xDismFeature

    Node $AllNodes.NodeName {        
        $isClientWindows = Get-TokenValue -Name 'IsClientWindows'
        $windowsFeatures = Get-TokenValue -Name 'WindowsFeatures' -Mandatory
        Write-Log -Info "Preparing PSCIWindowsFeatures, node '$($Node.NodeName)': WindowsFeatures $($windowsFeatures -join ', '); IsClientWindows: $isClientWindows"

        foreach ($windowsFeature in $windowsFeatures) {
            if ($isClientWindows) {
                xDismFeature $windowsFeature {
                    Name = $windowsFeature
                }
            } else {
                WindowsFeature $windowsFeature {
                    Name = $windowsFeature
                }
            }
        }
    }
}

