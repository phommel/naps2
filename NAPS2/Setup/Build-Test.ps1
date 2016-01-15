﻿param([Parameter(Position=0, Mandatory=$false)] [String] $Name, [Parameter(Mandatory=$false)] [switch] $d)

. .\naps2.ps1

# Rebuild NAPS2

$Version = Get-NAPS2-Version
$PublishDir = "..\publish\$Version\"
if (-not (Test-Path $PublishDir)) {
    mkdir $PublishDir
}
$msbuild = Get-MSBuild-Path
Get-Process | where { $_.ProcessName -eq "NAPS2.vshost" } | kill
"Building MSI"
& $msbuild ..\..\NAPS2.sln /v:q /p:Configuration=InstallerMSI
"Building ZIP"
if ($d) {
    & $msbuild ..\..\NAPS2.sln /v:q /p:Configuration=StandaloneZIP /t:Rebuild /p:DefineConstants=DEBUG%3BSTANDALONE%3BSTANDALONE_ZIP
} else {
    & $msbuild ..\..\NAPS2.sln /v:q /p:Configuration=StandaloneZIP /t:Rebuild
}

# Standalone ZIP/7Z
$StandaloneDir = $PublishDir + "naps2-$Version-portable\"
$AppDir = $StandaloneDir + "App\"
$DataDir = $StandaloneDir + "Data\"

function Publish-NAPS2-Standalone {
    param([Parameter(Position=0)] [String] $Configuration,
          [Parameter(Position=1)] [String] $ArchiveFile)
    if (Test-Path $StandaloneDir) {
        rmdir $StandaloneDir -Recurse
    }
    mkdir $StandaloneDir
    mkdir $AppDir
    mkdir $DataDir
    $BinDir = "..\bin\$Configuration\"
    $CmdBinDir = "..\..\NAPS2.Console\bin\$Configuration\"
    $PortableBinDir = "..\..\NAPS2.Portable\bin\Release\"
    cp ($PortableBinDir + "NAPS2.Portable.exe") $StandaloneDir
    foreach ($LanguageCode in Get-NAPS2-Languages) {
        $LangDir = $AppDir + "$LanguageCode\"
        mkdir $LangDir
        cp ($BinDir + "$LanguageCode\NAPS2.Core.resources.dll") $LangDir
    }
    foreach ($Dir in ($BinDir, $CmdBinDir)) {
        foreach ($File in (Get-ChildItem $Dir | where { $_.Name -match '(?<!vshost)\.(exe|dll)$' })) {
            cp $File.FullName $AppDir
        }
    }
    foreach ($File in ("..\..\NAPS2.Core\Resources\scanner-app.ico", "..\appsettings.xml", "lib\wiaaut.dll", "license.txt")) {
        cp $File $AppDir
    }
    if (Test-Path $ArchiveFile) {
        rm $ArchiveFile
    }
    & (Get-7z-Path) a $ArchiveFile $($StandaloneDir + "*")
    rmdir -Recurse $StandaloneDir
}

Publish-NAPS2-Standalone "StandaloneZIP" ($PublishDir + "naps2-$Version-test_$Name-portable.zip")

""
"Saved to " + ($PublishDir + "naps2-$Version-test_$Name-portable.zip")
""
