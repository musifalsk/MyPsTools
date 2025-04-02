
$pdfPath = '<Path to pdf>'
$pdfPath = Read-Host 'Enter the path to the PDF file'
$docxPath = $pdfPath -replace '\.pdf$', '.docx'

# Create a new instance of Microsoft Word
$word = New-Object -ComObject Word.Application
# $word.Visible = $false # Default value is $false
# $word.DisplayAlerts = 0 # Default value is 0

# Open the PDF document and Save as a docx file
$document = $word.Documents.Open($pdfPath, [ref]$false)
$document.SaveAs([ref]$docxPath, [ref]16) # 16 is the format for .docx

# Close and cleanup
$document.Close()
$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word)
Remove-Variable word
