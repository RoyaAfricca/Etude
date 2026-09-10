# Script de publication automatique pour l'Application Étude (APK & ZIP Windows)
# Ce script crée une release GitHub et y téléverse l'APK Android et le ZIP Windows.

$repo = "RoyaAfricca/Etude"
# Token lu depuis la variable d'environnement GITHUB_TOKEN (ne jamais mettre le token directement dans ce fichier)
$token = $env:GITHUB_TOKEN
if (-not $token) {
    $token = Read-Host "Entrez votre GitHub Personal Access Token"
}

# 1. Extraction de la version depuis pubspec.yaml
$pubspecPath = "e:\etude\pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Error "Le fichier pubspec.yaml est introuvable à l'adresse $pubspecPath."
    exit 1
}

$pubspec = Get-Content -Path $pubspecPath -Raw
$versionMatch = [regex]::Match($pubspec, 'version:\s*([0-9a-zA-Z.+_-]+)')
if ($versionMatch.Success) {
    $version = $versionMatch.Groups[1].Value.Trim()
} else {
    Write-Error "Impossible de lire la version depuis pubspec.yaml"
    exit 1
}

$cleanVersion = $version.Split('+')[0]
$tagName = "v$version"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  Publication Étude — Version $version ($tagName)" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 2. Localisation des fichiers compilés (APK et ZIP Windows)
$apkPath = "e:\etude\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "e:\etude\Adel\application_etude.apk"
}

# Recherche du ZIP Windows
$zipPath = "e:\etude\Adel\application_etude_v${cleanVersion}_windows.zip"
if (-not (Test-Path $zipPath)) {
    # Fallback: chercher n'importe quel ZIP windows dans Adel
    $found = Get-ChildItem "e:\etude\Adel" -Filter "*windows*.zip" | Select-Object -First 1
    if ($found) { $zipPath = $found.FullName }
}

# Validation des fichiers
$filesReady = $true
if (-not (Test-Path $apkPath)) {
    Write-Warning "[!] Fichier APK introuvable : $apkPath"
    $filesReady = $false
} else {
    Write-Host "[OK] APK trouvé à : $apkPath" -ForegroundColor Green
}

if (-not $zipPath -or -not (Test-Path $zipPath)) {
    Write-Warning "[!] Fichier ZIP Windows introuvable."
    $filesReady = $false
} else {
    Write-Host "[OK] ZIP Windows trouvé à : $zipPath" -ForegroundColor Green
}

if (-not $filesReady) {
    Write-Warning "`n[!] Certains fichiers sont manquants."
    $confirm = Read-Host "Voulez-vous quand même continuer avec les fichiers disponibles ? (O/N)"
    if ($confirm -ne "O" -and $confirm -ne "o") {
        Write-Host "Opération annulée."
        exit 1
    }
}

# 3. Préparation des requêtes API GitHub
$headers = @{
    "Authorization" = "token $token"
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "Etude-Release-Script"
}

# Création locale et push du Tag
Write-Host "`n[1/3] Création et envoi du tag Git $tagName..." -ForegroundColor Yellow
git -C "e:\etude" tag -d $tagName 2>$null
git -C "e:\etude" push origin ":refs/tags/$tagName" 2>$null
git -C "e:\etude" tag $tagName
git -C "e:\etude" push origin $tagName

# Création de la Release sur GitHub
Write-Host "`n[2/3] Création de la release $tagName sur GitHub..." -ForegroundColor Yellow
$releaseBody = @{
    tag_name         = $tagName
    target_commitish = "main"
    name             = "Version $cleanVersion"
    body             = "## Nouveautés de la version $cleanVersion`n`n* Matières Informatique 1, 2, 3 ajoutées.`n* Email et matière enseignée pour les professeurs.`n* Frais d'inscription modifiables par élève (100 DT par défaut).`n* Correction bouton Ajouter (professeurs/salles).`n`n*Téléchargez les installateurs ci-dessous pour mettre à jour votre application.*"
    draft            = $false
    prerelease       = $false
} | ConvertTo-Json

$createReleaseUrl = "https://api.github.com/repos/$repo/releases"
try {
    $releaseResponse = Invoke-RestMethod -Uri $createReleaseUrl -Method Post -Headers $headers -Body $releaseBody -ContentType "application/json"
    $uploadUrlTemplate = $releaseResponse.upload_url
    $releaseId = $releaseResponse.id
    Write-Host "[OK] Release créée avec succès ! ID: $releaseId" -ForegroundColor Green
} catch {
    Write-Error "Échec de la création de la release : $_"
    exit 1
}

# 4. Téléversement des Assets
Write-Host "`n[3/3] Téléversement des applications vers la release..." -ForegroundColor Yellow

function Upload-ReleaseAsset($filePath, $assetName, $contentType) {
    if (-not (Test-Path $filePath)) {
        Write-Warning "Impossible de téléverser $assetName : fichier source introuvable."
        return
    }
    Write-Host "Téléversement de $assetName ($([math]::Round((Get-Item $filePath).Length/1MB,1)) MB)..." -ForegroundColor Yellow
    $uploadUrl = $uploadUrlTemplate.Replace("{?name,label}", "?name=$assetName")
    $uploadHeaders = $headers.Clone()
    $uploadHeaders["Content-Type"] = $contentType
    try {
        $uploadResponse = Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $uploadHeaders -InFile $filePath -ContentType $contentType
        Write-Host "[OK] $assetName téléversé avec succès !" -ForegroundColor Green
    } catch {
        Write-Error "Échec du téléversement de $assetName : $_"
    }
}

# Téléversement de l'APK
if (Test-Path $apkPath) {
    Upload-ReleaseAsset -filePath $apkPath -assetName "application_etude_v${cleanVersion}.apk" -contentType "application/vnd.android.package-archive"
}

# Téléversement du ZIP Windows
if ($zipPath -and (Test-Path $zipPath)) {
    Upload-ReleaseAsset -filePath $zipPath -assetName "application_etude_v${cleanVersion}_windows.zip" -contentType "application/zip"
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "  PUBLICATION TERMINÉE !" -ForegroundColor Green
Write-Host "  Lien de la release : $($releaseResponse.html_url)" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
