# Convert Intel HEX to a dense .bin on the 0x08 flash alias.
# Two-pass native byte[] (do not store one dictionary entry per byte).
param(
    [Parameter(Mandatory = $true)][string]$InFile,
    [Parameter(Mandatory = $true)][string]$OutFile
)

$MaxSize = 2MB
$lines = [System.IO.File]::ReadAllLines($InFile)

$ela = [int64]0
$min = [int64]::MaxValue
$max = [int64]-1
foreach ($raw in $lines) {
    $t = $raw.Trim()
    if (-not $t.StartsWith(':') -or $t.Length -lt 11) { continue }
    $len = [Convert]::ToInt32($t.Substring(1, 2), 16)
    $off = [Convert]::ToInt32($t.Substring(3, 4), 16)
    $typ = [Convert]::ToInt32($t.Substring(7, 2), 16)
    if ($typ -eq 4 -and $t.Length -ge 15) {
        $ela = [int64][Convert]::ToInt32($t.Substring(9, 4), 16)
        continue
    }
    if ($typ -ne 0) { continue }
    $addr = ($ela -shl 16) + $off
    if ($addr -ge 0x0C000000 -and $addr -lt 0x0C200000) { $addr -= 0x04000000 }
    if ($addr -lt $min) { $min = $addr }
    $end = $addr + $len - 1
    if ($end -gt $max) { $max = $end }
}
if ($max -lt $min) { throw "No data records in $InFile" }
$size = [int64]($max - $min + 1)
if ($size -le 0 -or $size -gt $MaxSize) {
    throw "HEX span 0x$($min.ToString('X8'))-0x$($max.ToString('X8')) size=$size exceeds $MaxSize"
}

$blob = New-Object byte[] $size
$ela = [int64]0
foreach ($raw in $lines) {
    $t = $raw.Trim()
    if (-not $t.StartsWith(':') -or $t.Length -lt 11) { continue }
    $len = [Convert]::ToInt32($t.Substring(1, 2), 16)
    $off = [Convert]::ToInt32($t.Substring(3, 4), 16)
    $typ = [Convert]::ToInt32($t.Substring(7, 2), 16)
    if ($typ -eq 4 -and $t.Length -ge 15) {
        $ela = [int64][Convert]::ToInt32($t.Substring(9, 4), 16)
        continue
    }
    if ($typ -ne 0) { continue }
    $addr = ($ela -shl 16) + $off
    if ($addr -ge 0x0C000000 -and $addr -lt 0x0C200000) { $addr -= 0x04000000 }
    $base = [int]($addr - $min)
    for ($i = 0; $i -lt $len; $i++) {
        $blob[$base + $i] = [Convert]::ToByte($t.Substring(9 + 2 * $i, 2), 16)
    }
}

[IO.File]::WriteAllBytes($OutFile, $blob)
Set-Content -LiteralPath ($OutFile + '.addr') -Value ('0x{0:X8}' -f $min) -Encoding ascii
Write-Output ("LOAD=0x{0:X8} SIZE={1}" -f $min, $size)
