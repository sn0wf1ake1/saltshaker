Clear-Host

<# Password start #>
$password = "password"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
$password_binary = @()
$password_salted = @()
$password_salted_temp = ''

for($i = 0; $i -lt $password.Length; $i++) {
    $password_binary += [System.Convert]::ToString([byte][char]$password.Substring($i,1),2).PadLeft(8,'0')
}

'Password binary: ' + $password_binary -join ' '

<# Salt password start #>
for($i = 0; $i -lt $password.Length; $i++) {
    $password_salted_temp += (([long][char]$password[$i] + $i) / [math]::E).ToString().Substring(3)
}

for($i = 0; $i -le $password_salted_temp.Length - ($password_salted_temp.Length % 3) - 1; $i += 3) {
    $password_salted += [System.Convert]::ToString($password_salted_temp.Substring($i,3) % 255,2).PadLeft(8,'0')
}

'Password salted: ' + ($password_salted -join ' ').Substring(0,135) + '...' # Salt is way too long to display
<# Salt password end #>
<# Password end #>

<# 4 character block to be encrypted start #>
$block = "æøå雨"

'Block encoded:   ' + $block
<# 4 character block to be encrypted end #>

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

'UTF-8 encoded:   ' + $blocks_encoded
<# UTF-8 encode into 16 byte blocks end #>

<# Encryption start #>
$utf_binary = @()

foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
    $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
}

'UTF-8 binary:    ' + $utf_binary -join ' '

$utf_binary_string = $utf_binary -join ''
$password_salted_string = $password_salted -join ''

for($i = 0; $i -lt ($password_salted.Count - ($password_salted.Count % 16)) / 16; $i++) { # Amount of cycles based on $password_salted length
    for($j = 0; $j -lt 128; $j++) {
        $utf_binary_string += $utf_binary_string.Substring($i * 128,128).Substring($j,1) -bxor $password_salted_string.Substring($i * 128,128).Substring($j,1)
    }
}

$block_encrypted = @()
$utf_binary_string = $utf_binary_string.Substring($utf_binary_string.Length - 128,128)

for($i = 0; $i -lt 128; $i += 8) {
    $block_encrypted += $utf_binary_string.Substring($i,8)
}

'Encrypted:       ' + $block_encrypted -join ' '
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

'Block decoded:   ' + $blocks_decoded
<# UTF-8 decode end #>
