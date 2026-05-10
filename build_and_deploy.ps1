$ErrorActionPreference = "Stop"

Write-Host "1/4 Building Windows Release..."
flutter build windows --release

Write-Host "2/4 Building Android APK..."
flutter build apk --release

Write-Host "3/4 Building Web Release..."
flutter build web --release

Write-Host "4/4 Copying artifacts to shared drive..."
$targetDir = "C:\Data\Rajesh\Dev\Executables\KaraokeHost"

if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Force -Path $targetDir
}

# Copy Windows
Write-Host "Copying Windows files..."
Copy-Item -Path "build\windows\x64\runner\Release\*" -Destination $targetDir -Recurse -Force

# Copy APK
Write-Host "Copying Android APK..."
Copy-Item -Path "build\app\outputs\flutter-apk\app-release.apk" -Destination $targetDir -Force

# Copy Web
Write-Host "Copying Web files..."
$webTargetDir = Join-Path $targetDir "web"
if (Test-Path $webTargetDir) {
    Remove-Item -Path $webTargetDir -Recurse -Force
}
Copy-Item -Path "build\web" -Destination $webTargetDir -Recurse -Force

Write-Host "Deployment completed successfully!"
