param(
    [string]$pdfPath = 'C:\Users\frank.nerland\OneDrive - Bouvet Norge AS\Documents\davechild_regular-expressions.pdf'
    # [string]$docxPath
)

# Test Path and PDF
if (-not(Test-Path -Path $pdfPath -PathType Leaf)) {
    Write-Error "Not a valid path: $pdfPath"
    exit 1
}
if ((Get-Item $pdfPath).Extension -ne '.pdf') {
    Write-Error "Not a PDF: $pdfPath"
    exit 1
}

# Destination path for the converted docx file
$docxPath = $pdfPath -replace '\.pdf$', '.docx'

# Open the PDF document and Save as a docx file
$word = New-Object -ComObject Word.Application
# $word.Visible = $false # Default value is $false
# $word.DisplayAlerts = 0 # Default value is 0
$document = $word.Documents.Open($pdfPath, [ref]$false)
$document.SaveAs([ref]$docxPath, [ref]16) # 16 is the format for .docx

# Close and cleanup
$document.Close()
$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
Remove-Variable word
