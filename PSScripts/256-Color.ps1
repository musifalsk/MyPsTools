# 256-Color Foreground & Background Charts
$esc = $([char]27)
Write-Output "`n$esc[1;4m256-Color Foreground & Background Charts$esc[0m"
foreach ($fgbg in 38, 48) {
    # foreground/background switch
    foreach ($color in 0..255) {
        # color range
        #Display the colors
        $field = "$color".PadLeft(4)  # pad the chart boxes with spaces
        Write-Host -NoNewline "$esc[$fgbg;5;${color}m$field $esc[0m"
        #Display 6 colors per line
        if ( (($color + 1) % 6) -eq 4 ) { Write-Output "`r" }
    }
    Write-Output `n
}

# Color Codes
$white = $([char]27) + '[0m'
$grey = $([char]27) + '[38;5;250m'
$red = $([char]27) + '[38;5;196m'
$orange = $([char]27) + '[38;5;214m'
$yellow = $([char]27) + '[38;5;11m'
$green = $([char]27) + '[38;5;46m'
$cyan = $([char]27) + '[38;5;51m'
$blue = $([char]27) + '[38;5;75m'
$purple = $([char]27) + '[38;5;201m'
$pink = $([char]27) + '[38;5;219m'


"$($red)Test color string$($white)"
