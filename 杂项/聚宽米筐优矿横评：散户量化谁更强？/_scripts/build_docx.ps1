# 生成 06 / 杂项文章定稿 .docx
# 用法（PowerShell 5.1 兼容）：
#   powershell -ExecutionPolicy Bypass -File _scripts\build_docx.ps1
#
# 该脚本会读取：
#   06_修订与发布\修订稿 v4 纯文本.txt
# 并输出：
#   06_修订与发布\定稿.docx

param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Packaging
Add-Type -AssemblyName System.Xml

$src = Join-Path $ProjectRoot "06_修订与发布\修订稿 v4 纯文本.txt"
$dst = Join-Path $ProjectRoot "06_修订与发布\定稿.docx"

if (-not (Test-Path $src)) { throw "找不到源文件: $src" }

# ---------- 1. 把纯文本解析为结构化段落 ----------
$raw = Get-Content -LiteralPath $src -Raw -Encoding UTF8

# 规范化空白
$raw = $raw.Replace("`r`n", "`n")

function New-Block {
    param([string]$Type, [string[]]$Lines = @(), [hashtable]$Meta = @{})
    [pscustomobject]@{ Type = $Type; Lines = $Lines; Meta = $Meta }
}

$blocks = New-Object System.Collections.Generic.List[object]

$lines = $raw -split "`n"
$i = 0
$total = $lines.Count

function Push-Block($blocks, $type, $lines) {
    $lines = @($lines | Where-Object { $_ -ne $null })
    if ($lines.Count -eq 0) { return }
    $blocks.Add([pscustomobject]@{ Type = $type; Lines = $lines })
}

while ($i -lt $total) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { $i++; continue }

    # 标题
    if ($line -match '^(#+)\s+(.*)$') {
        $level = $matches[1].Length
        $text = $matches[2].Trim()
        if ($level -eq 1) { $blocks.Add([pscustomobject]@{ Type = "Title"; Lines = @($text) }) }
        elseif ($level -eq 2) { $blocks.Add([pscustomobject]@{ Type = "H2"; Lines = @($text) }) }
        elseif ($level -eq 3) { $blocks.Add([pscustomobject]@{ Type = "H3"; Lines = @($text) }) }
        else { $blocks.Add([pscustomobject]@{ Type = "H4"; Lines = @($text) }) }
        $i++; continue
    }

    # 引用块
    if ($line -match '^\s*>\s?(.*)$') {
        $buf = New-Object System.Collections.Generic.List[string]
        while ($i -lt $total -and $lines[$i] -match '^\s*>\s?(.*)$') {
            $buf.Add($matches[1])
            $i++
        }
        $blocks.Add([pscustomobject]@{ Type = "Quote"; Lines = $buf.ToArray() })
        continue
    }

    # 无序列表（- 或 * 开头）
    if ($line -match '^\s*[-*]\s+(.*)$') {
        $buf = New-Object System.Collections.Generic.List[string]
        while ($i -lt $total -and $lines[$i] -match '^\s*[-*]\s+(.*)$') {
            $buf.Add($matches[1])
            $i++
        }
        $blocks.Add([pscustomobject]@{ Type = "Bullet"; Lines = $buf.ToArray() })
        continue
    }

    # 段落
    $buf = New-Object System.Collections.Generic.List[string]
    while ($i -lt $total -and -not [string]::IsNullOrWhiteSpace($lines[$i]) -and
           -not ($lines[$i] -match '^(#+)\s+') -and
           -not ($lines[$i] -match '^\s*>\s?') -and
           -not ($lines[$i] -match '^\s*[-*]\s+')) {
        $buf.Add($lines[$i])
        $i++
    }
    $blocks.Add([pscustomobject]@{ Type = "Para"; Lines = $buf.ToArray() })
}

# ---------- 2. 渲染为 Word XML ----------
function Escape-Xml([string]$s) {
    return $s.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace('"', "&quot;").Replace("'", "&apos;")
}

