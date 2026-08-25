# Convert Intel HEX to a dense .bin on the 0x08 flash alias.
# 0x0Cxxxxxx (secure alias) is mapped to 0x08xxxxxx.
param(
    [Parameter(Mandatory = $true)][string]$InFile,
    [Parameter(Mandatory = $true)][string]$OutFile
)

$map = New-Object 'System.Collections.Generic.SortedDictionary[uint32,byte]'
$ela = [uint32]0
foreach ($raw in Get-Content -LiteralPath $InFile) {
    $t = $raw.Trim()
    if (-not $t.StartsWith(':') -or $t.Length -lt 11) { continue }
    $len = [Convert]::ToInt32($t.Substring(1, 2), 16)
    $off = [Convert]::ToInt32($t.Substring(3, 4), 16)
    $typ = [Convert]::ToInt32($t.Substring(7, 2), 16)
    if ($typ -eq 4 -and $t.Length -ge 15) {
        $ela = [uint32][Convert]::ToInt32($t.Substring(9, 4), 16)
        continue
    }
    if ($typ -ne 0) { continue }
    $addr = ([uint32]($ela -shl 16)) + [uint32]$off
    if ($addr -ge [uint32]0x0C000000 -and $addr -lt [uint32]0x0C200000) {
        $addr = $addr - [uint32]0x04000000
    }
    for ($i = 0; $i -lt $len; $i++) {
        $map[[uint32]($addr + $i)] = [Convert]::ToByte($t.Substring(9 + 2 * $i, 2), 16)
    }
}
if ($map.Count -eq 0) { throw "No data records in $InFile" }
$min = [uint32]($map.Keys | Select-Object -First 1)
$max = [uint32]($map.Keys | Select-Object -Last 1)
$size = [int]($max - $min + 1)
$blob = New-Object byte[] $size
foreach ($k in $map.Keys) { $blob[$k - $min] = $map[$k] }
[IO.File]::WriteAllBytes($OutFile, $blob)
$addrTxt = $OutFile + '.addr'
Set-Content -LiteralPath $addrTxt -Value ('0x{0:X8}' -f $min) -Encoding ascii
Write-Output ("LOAD=0x{0:X8} SIZE={1}" -f $min, $size)
