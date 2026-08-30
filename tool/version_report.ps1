# Prints a semver suggestion from git history and Conventional Commits.
# Does not modify files. Run from repo root: .\tool\version_report.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Get-LastTag {
    $tag = git tag --sort=-v:refname 2>$null | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($tag)) { return $null }
    return $tag.Trim()
}

function Get-CommitSubjectsSince([string]$Ref) {
    if ([string]::IsNullOrWhiteSpace($Ref)) {
        return git log --format='%s'
    }
    return git log "$Ref..HEAD" --format='%s'
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

$lastTag = Get-LastTag
$totalCommits = [int](git rev-list --count HEAD)
$subjectsSinceTag = @(Get-CommitSubjectsSince $lastTag)
$sinceTagLabel = if ($lastTag) { "since $lastTag" } else { 'full history (no tags yet)' }

$featCount = ($subjectsSinceTag | Where-Object { $_ -match '^feat(\(|:|!)' }).Count
$fixCount = ($subjectsSinceTag | Where-Object { $_ -match '^fix(\(|:|!)' }).Count
$suggestedBump = Get-SuggestedBump $subjectsSinceTag

$pubspecVersion = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()

Write-Host '=== Plontukrot version report ===' -ForegroundColor Cyan
Write-Host "pubspec.yaml version : $pubspecVersion"
Write-Host "git commits (HEAD)   : $totalCommits"
Write-Host "last git tag         : $(if ($lastTag) { $lastTag } else { '(none)' })"
Write-Host "commits analyzed     : $sinceTagLabel"
Write-Host "feat / fix counts    : $featCount / $fixCount"
Write-Host "suggested next bump  : $suggestedBump"
Write-Host ''

if (-not $lastTag) {
    Write-Host 'Retroactive baseline (see ADR-045):' -ForegroundColor Yellow
    Write-Host '  1.0.0     - Jun 8 initial (pubspec stayed 1.0.0+1 in git)'
    Write-Host '  1.1-1.5   - Jul-Aug Firebase era (repotting..reminders)'
    Write-Host '  2.0.0     - Aug 20 REST migration'
    Write-Host '  2.1-2.4   - Aug 20-28 manipulations, hybrid, filters, auth'
    Write-Host '  2.5.0     - genus care guide (current baseline)'
    Write-Host '  note      : count full git log, not only feat: commits'
    Write-Host "  build number         : $totalCommits (total commits)"
    Write-Host ''
}

if ($suggestedBump -eq 'none') {
    Write-Host 'No feat/fix/breaking commits since last tag; bump build only if uploading to stores.' -ForegroundColor DarkYellow
}
else {
    Write-Host "Next release command : .\scripts\release.ps1 -Bump $suggestedBump" -ForegroundColor Green
}
