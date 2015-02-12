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

function Update-SSASXmlaRoleMembers { 
    <#
    .SYNOPSIS
    Replaces roles in the .xmla file with the ones specified in $RoleName and $RoleMembers parameters.

    .PARAMETER GeneratedXmlaFilePath
    Output file that will be created by this cmdlet.

    .PARAMETER DeploymentXmlaFilePath
    Input file that will be converted by this cmdlet.

    .PARAMETER RoleName
    Name of the role which will be added to the cube.

    .PARAMETER RoleMembers
    List of role members which will be added to the role specified in RoleName.

    .PARAMETER Force
    If $true then $DeploymentXmlaFilePath will be overwritten

    .EXAMPLE
    Update-SSASXmlaRoleMembers -GeneratedXmlaFilePath $generatedXmlaFilePath -DeploymentXmlaFilePath $deploymentXmlaFilePath -RoleName $RoleName -RoleMembers $RoleMembers

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $GeneratedXmlaFilePath,

        [Parameter(Mandatory=$true)]
        [string] 
        $DeploymentXmlaFilePath,

        [Parameter(Mandatory=$true)]
        [string] 
        $RoleName,

        [Parameter(Mandatory=$true)]
        [string[]] 
        $RoleMembers,

        [Switch]
        $Force
    )

    $Members = $RoleMembers | Foreach-Object { "<Member><Name>$_</Name></Member>" }

    $xmlaXdtTranformation = @"
<Batch Transaction="false" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine" xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
  <Alter AllowCreate="true" ObjectExpansion="ExpandFull">
    <ObjectDefinition>
      <Database xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ddl2="http://schemas.microsoft.com/analysisservices/2003/engine/2" xmlns:ddl2_2="http://schemas.microsoft.com/analysisservices/2003/engine/2/2" xmlns:ddl100_100="http://schemas.microsoft.com/analysisservices/2008/engine/100/100" xmlns:ddl200="http://schemas.microsoft.com/analysisservices/2010/engine/200" xmlns:ddl200_200="http://schemas.microsoft.com/analysisservices/2010/engine/200/200"> 
        <Roles>
          <Role xdt:Transform="Replace">
              <ID>Role</ID>
              <Name>$RoleName</Name>
              <Description></Description>
              <Members>
                $Members
              </Members>
            </Role>
        </Roles>
      </Database>
    </ObjectDefinition>
  </Alter>
</Batch>
"@

    [void](Convert-XmlUsingXdt -Path $GeneratedXmlaFilePath -XdtXml $xmlaXdtTranformation -Destination $DeploymentXmlaFilePath -Force:$Force)
}