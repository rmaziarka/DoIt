#region Initialize

function Initialize
{
    # Cert Store Location
    $script:certStoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine

    # Cert Path
    $script:certStoreLocationPath = "Cert:\{0}\{1}"

    # Enum for Ensure
    try
    {
    Add-Type -TypeDefinition @"
        public enum EnsureType
        {
            Present,
            Absent
        }
"@
    }
    catch
    {
    }
}

Initialize

#endregion

#region Message Definition

$debugMessage = DATA {
    ConvertFrom-StringData -StringData "
        ImportPfx = Importing certificate PFX '{0}' to CertStoreLocation '{1}', CertStore '{2}'.
        RemovePfx = Removing pfx from Cert path '{0}'.
    "
}

$verboseMessage = DATA {
    ConvertFrom-StringData -StringData "
    "
}

$exceptionMessage = DATA {
    ConvertFrom-StringData -StringData "
        CertificateFileNotFoundException = Certificate not found in '{0}'. Make sure you have been already place it.
    "
}

#endregion


#region *-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    [OutputType([Void])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]$ThumbPrint,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]$Ensure,

        [parameter(Mandatory = $false)]
        [System.String]$PfxFilePath,

        [parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.StoreName]$CertStoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    # Ensure = Absent
    if ($Ensure -eq [EnsureType]::Absent.ToString())
    {
        $certPath = GetCertPath -CertStoreName $CertStoreName
        $pfx = Get-ChildItem -Path $certPath | where ThumbPrint -eq $ThumbPrint
        if ($pfx -ne $null)
        {
            Write-Debug ($debugMessage.RemovePfx -f $pfx.PSPath)
            Remove-Item -Path $pfx.PSPath -Force > $null
        }
        return
    }

    # Ensure = Present
    if (-not (Test-Path $PfxFilePath))
    {
        throw New-Object System.IO.FileNotFoundException ($exceptionMessage.CertificateFileNotFoundException -f $PfxFilePath)
    }

    # pfx identification
    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    $pfxToImport = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $PfxFilePath, $Credential.GetNetworkCredential().Password, $flags
    $pfxStore = New-Object System.Security.Cryptography.X509Certificates.X509Store $CertStoreName, $script:certStoreLocation

    try
    {
        # Import pfx
        Write-Debug ($debugMessage.ImportPfx -f $PfxFilePath, $script:certStoreLocation, $CertStoreName)
        $pfxStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed)
        $pfxStore.Add($pfxToImport) > $null
    }
    finally
    {
        $PFXStore.Close()
    }    
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]$ThumbPrint,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]$Ensure,

        [parameter(Mandatory = $false)]
        [System.String]$PfxFilePath,

        [parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.StoreName]$CertStoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    $certPath = GetCertPath -CertStoreName $CertStoreName
    $pfx = Get-ChildItem -Path $certPath | where ThumbPrint -eq $ThumbPrint

    $ensureResult = if ($pfx -eq $null)
    {
        [EnsureType]::Absent
    }
    else
    {
        [EnsureType]::Present
    }

    $returnValue = @{
        ThumbPrint = $ThumbPrint
        Ensure = $ensureResult
        PfxFilePath = $PfxFilePath
        CertStoreLocation = $script:certStoreLocation
        CertStoreName = $CertStoreName
        Credential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$Credential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
    }
    return $returnValue
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]$ThumbPrint,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]$Ensure,

        [parameter(Mandatory = $false)]
        [System.String]$PfxFilePath,

        [parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.StoreName]$CertStoreName = [System.Security.Cryptography.X509Certificates.StoreName]::My,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    $result = Get-TargetResource -ThumbPrint $ThumbPrint -Ensure $Ensure -CertStoreName $CertStoreName
    return $result.Ensure -eq $Ensure
}

#endregion

#region Cert Helper

function GetCertPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.StoreName]$CertStoreName
    )

    return $script:certStoreLocationPath -f $script:certStoreLocation, $CertStoreName.ToString()
}

#endregion

Export-ModuleMember -Function *-TargetResource
