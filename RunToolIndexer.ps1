
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module -Name (Join-Path $scriptDir 'ToolIndexer.psm1')

$basePath = "E:\projects\github"
$outputHtml = "S:\Other\Current\Html\ToolIndex.html"

# You shoud not need to change the following code unless you want to customize the output HTML format.
$toolDataList = @()
Get-ChildItem -Path $basePath -Directory | ForEach-Object {
    $folder = $_.FullName
    $readmePath = Join-Path $folder "README.md"
    $gitFolder = Join-Path $folder ".git"

    if (Test-Path $readmePath) {
        $metadata = Get-ToolMetadata -ReadmePath $readmePath
        $githubUrl = Get-GitHubRepositoryUrl -GitFolder $gitFolder
        $exeFiles = Get-ExecutableFiles -FolderPath $folder

        $toolDataList += [PSCustomObject]@{
            Name = $_.Name
            Metadata = $metadata
            GitHubUrl = $githubUrl
            ExeFiles = $exeFiles
        }
    }
}

Export-ToolIndexHtml -ToolDataList $toolDataList -OutputPath $outputHtml
Write-Host "HTML generated at $outputHtml"
