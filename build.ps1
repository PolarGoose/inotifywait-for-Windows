Function Info($msg) {
  Write-Host -ForegroundColor DarkGreen "`nINFO: $msg`n"
}

Function Error($msg) {
  Write-Host `n`n
  Write-Error $msg
  exit 1
}

Function CheckReturnCodeOfPreviousCommand($msg) {
  if(-Not $?) {
    Error "${msg}. Error code: $LastExitCode"
  }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$root = Resolve-Path "$PSScriptRoot"
$buildDir = "$root/build"
$gitCommand = Get-Command -Name git

Info "Remove '$buildDir' folder if it exists"
Remove-Item $buildDir -Force -Recurse -ErrorAction SilentlyContinue
New-Item $buildDir -Force -ItemType "directory" > $null

Info "Clone inotify-win git repository"
& $gitCommand clone --depth 1 https://github.com/thekid/inotify-win.git $buildDir/inotify-win
CheckReturnCodeOfPreviousCommand "git failed"

Info "Copy the csproj file to the inotify-win directory"
Copy-Item -Path $root/inotifywait.csproj -Destination $buildDir/inotify-win/inotifywait.csproj

Info "Build the inotify-win executable"
dotnet build `
  --nologo `
  --configuration Release `
  /property:Platform="AnyCPU" `
  /property:DebugType=None `
  $buildDir/inotify-win/inotifywait.csproj
CheckReturnCodeOfPreviousCommand "build failed"

Info "Copy executable to the publish directory and archive it"
New-Item $buildDir/publish -Force -ItemType "directory" > $null
Copy-Item -Path $buildDir/inotify-win/bin/Release/net472/inotifywait.exe -Destination $buildDir/publish
Compress-Archive -Path $buildDir/publish/inotifywait.exe -DestinationPath $buildDir/publish/inotifywait.zip
