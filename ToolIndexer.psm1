function Get-ToolMetadata {
    param ($ReadmePath)
    $content = Get-Content $ReadmePath -Raw

    $purpose = $null
    if ($content -match '<!--\s*Purpose:\s*(.*?)\s*-->') {
        $purpose = $matches[1]
    }

    $installCommand = $null
    if ($content -match '<!--\s*INSTALL_COMMAND:\s*(.*?)\s*-->') {
        $installCommand = $matches[1]
    }

    $runCommand = $null
    if ($content -match '<!--\s*RUN_COMMAND:\s*(.*?)\s*-->') {
        $runCommand = $matches[1]
    }

    $metadata = @{
        Purpose = $purpose
        InstallCommand = $installCommand
        RunCommand = $runCommand
    }
    return $metadata
}

function Get-GitHubRepositoryUrl {
    param ($GitFolder)
    $configPath = Join-Path $GitFolder 'config'
    if (Test-Path $configPath) {
        $config = Get-Content $configPath
        foreach ($line in $config) {
            if ($line -match 'url = https://github.com/(.*?)(\.git)?$') {
                return "https://github.com/$($matches[1])"
            }
        }
    }
    return $null
}

function Get-ExecutableFiles {
    param ($FolderPath)
    return Get-ChildItem -Path $FolderPath -Filter *.exe -File | Select-Object -ExpandProperty Name
}

function Format-ToolCard {
    param ($tool)
    $badges = @()
    if ($tool.GitHubUrl) { $badges += "<span>GitHub</span>" }
    if ($tool.Metadata.RunCommand) { $badges += "<span>PowerShell</span>" }
    if ($tool.ExeFiles.Count -gt 0) { $badges += "<span>EXE Available</span>" }

    return @"
    <div class="card">
        <h3>$($tool.Name)</h3>
        <div class="badges">$($badges -join ' ')</div>
        <p><span class="icon">🛠️</span><strong>Purpose:</strong> $($tool.Metadata.Purpose)</p>
        <p><span class="icon">🔗</span><strong>GitHub:</strong> $([string]::IsNullOrEmpty($tool.GitHubUrl) ? "Private Repo" : "<a href='$($tool.GitHubUrl)'>$($tool.GitHubUrl)</a>")</p>
        <p><span class="icon">📥</span><strong>Install Command:</strong></p>
        <pre>$($tool.Metadata.InstallCommand)</pre>
        <p><span class="icon">▶️</span><strong>Run Command:</strong></p>
        <pre>$($tool.Metadata.RunCommand)</pre>
        <p><span class="icon">💾</span><strong>EXE Files:</strong> $($tool.ExeFiles -join ', ')</p>
    </div>
"@
}

function Export-ToolIndexHtml {
    param ($ToolDataList, $OutputPath)
    $publicTools = $ToolDataList | Where-Object { $_.GitHubUrl }
    $privateTools = $ToolDataList | Where-Object { -not $_.GitHubUrl }

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Tool Index2</title>
    <style>
        body { font-family: Arial; background-color: #f9f9f9; }
        h1, h2 { color: #333; }
        .section { margin-bottom: 40px; }
        .card-grid { display: flex; flex-wrap: wrap; gap: 20px; }
        .card { flex: 1 1 calc(27% - 20px); box-sizing: border-box; border: 1px solid #ccc; padding: 15px; margin: 0; border-radius: 8px; box-shadow: 2px 2px 5px #aaa; background-color: #fff; height: 400px}
        .card h3 { margin-top: 0; }
        .card pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
        .badges span { display: inline-block; background-color: #0078D7; color: white; padding: 5px 10px; margin-right: 5px; border-radius: 5px; font-size: 0.9em; }
        .icon { font-size: 1.2em; margin-right: 5px; }
        #searchBox { width: 90%; padding: 10px; font-size: 1em; margin-bottom: 20px; border: 1px solid #ccc; border-radius: 5px; }
    </style>
    <script>
        function filterCards() {
            var input = document.getElementById('searchBox').value.toLowerCase();
            var cards = document.getElementsByClassName('card');
            for (var i = 0; i < cards.length; i++) {
                var cardText = cards[i].innerText.toLowerCase();
                cards[i].style.display = cardText.includes(input) ? '' : 'none';
            }
        }
    </script>
</head>
<body>
    <h1>Tool Index</h1>
    <input type="text" id="searchBox" onkeyup="filterCards()" placeholder="Search tools by name, purpose, command...">
"@

    $html += "<div class='section'><h2>Tools</h2><div class='card-grid'>"
    foreach ($tool in $publicTools) {
        $html += Format-ToolCard -tool $tool
    }

    foreach ($tool in $privateTools) {
        $html += Format-ToolCard -tool $tool
    }
    $html += "</div></div>"

    $html += "</body></html>"

# Save with UTF-8 BOM
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    $writer = New-Object System.IO.StreamWriter($OutputPath, $false, $utf8WithBom)
    $writer.Write($html)
    $writer.Close()
}

Export-ModuleMember -Function Get-ToolMetadata, Get-GitHubRepositoryUrl, Get-ExecutableFiles, Format-ToolCard, Export-ToolIndexHtml
