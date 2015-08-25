function Upload-Directories {
    param ($Tokens, $ConnectionParams)

    if (!$Tokens.Directories) {
        return
    }

    $srcList = @()
    $dstList = @()
    $projectRootPath = (Get-ConfigurationPaths).ProjectRootPath

    foreach ($dirInfo in $Tokens.Directories.GetEnumerator()) {
        if ([System.IO.Path]::IsPathRooted($dirInfo.Key)) { 
            $srcList += $dirInfo.Key
        } else {
            $srcList += (Join-Path -Path $projectRootPath -ChildPath $dirInfo.Key)
        }
        $dstList += $dirInfo.Value
    }
    
    $params = @{
        Path = $srcList 
        ConnectionParams = $ConnectionParams
        Destination = $dstList
        ClearDestination = $true
    }

    Copy-FilesToRemoteServer @params
}
