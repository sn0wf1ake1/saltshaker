Clear-Host

<# Password start #>
$password = "Password"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
$password_salted = @()
$password_salted_temp = ''

$x = ([long][char]$password.Substring(0,1) / [math]::E).ToString().Substring(3)
$y = ''

for($i = 0; $i -lt $password.Length; $i++) {
    $x += ([long][char]$password.Substring($i,1) / [math]::E).ToString() + $y
    $y += ($x.Substring($x.Length - 6,6) / [math]::E).ToString()
}

$password_salted_temp = $x.Replace(',','').Replace('.','')

for($i = 0; $i -le $password_salted_temp.Length - ($password_salted_temp.Length % 3) - 1; $i += 3) {
    $password_salted += [System.Convert]::ToString($password_salted_temp.Substring($i,3) % 255,2).PadLeft(8,'0')
}

'Password salted: ' + ($password_salted -join ' ').Substring(0,135) + '...' # Salt is way too long to display
<# Password end #>

<# 4 character block to be encrypted start #>
$block = "xøå雨"

'Block text:      ' + $block
<# 4 character block to be encrypted end #>

<# UTF-8 encode into 16 byte blocks start #>
[string]$blocks_encoded = ''

for($j = 0; $j -lt 4; $j++) {
    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($([string]$block.Substring($j,1))))
    [string]$utf = ''

    for($i = 0; $i -lt 4; $i++) {
        $utf += [char]($base64.Substring($i,1))
    }

    $blocks_encoded += $utf
}

'UTF-8 encoded:   ' + $blocks_encoded
<# UTF-8 encode into 16 byte blocks end #>

<# Encrypt start #>
$utf_binary = @()

foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
    $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
}

'UTF-8 binary:    ' + $utf_binary -join ' '

$utf_binary_string = $utf_binary -join ''
$password_salted_string = $password_salted -join ''
$password_rotations = [int](($password_salted.Count - ($password_salted.Count % 16)) / 128) # Do not try to understand this line of code

'Rotations:       ' + $password_rotations

for($i = 0; $i -lt $password_rotations; $i++) {
    for($j = 0; $j -lt 128; $j++) {
        $utf_binary_string += $utf_binary_string.Substring($i * 128,128).Substring($j,1) -bxor $password_salted_string.Substring($i * 128,128).Substring($j,1)
    }
}

$block_encrypted = @()
$block_encrypted_text = ''
$utf_binary_string = $utf_binary_string.Substring($utf_binary_string.Length - 128,128)

for($i = 0; $i -lt 128; $i += 8) {
    $block_encrypted += $utf_binary_string.Substring($i,8)
}

'Encrypted:       ' + $block_encrypted -join ' '

for($i = 0; $i -lt 16; $i++) {
    $block_encrypted_text += [char][Convert]::ToInt32($block_encrypted[$i],2)
}

'Encrypted text:  ' + $block_encrypted_text
<# Encrypt end #>

<# Decrypt start #>
for($i = 0; $i -lt $password_rotations; $i++) {
    for($j = 0; $j -lt 128; $j++) {
        $utf_binary_string += $utf_binary_string.Substring($i * 128,128).Substring($j,1) -bxor $password_salted_string.Substring($i * 128,128).Substring($j,1)
    }
}

$blocks_encoded = ''
$block_decrypted = $utf_binary_string.Substring($utf_binary_string.Length - 128,128) -split '(\w{8})' | Where-Object {$_}

'Decrypted:       ' + $block_decrypted -join ' '

for($i = 0; $i -lt 16; $i++) {
    $blocks_encoded +=  [char][convert]::ToInt32($block_decrypted[$i],2)
}

'UTF-8 encoded:   ' + $blocks_encoded
<# Decrypt end #>

<# UTF-8 decode start #>
[string]$blocks_decoded = ''

for($j = 0; $j -le 12; $j += 4) {
    [string]$utf = ''

    for($i = 0; $i -le 3; $i++) {
        $utf += [char]($blocks_encoded.Substring($j,4).Substring($i,1))
    }

    $blocks_decoded += [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf))
}

'Block decoded:   ' + $blocks_decoded
<# UTF-8 decode end #>
