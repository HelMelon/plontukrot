# Bump pubspec version, sync build number from git, update CHANGELOG, create annotated tag.
# Usage:
#   .\scripts\release.ps1 -Bump minor
#   .\scripts\release.ps1 -Bump auto
#   .\scripts\release.ps1 -Baseline   # one-time after adopting ADR-045 (no bump)

param(
    [ValidateSet('patch', 'minor', 'major', 'auto', 'none')]
    [string]$Bump = 'auto',

    [switch]$Baseline,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

function Get-LastTag {
    $tag = git tag --sort=-v:refname 2>$null | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($tag)) { return $null }
    return $tag.Trim()
}

function Get-CommitSubjectsSince([string]$Ref) {
    if ([string]::IsNullOrWhiteSpace($Ref)) {
        return @()
    }
    return @(git log "$Ref..HEAD" --format='%s')
}

function Get-SuggestedBump([string[]]$Subjects) {
    $hasBreaking = $false
    $hasFeat = $false
    $hasFix = $false

    foreach ($subject in $Subjects) {
        if ($subject -match 'BREAKING CHANGE|^(\w+)!:') { $hasBreaking = $true }
        elseif ($subject -match '^feat(\(|:|!)') { $hasFeat = $true }
        elseif ($subject -match '^fix(\(|:|!)') { $hasFix = $true }
    }

    if ($hasBreaking) { return 'major' }
    if ($hasFeat) { return 'minor' }
    if ($hasFix) { return 'patch' }
    return 'none'
}

function Require-CleanTree {
    $status = git status --porcelain
    if ($status) {
        throw "Working tree is not clean. Commit or stash changes before releasing.`n$status"
    }
}

$buildNumber = [int](git rev-list --count HEAD)

if ($Baseline) {
    $current = (dart run cider version).Trim()
    $tagName = "v$($current.Split('+')[0])"
    Write-Host "Baseline tag $tagName at build +$buildNumber (no version bump)." -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host '[dry-run] would run: git tag -a' $tagName
        exit 0
    }

    Require-CleanTree
    if (Get-LastTag) {
        Write-Host "Tag already exists: $(Get-LastTag). Skip -Baseline or delete the tag manually." -ForegroundColor Yellow
        exit 1
    }

    git tag -a $tagName -m "Baseline release $tagName (+$buildNumber)"
    Write-Host "Created tag $tagName" -ForegroundColor Green
    exit 0
}

if (-not $Baseline -and -not (Get-LastTag)) {
    Write-Host 'No git tag yet. Commit versioning files, then run: .\scripts\release.ps1 -Baseline' -ForegroundColor Yellow
    exit 1
}

$lastTag = Get-LastTag
$subjects = Get-CommitSubjectsSince $lastTag

if ($Bump -eq 'auto') {
    $Bump = Get-SuggestedBump $subjects
    Write-Host "Auto-detected bump: $Bump (since $(if ($lastTag) { $lastTag } else { 'no tag' }))" -ForegroundColor Cyan
}

if ($Bump -eq 'none') {
    Write-Host 'Nothing to release: no feat/fix/breaking commits since last tag.' -ForegroundColor Yellow
    Write-Host "To upload a build only: dart run cider bump build --build=$buildNumber"
    exit 0
}

$unreleased = Select-String -Path 'CHANGELOG.md' -Pattern '^## Unreleased' -Quiet
if (-not $unreleased) {
    throw 'CHANGELOG.md must contain a ## Unreleased section (Keep a Changelog + cider).'
}

Write-Host "Releasing with bump=$Bump, build=$buildNumber" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[dry-run] dart run cider bump $Bump --build=$buildNumber"
    Write-Host '[dry-run] dart run cider release'
    Write-Host "[dry-run] git tag -a v<new-version>"
    exit 0
}

Require-CleanTree

dart pub get | Out-Null
dart run cider bump $Bump --build=$buildNumber
dart run cider release

$newVersion = (dart run cider version).Trim()
$tagName = "v$($newVersion.Split('+')[0])"

git add pubspec.yaml CHANGELOG.md
git commit -m "chore(release): $tagName (+$buildNumber)"
git tag -a $tagName -m "Release $tagName (+$buildNumber)"

Write-Host "Released $newVersion - tag $tagName" -ForegroundColor Green
Write-Host 'Push with: git push; git push --tags'
