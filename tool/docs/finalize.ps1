# Fill Word tables of contents and recalculate Excel formulas (requires Microsoft Office).
#   powershell -ExecutionPolicy Bypass -File tool/docs/finalize.ps1
$docs = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'docs'

$x = New-Object -ComObject Excel.Application
$x.Visible = $false; $x.DisplayAlerts = $false
try {
  Get-ChildItem $docs -Filter 'GYMVIA-*.xlsx' | ForEach-Object {
    $wb = $x.Workbooks.Open($_.FullName); $x.CalculateFull(); $wb.Save(); $wb.Close()
    "recalculated: $($_.Name)"
  }
} finally { $x.Quit() }

$w = New-Object -ComObject Word.Application
$w.Visible = $false; $w.DisplayAlerts = 0
try {
  Get-ChildItem $docs -Filter 'GYMVIA-*.docx' | ForEach-Object {
    $d = $w.Documents.Open($_.FullName)
    foreach ($t in $d.TablesOfContents) { $t.Update() }
    $d.Save()
    "toc updated: $($_.Name) ($($d.ComputeStatistics(2)) pages)"
    $d.Close()
  }
} finally { $w.Quit() }
