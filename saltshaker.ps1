Clear-Host

$password = "passwod  2"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
#$UserName = (Get-Random -Minimum 10 -Maximum 99).ToString() + $password + "æøå雨 test aaa nkjfk l k nkf kbrkh b4oooioj"
#$UserName = Get-Random
#"$UserName`n".Substring(0,4)
$block = "æøå雨"

'Block encoded: ' + $block
[string]$blocks_encoded = ''

<# Encode start #>
for($j = 0; $j -le 3; $j++) {
    $EncodedText = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($([string]$block.Substring($j,1))))
#    "Encoded text: $EncodedText" # Debug

    [string]$utf2 = ''

    for($i = 0; $i -le 3; $i++) {
        $x = [byte][char]($EncodedText.Substring($i,1))
        $y = $x -bxor 19
        $utf2 += [char]$y
    }

#    'Encoded: ' + $utf2 # Debug

    $blocks_encoded += $utf2
}
<# Encode end #>

<# Decode start #>
$blocks_decoded = ''

for($j = 0; $j -le 12; $j += 4) {
    [string]$utf3 = ''

    for($i = 0; $i -le 3; $i++) {
        $x = [byte][char]($blocks_encoded.Substring($j,4).Substring($i,1))
        $y = $x -bxor 19
        $utf3 += [char]$y
    }

#    'Block: ' + [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf3)) # Debug

    $blocks_decoded += [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf3))
}

'Block decoded: ' + $blocks_decoded
<# Decode end #>
