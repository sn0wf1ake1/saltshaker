# START Split a character into a 4 block array
$test = 'z'
$test = 'æ'
$test = '雨'

$x = @(0,0,0,0)
$y = [System.Text.Encoding]::Default.GetBytes($test).Length - 1
for($i = 0; $i -le $y; $i++) {
    $x[$i + 3 - $y] = [System.Text.Encoding]::Default.GetBytes($test)[$i]
}

$x
# END Split a character into a 4 block array