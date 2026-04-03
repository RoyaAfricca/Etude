$repo = "RoyaAfricca/Etude"
$token = "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" # Extracted from .git/config
$version = "1.2.1+010426" # From pubspec.yaml
$tagName = "v$version"
$apkPath = "e:\etude\build\app\outputs\flutter-apk\app-release.apk"

if (-not (Test-Path $apkPath)) {
    Write-Error "APK not found at $apkPath"
    exit 1
}

$headers = @{
    "Authorization" = "token $token"
    "Accept"        = "application/vnd.github.v3+json"
}

# 1. Create a Git Tag locally and push it
Write-Host "Creating and pushing tag $tagName..."
git tag $tagName
git push origin $tagName

# 2. Create the Release
Write-Host "Creating release $tagName on GitHub..."
$releaseBody = @{
    tag_name         = $tagName
    target_commitish = "main"
    name             = "Release $tagName"
    body             = "Automated release of APK for version $version"
    draft            = $false
    prerelease       = $false
} | ConvertTo-Json

$createReleaseUrl = "https://api.github.com/repos/$repo/releases"
try {
    $releaseResponse = Invoke-RestMethod -Uri $createReleaseUrl -Method Post -Headers $headers -Body $releaseBody
    $uploadUrl = $releaseResponse.upload_url.Replace("{?name,label}", "?name=application_etude_$version.apk")
    $releaseId = $releaseResponse.id
    Write-Host "Release created successfully. ID: $releaseId"
} catch {
    Write-Error "Failed to create release: $_"
    exit 1
}

# 3. Upload the APK
Write-Host "Uploading APK to release..."
$uploadHeaders = $headers.Clone()
$uploadHeaders["Content-Type"] = "application/vnd.android.package-archive"

try {
    $fileBytes = [System.IO.File]::ReadAllBytes($apkPath)
    $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -InFile $apkPath
    Write-Host "APK uploaded successfully!"
    Write-Host "Release URL: $($releaseResponse.html_url)"
} catch {
    Write-Error "Failed to upload APK: $_"
    exit 1
}
