# Remap Intel HEX from STM32 secure flash alias 0x0Cxxxxxx to 0x08xxxxxx.
# J-Link / CubeProgrammer program the 0x08000000 flash window, not 0x0C000000.
param(
    [Parameter(Mandatory = $true)][string]$InFile,
    [Parameter(Mandatory = $true)][string]$OutFile
)

$lines = Get-Content -LiteralPath $InFile
$out = New-Object System.Collections.Generic.List[string]
foreach ($line in $lines) {
    $t = $line.Trim()
    if ($t.StartsWith(':') -and $t.Length -ge 15 -and $t.Substring(7, 2) -eq '04') {
        $data = $t.Substring(9, 4)
        $hi = [Convert]::ToInt32($data, 16)
        if ($hi -ge 0x0C00 -and $hi -le 0x0C1F) {
            $nhi = $hi - 0x0400
            $len = [Convert]::ToInt32($t.Substring(1, 2), 16)
            $ah = [Convert]::ToInt32($t.Substring(3, 2), 16)
            $al = [Convert]::ToInt32($t.Substring(5, 2), 16)
            $d0 = ($nhi -shr 8) -band 0xFF
            $d1 = $nhi -band 0xFF
            $sum = $len + $ah + $al + 4 + $d0 + $d1
            $ck = ((-$sum) -band 0xFF)
            $t = (':{0:X2}{1:X2}{2:X2}04{3:X4}{4:X2}' -f $len, $ah, $al, $nhi, $ck)
        }
    }
    $out.Add($t)
}
$out | Set-Content -LiteralPath $OutFile -Encoding ascii
