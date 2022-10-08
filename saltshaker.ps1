Clear-Host

<# Password start #>
$password = "passwod  2"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
$password_binary = @()

for($i = 0; $i -le $password.Length - 1; $i++) {
    $password_binary += [System.Convert]::ToString([byte][char]$password.Substring($i,1),2).PadLeft(8,'0')
}

$password_binary -join ' '
<# Password end #>

$block = "æøå雨"

'Block encoded: ' + $block

<# UTF-8 encode into 16 byte blocks start #>
[string]$blocks_encoded = ''

for($j = 0; $j -le 3; $j++) {
    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($([string]$block.Substring($j,1))))
    [string]$utf = ''

    for($i = 0; $i -le 3; $i++) {
        $utf += [char]($base64.Substring($i,1))
    }

    $blocks_encoded += $utf
}

'UTF-8 encoded: ' + $blocks_encoded
<# UTF-8 encode into 16 byte blocks end #>

<# Encryption start #>
$utf_binary = @()

foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
    $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
}

$utf_binary -join ' '
<# Encryption end #>

<# UTF-8 decode start #>
[string]$blocks_decoded = ''

for($j = 0; $j -le 12; $j += 4) {
    [string]$utf = ''

    for($i = 0; $i -le 3; $i++) {
        $utf += [char]($blocks_encoded.Substring($j,4).Substring($i,1))
    }

    $blocks_decoded += [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf))
}

'Block decoded: ' + $blocks_decoded
<# UTF-8 decode end #>
