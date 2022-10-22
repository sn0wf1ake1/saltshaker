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
<# Password end #>

function saltshaker() {
     param (
        [Parameter(Mandatory = $true)] [string]$block,
        [Parameter(Mandatory = $true)] [byte]$debugging
    )

    if($debugging -eq 1){Write-Host ('Password salted: ' + ($password_salted -join ' ').Substring(0,135) + '...')} # Salt is way too long to display

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

    if($debugging -eq 1){Write-Host ('UTF-8 encoded:   ' + $blocks_encoded)}
    <# UTF-8 encode into 16 byte blocks end #>

    <# Encrypt start #>
    $utf_binary = @()

    foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
        $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
    }

    if($debugging -eq 1){Write-Host ('UTF-8 binary:    ' + $utf_binary -join ' ')}

    $utf_binary_string = $utf_binary -join ''
    $password_salted_string = $password_salted -join ''
    $password_rotations = [int](($password_salted.Count - ($password_salted.Count % 16)) / 128) # Do not try to understand this line of code

    if($debugging -eq 1){Write-Host ('Rotations:       ' + $password_rotations)}

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

    if($debugging -eq 1){Write-Host ('Encrypted:       ' + $block_encrypted -join ' ')}

    for($i = 0; $i -lt 16; $i++) {
        $j = [Convert]::ToInt32($block_encrypted[$i],2)
        if($j -ne 158) { # x9E cannot be converted for some reason
            $block_encrypted_text += [char]$j
        }
    }

    if($debugging -eq 1){Write-Host ('Encrypted text:  ' + $block_encrypted_text)}
    <# Encrypt end #>

    <# Decrypt start #>
    for($i = 0; $i -lt $password_rotations; $i++) {
        for($j = 0; $j -lt 128; $j++) {
            $utf_binary_string += $utf_binary_string.Substring($i * 128,128).Substring($j,1) -bxor $password_salted_string.Substring($i * 128,128).Substring($j,1)
        }
    }

    $blocks_encoded = ''
    $block_decrypted = $utf_binary_string.Substring($utf_binary_string.Length - 128,128) -split '(\w{8})' | Where-Object {$_}

    if($debugging -eq 1){Write-Host ('Decrypted:       ' + $block_decrypted -join ' ')}

    for($i = 0; $i -lt 16; $i++) {
        $blocks_encoded +=  [char][convert]::ToInt32($block_decrypted[$i],2)
    }

    if($debugging -eq 1){Write-Host ('UTF-8 decoded:   ' + $blocks_encoded)}
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

    return @($blocks_decoded,$block_encrypted_text)
    <# UTF-8 decode end #>
}

<# String divided into 4 character blocks to be encrypted start #>
$data = "aaaaaaaaaaaaaaaaaæøå雨wxzQ"
$data_padding = ''
$blocks_decoded_array = @()
$blocks_decoded_string = ''
$blocks_encrypted_string = ''

for($i = 0; $i -lt (4 - ($data.Length + 1) % 4) % 4; $i++) {
    $data_padding += [char](Get-Random -Minimum 32 -Maximum 126)
}

$data = ((4 - ($data.Length + 1) % 4) % 4).ToString() + $data + $data_padding # First byte counts how many padded characters has been added to the final block

for($i = 0; $i -lt $data.Length / 4; $i++) {
    $blocks_decoded_array += saltshaker $data.Substring($i * 4,4) 1
}

for($i = 0; $i -lt $blocks_decoded_array.Count; $i += 2) {
    $blocks_encrypted_string += $blocks_decoded_array[$i + 1] + '   '
    $blocks_decoded_string += $blocks_decoded_array[$i]
}

Write-Host ('Encrypted:       ' + $blocks_encrypted_string)
Write-Host ('Decrypted:       ' + $blocks_decoded_string.Substring(1, $blocks_decoded_string.Length - ([int]$blocks_decoded_string.Substring(0,1) + 1)))
<# String divided into 4 character blocks to be encrypted end #>
