$Provider = 'PullServerModules'

function Initialize-Provider     { return $Provider }
function Get-PackageProviderName { return $Provider }

function Find-Package { 
    param(
        [string[]] $names,
        [string] $requiredVersion,
        [string] $minimumVersion,
        [string] $maximumVersion
    )

    foreach ($name in $names) {
        $module = OneGet\Find-Package -name $name -ProviderName PSModule
        $SWID = @{
	                version              = $module.version
	                versionScheme        = 'semver'
	                fastPackageReference = "$($module.name)|$($module.version)|$($module.source)"
	                name                 = $module.name
	                source               = $module.source
	                summary              = $module.summary
	                searchKey            = $module.name
	            }
        $SWID.fastPackageReference = $SWID | ConvertTo-Json -Compress
        New-SoftwareIdentity @SWID
    }
}

function Install-Package { 
    param(
        [string] $fastPackageReference
    )
    $pkg = $fastPackageReference | ConvertFrom-Json
    $mPath = Get-DSCConfiguration | ? CimClassName -eq MSFT_xDSCWebService | % ModulePath

    & 'C:\Program Files\OneGet\ProviderAssemblies\nuget-anycpu.exe' install $pkg.name -source $pkg.source -o $mPath -NonInteractive
    #OneGet\Install-Package -ProviderName NuGet -Name $pkg.Name -Source $pkg.Source -Destination $mPath

    $ModulePath = "$mPath\$($pkg.name).$($pkg.version)"
    $ArchiveName = "$mPath\$($pkg.name)_$($pkg.version).zip"
    if ((Test-Path $ModulePath) -AND !(Test-Path $ArchiveName)) {
        $NuPkg = Get-ChildItem $ModulePath | ? Extension -eq .nupkg | % FullName
        Remove-Item $NuPkg -Force

        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipfile]::CreateFromDirectory($ModulePath, $ArchiveName)

        New-DSCCheckSum -ConfigurationPath $ArchiveName -OutPath $mPath
        }
    Remove-Item $ModulePath -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-InstalledPackage {
    param(
    )
    
    $mPath = Get-DSCConfiguration | ? CimClassName -eq MSFT_xDSCWebService | % ModulePath
    
    $ModuleData = @()
    foreach ($zip in (Get-ChildItem $mPath | ? Extension -eq .zip)) {
        $ModuleData += @{name = $zip.name.split('_')[0]
                        version = $zip.name.split('_')[1].replace('.zip','')
                        path = $zip.Directory
                        }
        
        }

    foreach ($Module in $ModuleData) {

    $SWID = @{
	        version              = $module.version
	        versionScheme        = 'semver'
	        fastPackageReference = "$($module.name)|$($module.version)|$($module.path)"
	        name                 = $module.name
	        source               = $module.path
	        searchKey            = $module.name
	    }           
	            
	    New-SoftwareIdentity @SWID
    }
}
