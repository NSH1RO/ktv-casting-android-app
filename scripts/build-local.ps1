[CmdletBinding()]
param(
    [ValidateSet('arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64')]
    [string[]]$Abis = @('arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'),
    [string]$Version = '1.2.0-dev.direct.1',
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$SdkRoot = $env:ANDROID_HOME
)

$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$devRoot = Join-Path (Split-Path $appRoot -Parent) 'android-dev'
if (-not $JavaHome) {
    $JavaHome = (Get-ChildItem (Join-Path $devRoot 'jdk') -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'bin/java.exe') } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
if (-not $SdkRoot) { $SdkRoot = Join-Path $devRoot 'sdk' }
if (-not $JavaHome -or -not (Test-Path (Join-Path $JavaHome 'bin/java.exe'))) {
    throw 'JDK not found. Pass -JavaHome or set JAVA_HOME.'
}
if (-not (Test-Path (Join-Path $SdkRoot 'platforms/android-36/android.jar'))) {
    throw 'Android SDK 36 not found. Pass -SdkRoot or set ANDROID_HOME.'
}
foreach ($abi in $Abis) {
    $library = Join-Path $appRoot "app/src/main/jniLibs/$abi/libktv_casting_lib.so"
    if (-not (Test-Path $library)) {
        throw "Missing $library. Download the native library from this fork's Build Debug APK workflow first."
    }
}
$env:JAVA_HOME = $JavaHome
$env:ANDROID_HOME = $SdkRoot
$env:ANDROID_USER_HOME = Join-Path $devRoot 'android-user'
$env:GRADLE_USER_HOME = Join-Path $devRoot 'gradle-cache'
$env:Path = "$(Join-Path $JavaHome 'bin');$(Join-Path $SdkRoot 'platform-tools');$env:Path"
$sdkProperty = 'sdk.dir=' + ($SdkRoot -replace '\\', '/')
[System.IO.File]::WriteAllText((Join-Path $appRoot 'local.properties'), $sdkProperty)

Push-Location $appRoot
try {
    & ./gradlew.bat :app:testDebugUnitTest :app:assembleDebug "-Ptarget_abis=$($Abis -join ',')" "-Papp_version_name=$Version" --console=plain
    if ($LASTEXITCODE -ne 0) { throw "Gradle failed with exit code $LASTEXITCODE" }
    $metadataPath = Join-Path $appRoot 'app/build/outputs/apk/debug/output-metadata.json'
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $outputDir = Join-Path $appRoot 'apks'
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach ($element in $metadata.elements) {
        $abiFilter = $element.filters | Where-Object { $_.filterType -eq 'ABI' } | Select-Object -First 1
        $abiLabel = if ($abiFilter) { $abiFilter.value } else { 'universal' }
        $source = Join-Path (Split-Path $metadataPath -Parent) $element.outputFile
        $archive = [System.IO.Compression.ZipFile]::OpenRead($source)
        try {
            $expectedAbis = if ($abiLabel -eq 'universal') { $Abis } else { @($abiLabel) }
            foreach ($abi in $expectedAbis) {
                $entry = $archive.GetEntry("lib/$abi/libktv_casting_lib.so")
                if (-not $entry -or $entry.Length -eq 0) { throw "Native library missing from APK: $abi" }
            }
        } finally { $archive.Dispose() }
        $destination = Join-Path $outputDir "KTV-Casting-$Version-$abiLabel-debug.apk"
        Copy-Item -LiteralPath $source -Destination $destination -Force
        Write-Output $destination
    }
} finally { Pop-Location }
