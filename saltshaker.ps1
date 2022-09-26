# START Split a character into a 4 block array
$test = 'z'
$test = 'æ'
$test = '雨'

$x = @(0,0,0,0)
$y = [System.Text.Encoding]::Default.GetBytes($test).Length - 1
for($i = 0; $i -le $y; $i++) {
    $x[$i + 3 - $y] = [System.Text.Encoding]::Default.GetBytes($test)[$i]
}
# END Split a character into a 4 block array

#START Encode the character to a 4 block binary entity
[string]$b = '00000000000000000000000000000000'
for($i = 0; $i -lt 4; $i++) {
    [string]$a = [convert]::ToString([int32]$x[$i],2)
    for($y = 0; $y -lt 8 - $a.Length; $y++) {
        $a = '0' + $a
    }

    $b += $a
}

$b.Substring($b.Length - 32)
#END Encode the character to a 4 block binary entity
