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

function Deploy-SSRSReportsByVisualStudio {
    <#
    .SYNOPSIS
        Deploys a SSRS project using Visual Studio.

    .DESCRIPTION
    	Deploys a SSRS project using rptproj file using given project configuration (Configuration parameter set) or using given project settings (Target parameter set).
        Compatible with SSRS versions 2008R2, 2012 and 2014.

	.PARAMETER PackageName
		Name of the SSRS package.

	.PARAMETER ProjectName
		Name of .rptproj project.

    .PARAMETER TargetServerURL
        SSRS server url.

    .PARAMETER TargetFolder
        SSRS target report folder name.

    .PARAMETER TargetDataSourceFolder
        SSRS target data source folder name.

    .PARAMETER DataSources
        Hashtable of data sources.

    .PARAMETER ProjectConfigurationName
    	Name of the project configuration to be used while deploying.

    .PARAMETER Credential
        Credentials

    .EXAMPLE
        Deploy-SSRSReportsByVisualStudio -PackageName 'SSRSReports' -Configuration 'UAT'

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $PackageName,

        [Parameter(Mandatory=$true)]
        [string] 
        $ProjectName,

        [Parameter(Mandatory=$true)]
        [string] 
        $TargetServerURL,

        [Parameter(Mandatory=$true)]
        [string] 
        $TargetFolder,

        [Parameter(Mandatory=$true)]
        [string] 
        $TargetDataSourceFolder,
        
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $DataSources,

        [Parameter(Mandatory=$false)]
        [string] 
        $ProjectConfigurationName = 'Release',

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential] 
        $Credential
    )

    $DevEnvPath = "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE\devenv.com"

    if (!(Test-Path -Path $DevEnvPath)) {
        Write-Log -Critical "BIDS for SQL Server 2008 R2 has not been found at '$DevEnvPath'."
    }        

    $configPaths = Get-ConfigurationPaths
    $PackagePath = Join-Path -Path $configPaths.PackagesPath -ChildPath $PackageName

    if ($ProjectName) {
        $RSProject = Join-Path -Path $PackagePath -ChildPath "$ProjectName.rptproj"
    
        if (!(Test-Path -Path $RSProject)) {
            Write-Log -Critical "Project $RSProject doesn't exist"
        }
    } else{
        $projectFiles = ,(Get-ChildItem -Path $PackagePath | Where-Object {$_.extension -eq ".rptproj"})
        if ($projectFiles.Length > 1) {
            Write-Log -Critical "Multiple projects found in $PackagePath but project name was not specified."
        }
        $RSProject = $projectFiles[0].FullName
    }


    Write-Log -Info "Setting configuration.."
    Set-SSRSProjectConfiguration -ProjectFilePath $RSProject -DeploymentFilePath $RSProject -ConfigurationName $ProjectConfigurationName -TargetFolder $TargetFolder -TargetServerURL $TargetServerURL -TargetDataSourceFolder $TargetDataSourceFolder
    
    $DataSources.Keys | Where-Object {

        $DataSourcePath = Join-Path -Path $PackagePath -ChildPath $_

        if (!(Test-Path -Path $DataSourcePath)) {
            Write-Log -Critical "DataSource $DataSourcePath doesn't exist"
        }

        $ds = $DataSources.Item($_)

        Write-Log -Info "Setting datasource.."
        Set-SSRSDataSource -FilePath $DataSourcePath -ConnectionString $ds.Item('ConnectionString') -IntegratedSecurity $ds.Item('IntegratedSecurity')
    }

    Write-Log -Info "Deploying RS project..."

    $startDevenvParams = @{ Command=$DevEnvPath;
             ArgumentList="""$RSProject"" /deploy $ProjectConfigurationName";
             Credential=$Credential}

    Start-ExternalProcess @startDevenvParams

    Write-Log -Info "RS project was deployed successfully." 
}