param(
    [Parameter(Mandatory = $true)][string]$HtmlPath,
    [Parameter(Mandatory = $true)][string]$DocxPath
)

function Get-InnerTextWithBold {
    param([string]$Html)
    $parts = @()
    $pos = 0
    while ($pos -lt $Html.Length) {
        $strongStart = $Html.IndexOf('<strong>', $pos)
        if ($strongStart -lt 0) {
            $text = $Html.Substring($pos)
            if ($text) { $parts += [pscustomobject]@{ Text = $text; Bold = $false } }
            break
        }
        if ($strongStart -gt $pos) {
            $parts += [pscustomobject]@{ Text = $Html.Substring($pos, $strongStart - $pos); Bold = $false }
        }
        $contentStart = $strongStart + 8
        $contentEnd = $Html.IndexOf('</strong>', $contentStart)
        if ($contentEnd -lt 0) { break }
        $parts += [pscustomobject]@{ Text = $Html.Substring($contentStart, $contentEnd - $contentStart); Bold = $true }
        $pos = $contentEnd + 9
    }
    return $parts
}

function Write-RichParagraph {
    param(
        $Selection,
        [string]$InnerHtml,
        [int]$FontSize = 12,
        [switch]$BoldAll,
        [switch]$Gray,
        [switch]$Center,
        [switch]$Footer
    )

    if ($BoldAll) { $Selection.Font.Bold = $true }
    if ($Gray -or $Footer) { $Selection.Font.Color = 8421504 }
    if ($Footer) { $Selection.Font.Size = 10; $Selection.ParagraphFormat.Alignment = 1 }
    else { $Selection.Font.Size = $FontSize; $Selection.ParagraphFormat.Alignment = 3 }

    $Selection.Font.NameFarEast = '宋体'
    $Selection.Font.Name = 'Times New Roman'

    if ($BoldAll) {
        $Selection.TypeText(($InnerHtml -replace '<[^>]+>', ''))
    }
    else {
        foreach ($part in (Get-InnerTextWithBold $InnerHtml)) {
            $Selection.Font.Bold = [int][bool]$part.Bold
            $Selection.TypeText($part.Text)
        }
        $Selection.Font.Bold = $false
    }

    $Selection.TypeParagraph()
    $Selection.Font.Color = 0
    $Selection.Font.Bold = $false
    $Selection.ParagraphFormat.Alignment = 0
}

function Write-ImageBlock {
    param($Selection, $Word, [string]$ImagePath, [string]$Caption)

    if (-not (Test-Path -LiteralPath $ImagePath)) {
        throw "Image not found: $ImagePath"
    }

    $Selection.ParagraphFormat.Alignment = 1
    $shape = $Selection.InlineShapes.AddPicture($ImagePath)
    $shape.LockAspectRatio = $true
    $shape.Width = $Word.CentimetersToPoints(14)
    $Selection.TypeParagraph()

    if ($Caption) {
        $Selection.Font.Size = 10
        $Selection.Font.Color = 8421504
        $Selection.ParagraphFormat.Alignment = 1
        $Selection.TypeText($Caption)
        $Selection.TypeParagraph()
    }

    $Selection.Font.Color = 0
    $Selection.ParagraphFormat.Alignment = 0
}

function Get-NextBlock {
    param([string]$Text, [int]$Start)

    $tags = @('h1', 'blockquote', 'figure', 'h2')
    $bestIndex = -1
    $bestTag = $null

    foreach ($tag in $tags) {
        $idx = $Text.IndexOf("<$tag", $Start)
        if ($idx -ge 0 -and ($bestIndex -lt 0 -or $idx -lt $bestIndex)) {
            $bestIndex = $idx
            $bestTag = $tag
        }
    }

    $pMatch = [regex]::Match($Text.Substring($Start), '<p(?:\s+class="([^"]*)")?>')
    if ($pMatch.Success) {
        $pIndex = $Start + $pMatch.Index
        if ($bestIndex -lt 0 -or $pIndex -lt $bestIndex) {
            $bestIndex = $pIndex
            $bestTag = 'p'
            $script:pClass = $pMatch.Groups[1].Value
        }
    }

    if ($bestIndex -lt 0) { return $null }

    if ($bestTag -eq 'p') {
        $close = $Text.IndexOf('</p>', $bestIndex)
        if ($close -lt 0) { return $null }
        $openEnd = $Text.IndexOf('>', $bestIndex) + 1
        return [pscustomobject]@{
            Tag = 'p'
            Class = $script:pClass
            Inner = $Text.Substring($openEnd, $close - $openEnd)
            Next = $close + 4
        }
    }

    $closeTag = "</$bestTag>"
    $close = $Text.IndexOf($closeTag, $bestIndex)
    if ($close -lt 0) { return $null }
    $openEnd = $Text.IndexOf('>', $bestIndex) + 1
    return [pscustomobject]@{
        Tag = $bestTag
        Class = ''
        Inner = $Text.Substring($openEnd, $close - $openEnd)
        Next = $close + $closeTag.Length
    }
}

