Clear-Host

$password = "passwod  2"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
#$UserName = (Get-Random -Minimum 10 -Maximum 99).ToString() + $password + "æøå雨 test aaa nkjfk l k nkf kbrkh b4oooioj"
#$UserName = Get-Random
#"$UserName`n".Substring(0,4)
$block = "æøå雨"

'Block encoded: ' + $block

<# UTF-8 encode start #>
[string]$blocks_encoded = ''

for($j = 0; $j -le 3; $j++) {
    $EncodedText = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($([string]$block.Substring($j,1))))
#    "Encoded text: $EncodedText" # Debug

    [string]$utf = ''

    for($i = 0; $i -le 3; $i++) {
        $x = [byte][char]($EncodedText.Substring($i,1))
        $y = $x -bxor 19
        $utf += [char]$y
    }

#    'Encoded: ' + $utf # Debug

    $blocks_encoded += $utf
}
<# UTF-8 encode end #>

<# UTF-8 decode start #>
[string]$blocks_decoded = ''

for($j = 0; $j -le 12; $j += 4) {
    [string]$utf = ''

    for($i = 0; $i -le 3; $i++) {
        $x = [byte][char]($blocks_encoded.Substring($j,4).Substring($i,1))
        $y = $x -bxor 19
        $utf += [char]$y
    }

#    'Block: ' + [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf)) # Debug

    $blocks_decoded += [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf))
}

'Block decoded: ' + $blocks_decoded
<# UTF-8 decode end #>
