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

function Get-TargetResource {
    param(	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $DestinationPath,

        [parameter(Mandatory = $true)]
    	[string]
        $SourcePath, 

        [parameter(Mandatory = $false)]
    	[string]
        $Path7zip
    )

    $result = @{ 
        DestinationPath = $DestinationPath;
        Exists = (Test-Path -LiteralPath $DestinationPath)
    }
    return $result
}

function Test-TargetResource {
    param(	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $DestinationPath,

        [parameter(Mandatory = $true)]
    	[string]
        $SourcePath, 

        [parameter(Mandatory = $false)]
    	[string]
        $Path7zip
    )

    $currentSettings = Get-TargetResource @PSBoundParameters
    return $currentSettings.Exists
}


function Set-TargetResource {
    param(	
        [parameter(Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [string] 
        $DestinationPath,

        [parameter(Mandatory = $true)]
    	[string]
        $SourcePath, 

        [parameter(Mandatory = $false)]
    	[string]
        $Path7zip
    )

    if (!$Path7zip) {
        $Path7zip = Join-Path -Path $env:ProgramFiles -ChildPath '7-Zip'
    }
    $Path7zip = Join-Path -Path $Path7zip -ChildPath '7z.exe'
    if (!(Test-Path -LiteralPath $Path7zip)) {
        throw "7zip does not exist at '$Path7zip'"
    }

    $args = " x `"$SourcePath`" -o`"$DestinationPath`" -y"
    Write-Verbose -Message "Running $Path7zip $args"
    & "$Path7zip" x "`"$SourcePath`"" "-o`"$DestinationPath`"" "-y"
    if ($lastexitcode) {
        throw "7-Zip failed with exit code $lastexitcode"
    }
}

Export-ModuleMember -Function *-TargetResource