$html = Get-Content -LiteralPath $HtmlPath -Raw -Encoding UTF8
$htmlDir = Split-Path -Parent (Resolve-Path -LiteralPath $HtmlPath)
$bodyMatch = [regex]::Match($html, '<div class="container">(.*?)</div>\s*</body>', 'Singleline')
$body = $bodyMatch.Groups[1].Value

$word = $null
$doc = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $doc = $word.Documents.Add()
    $sel = $word.Selection

    $sel.PageSetup.TopMargin = $word.CentimetersToPoints(2.5)
    $sel.PageSetup.BottomMargin = $word.CentimetersToPoints(2.5)
    $sel.PageSetup.LeftMargin = $word.CentimetersToPoints(2.8)
    $sel.PageSetup.RightMargin = $word.CentimetersToPoints(2.8)

    $pos = 0
    while ($pos -lt $body.Length) {
        $block = Get-NextBlock -Text $body -Start $pos
        if (-not $block) { break }
        $pos = $block.Next

        switch ($block.Tag) {
            'h1' {
                $sel.Font.Size = 22
                $sel.Font.Bold = $true
                $sel.Font.NameFarEast = '宋体'
                $sel.ParagraphFormat.SpaceAfter = 12
                $sel.TypeText($block.Inner.Trim())
                $sel.TypeParagraph()
                $sel.Font.Bold = $false
                $sel.Font.Size = 12
            }
            'blockquote' {
                foreach ($p in [regex]::Matches($block.Inner, '<p>(.*?)</p>', 'Singleline')) {
                    $sel.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.6)
                    $sel.ParagraphFormat.SpaceAfter = 6
                    Write-RichParagraph -Selection $sel -InnerHtml $p.Groups[1].Value -Gray
                    $sel.ParagraphFormat.LeftIndent = 0
                }
                $sel.ParagraphFormat.SpaceAfter = 12
            }
            'figure' {
                $src = [regex]::Match($block.Inner, 'src="([^"]+)"').Groups[1].Value
                $cap = [regex]::Match($block.Inner, '<figcaption>(.*?)</figcaption>', 'Singleline').Groups[1].Value
                $imgPath = [System.IO.Path]::GetFullPath((Join-Path $htmlDir $src))
                Write-ImageBlock -Selection $sel -Word $word -ImagePath $imgPath -Caption $cap
                $sel.ParagraphFormat.SpaceAfter = 12
            }
            'h2' {
                $sel.ParagraphFormat.SpaceBefore = 18
                $sel.ParagraphFormat.SpaceAfter = 10
                $sel.Font.Size = 16
                $sel.Font.Bold = $true
                $sel.Font.NameFarEast = '宋体'
                $sel.TypeText($block.Inner.Trim())
                $sel.TypeParagraph()
                $sel.Font.Bold = $false
                $sel.Font.Size = 12
            }
            'p' {
                $sel.ParagraphFormat.SpaceAfter = 8
                if ($block.Class -eq 'footer') {
                    $sel.ParagraphFormat.SpaceBefore = 18
                    Write-RichParagraph -Selection $sel -InnerHtml ($block.Inner -replace '<[^>]+>', '') -Footer
                }
                elseif ($block.Class -eq 'key-sentence') {
                    $sel.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.4)
                    Write-RichParagraph -Selection $sel -InnerHtml $block.Inner -FontSize 13 -BoldAll
                    $sel.ParagraphFormat.LeftIndent = 0
                }
                else {
                    Write-RichParagraph -Selection $sel -InnerHtml $block.Inner
                }
            }
        }
    }

    if (Test-Path -LiteralPath $DocxPath) { Remove-Item -LiteralPath $DocxPath -Force }
    $doc.SaveAs2([ref]$DocxPath, [ref]16)
    $doc.Close([ref]0)
    $word.Quit()
}
finally {
    if ($doc) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) }
    if ($word) { [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Output "saved: $DocxPath"