# 把 ** 加粗 还原成 run 序列
function Render-Inline([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    $sb = New-Object System.Text.StringBuilder
    $idx = 0
    while ($idx -lt $text.Length) {
        $star = $text.IndexOf("**", $idx)
        if ($star -lt 0) {
            [void]$sb.Append("<w:r><w:t xml:space=""preserve"">" + (Escape-Xml $text.Substring($idx)) + "</w:t></w:r>")
            break
        }
        if ($star -gt $idx) {
            [void]$sb.Append("<w:r><w:t xml:space=""preserve"">" + (Escape-Xml $text.Substring($idx, $star - $idx)) + "</w:t></w:r>")
        }
        $end = $text.IndexOf("**", $star + 2)
        if ($end -lt 0) {
            [void]$sb.Append("<w:r><w:t xml:space=""preserve"">" + (Escape-Xml $text.Substring($star)) + "</w:t></w:r>")
            break
        }
        $content = $text.Substring($star + 2, $end - $star - 2)
        [void]$sb.Append("<w:r><w:rPr><w:b/></w:rPr><w:t xml:space=""preserve"">" + (Escape-Xml $content) + "</w:t></w:r>")
        $idx = $end + 2
    }
    return $sb.ToString()
}

$docBody = New-Object System.Text.StringBuilder

foreach ($b in $blocks) {
    switch ($b.Type) {
        "Title" {
            [void]$docBody.Append('<w:p><w:pPr><w:pStyle w:val="Title"/><w:spacing w:before="360" w:after="240"/><w:jc w:val="center"/></w:pPr>')
            [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:b/><w:sz w:val=""40""/></w:rPr><w:t xml:space=""preserve"">" + (Escape-Xml $b.Lines[0]) + "</w:t></w:r>")
            [void]$docBody.Append("</w:p>")
        }
        "H2" {
            [void]$docBody.Append('<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:spacing w:before="320" w:after="160"/></w:pPr>')
            [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:b/><w:sz w:val=""32""/></w:rPr><w:t xml:space=""preserve"">" + (Escape-Xml $b.Lines[0]) + "</w:t></w:r>")
            [void]$docBody.Append("</w:p>")
        }
        "H3" {
            [void]$docBody.Append('<w:p><w:pPr><w:pStyle w:val="Heading3"/><w:spacing w:before="240" w:after="120"/></w:pPr>')
            [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:b/><w:sz w:val=""28""/></w:rPr><w:t xml:space=""preserve"">" + (Escape-Xml $b.Lines[0]) + "</w:t></w:r>")
            [void]$docBody.Append("</w:p>")
        }
        "H4" {
            [void]$docBody.Append('<w:p><w:pPr><w:pStyle w:val="Heading4"/><w:spacing w:before="200" w:after="100"/></w:pPr>')
            [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:b/><w:sz w:val=""24""/></w:rPr><w:t xml:space=""preserve"">" + (Escape-Xml $b.Lines[0]) + "</w:t></w:r>")
            [void]$docBody.Append("</w:p>")
        }
        "Para" {
            [void]$docBody.Append('<w:p><w:pPr><w:spacing w:line="360" w:lineRule="auto" w:after="120"/></w:pPr>')
            foreach ($ln in $b.Lines) {
                [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:sz w:val=""22""/></w:rPr><w:t xml:space=""preserve"">" + (Render-Inline $ln) + "</w:t></w:r>")
                if ($ln -ne $b.Lines[-1]) { [void]$docBody.Append('<w:r><w:br/></w:r>') }
            }
            [void]$docBody.Append("</w:p>")
        }
        "Quote" {
            [void]$docBody.Append('<w:p><w:pPr><w:ind w:left="480" w:right="480"/><w:spacing w:line="320" w:lineRule="auto" w:before="120" w:after="120"/></w:pPr>')
            foreach ($ln in $b.Lines) {
                [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:i/><w:color w:val=""595959""/><w:sz w:val=""22""/></w:rPr><w:t xml:space=""preserve"">" + (Render-Inline $ln) + "</w:t></w:r>")
                if ($ln -ne $b.Lines[-1]) { [void]$docBody.Append('<w:r><w:br/></w:r>') }
            }
            [void]$docBody.Append("</w:p>")
        }
        "Bullet" {
            foreach ($ln in $b.Lines) {
                [void]$docBody.Append('<w:p><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr><w:spacing w:line="320" w:lineRule="auto" w:after="60"/><w:ind w:left="420" w:hanging="420"/></w:pPr>')
                [void]$docBody.Append("<w:r><w:rPr><w:rFonts w:ascii=""Microsoft YaHei"" w:eastAsia=""Microsoft YaHei"" w:hAnsi=""Microsoft YaHei""/><w:sz w:val=""22""/></w:rPr><w:t xml:space=""preserve"">" + (Render-Inline $ln) + "</w:t></w:r>")
                [void]$docBody.Append("</w:p>")
            }
        }
    }
}

# ---------- 3. 组装 docx 部件 ----------
$contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$rels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$documentRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>
"@

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
$docBody
  </w:body>
</w:document>
"@

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:eastAsia="Microsoft YaHei" w:hAnsi="Calibri"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
        <w:lang w:val="zh-CN" w:eastAsia="zh-CN" w:bidi="ar-SA"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="120" w:line="320" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="360" w:after="240"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
      <w:b/>
      <w:sz w:val="40"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="320" w:after="160"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
      <w:b/>
      <w:sz w:val="32"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="240" w:after="120"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
      <w:b/>
      <w:sz w:val="28"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading4">
    <w:name w:val="heading 4"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="200" w:after="100"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
      <w:b/>
      <w:sz w:val="24"/>
    </w:rPr>
  </w:style>
</w:styles>
"@

$numberingXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0">
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:lvlText w:val="•"/>
      <w:lvlJc w:val="left"/>
      <w:pPr>
        <w:ind w:left="420" w:hanging="420"/>
      </w:pPr>
      <w:rPr>
        <w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/>
      </w:rPr>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="1">
    <w:abstractNumId w:val="0"/>
  </w:num>
</w:numbering>
"@

$coreXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>聚宽、米筐、优矿：散户选量化平台，最该比的不是功能</dc:title>
  <dc:creator>Content</dc:creator>
  <cp:lastModifiedBy>Content</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-06-13T18:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-06-13T18:00:00Z</dcterms:modified>
</cp:coreProperties>
"@

$appXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
  xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Content Pipeline</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>16.0000</AppVersion>
</Properties>
"@

# ---------- 4. 写入 docx 包 ----------
if (Test-Path $dst) { Remove-Item $dst -Force }
$dstDir = Split-Path -Parent $dst
if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }

$pkgUri = (New-Object System.Uri ([System.IO.Path]::GetFullPath($dst)))
$package = [System.IO.Packaging.Package]::Open($pkgUri, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite)

function Add-PartXml([System.IO.Packaging.Package]$package, [string]$partPath, [string]$contentType, [string]$content) {
    $partUri = New-Object System.Uri ($partPath, [System.UriKind]::Relative)
    $part = $package.CreatePart($partUri, $contentType, [System.IO.Packaging.CompressionOption]::Maximum)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $stream = $part.GetStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    return $part
}

# 顶层 _rels/.rels
$relsUri = New-Object System.Uri "/_rels/.rels", [System.UriKind]::Relative
$relsPart = $package.CreatePart($relsUri, "application/vnd.openxmlformats-package.relationships+xml", [System.IO.Packaging.CompressionOption]::Maximum)
$rs = $relsPart.GetStream(); $rb = [System.Text.Encoding]::UTF8.GetBytes($rels); $rs.Write($rb, 0, $rb.Length); $rs.Close()
$package.CreateRelationship($relsPart.Uri, [System.IO.Packaging.TargetMode]::Internal, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument") | Out-Null
# 直接使用根 .rels，不调用 CreateRelationship 因为我们手写完整

# 因为 CreateRelationship 是在 Part 上加 relationship，我们改为手写最简根 rels。
# 已经把根 rels 内容写死了，手写 .rels 即可。
# 接下来添加各 part
Add-PartXml $package "/word/document.xml" "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml" $documentXml | Out-Null
Add-PartXml $package "/word/styles.xml" "application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml" $stylesXml | Out-Null
Add-PartXml $package "/word/numbering.xml" "application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml" $numberingXml | Out-Null
Add-PartXml $package "/docProps/core.xml" "application/vnd.openxmlformats-package.core-properties+xml" $coreXml | Out-Null
Add-PartXml $package "/docProps/app.xml" "application/vnd.openxmlformats-officedocument.extended-properties+xml" $appXml | Out-Null

# document.xml.rels
$docRelsUri = New-Object System.Uri "/word/_rels/document.xml.rels", [System.UriKind]::Relative
$docRelsPart = $package.CreatePart($docRelsUri, "application/vnd.openxmlformats-package.relationships+xml", [System.IO.Packaging.CompressionOption]::Maximum)
$drs = $docRelsPart.GetStream(); $drb = [System.Text.Encoding]::UTF8.GetBytes($documentRels); $drs.Write($drb, 0, $drb.Length); $drs.Close()

# [Content_Types].xml 必须由包自动管理？Package 类会自动处理 Default 关系，但需要 Override 与 Default 完全匹配。
# 这里采用更稳妥的方式：把 [Content_Types].xml 替换为手写版本。
$ctPart = $package.GetPart(New-Object System.Uri "/[Content_Types].xml", [System.UriKind]::Relative)
if ($null -ne $ctPart) {
    $ctPartStream = $ctPart.GetStream()
    $ctPartStream.SetLength(0)
    $ctb = [System.Text.Encoding]::UTF8.GetBytes($contentTypes)
    $ctPartStream.Write($ctb, 0, $ctb.Length)
    $ctPartStream.Close()
}

$package.Close()

Write-Output "已生成: $dst"
