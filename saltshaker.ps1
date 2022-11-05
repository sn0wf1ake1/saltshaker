Clear-Host

# Slow as molasses and also found a major weakness in the password salt generator

<# Password start #>
$password = "Password"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
$password_salted = $password_salted_temp = $null

$x = ($password[0] / [math]::E).ToString().Substring(3)
$y = $null

for($i = 0; $i -lt $password.Length; $i++) {
    $x += ($password[$i] / [math]::E).ToString() + ($x[-6] / [math]::E).ToString() + $y
    $y += ($x[-6] / [math]::E).ToString()
}

$password_salted_temp = $x -replace "[^0-9]"

for($i = 0; $i -le $password_salted_temp.Length - ($password_salted_temp.Length % 3) - 1; $i += 3) {
    $password_salted += [System.Convert]::ToString($password_salted_temp.Substring($i,3) % 255,2).PadLeft(8,'0')
}
<# Password end #>

function saltshaker() {
     param (
        [Parameter(Mandatory = $true)] [string]$block_previous,
        [Parameter(Mandatory = $true)] [string]$block,
        [Parameter(Mandatory = $true)] [int]$rotations
    )

    #Write-Host ('Password salted:  ' + ($password_salted).Substring(0,128) + '...') # Salt is way too long to display

    <# UTF-8 encode into 16 byte blocks start #>
    [string]$blocks_encoded = $null

    for($i = 0; $i -lt 4; $i++) {
        $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($([string]$block[$i])))
        [string]$utf = $null

        for($j = 0; $j -lt 4; $j++) {
            $utf += [char]($base64[$j])
        }

        $blocks_encoded += $utf
    }

    #Write-Host ('UTF-8 encoded:    ' + $blocks_encoded)
    <# UTF-8 encode into 16 byte blocks end #>

    <# Encrypt start #>
    $utf_binary = $utf_binary_string = $null

    foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
        $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
    }

    for($i = 0; $i -lt $rotations; $i++) {
        for($j = 0; $j -lt 128; $j++) {
            $utf_binary +=  [byte]('0' + $block_previous[$j]) -bxor
                            [byte]$utf_binary.Substring($i * 128,128).Substring($j,1) -bxor
                            [byte]$password_salted.Substring($i * 128,128).Substring($j,1)
        }
    }

    $utf_binary = $utf_binary.Substring($utf_binary.Length - 128,128)
        
    for($i = 0; $i -lt 128; $i += 8) {
        $j = [System.Convert]::ToInt32($utf_binary.Substring($i,8),2)
        if($j -ge 32 -and $j -le 126) { # Strip non-visible characters for debug purposes
            $utf_binary_string += [char]$j
        }
    }

    Write-Host ('UTF-8 binary:     ' + $utf_binary + "`n" + 'Encrypted string: ' + $utf_binary_string)
    <# Encrypt end #>

    <# Decrypt start #>
    for($i = 0; $i -lt $rotations; $i++) {
        for($j = 0; $j -lt 128; $j++) {
            $utf_binary +=  [byte]('0' + $block_previous[$j]) -bxor
                            [byte]$utf_binary.Substring($i * 128,128).Substring($j,1) -bxor
                            [byte]$password_salted.Substring($i * 128,128).Substring($j,1)
        }
    }

    $utf_binary = $utf_binary.Substring($utf_binary.Length - 128,128)
    $blocks_encoded = $null

    for($i = 0; $i -lt 16; $i++) {
        $blocks_encoded += [char][convert]::ToInt32($utf_binary.Substring($i * 8,8),2)
    }

    #Write-Host ('UTF-8 decoded:   ' + $blocks_encoded)
    <# Decrypt end #>

    <# UTF-8 decode start #>
    [string]$block_decoded = $null

    for($j = 0; $j -le 12; $j += 4) {
        [string]$utf = $null

        for($i = 0; $i -le 3; $i++) {
            $utf += [char]($blocks_encoded.Substring($j,4)[$i])
        }

        $block_decoded += [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($utf))
    }

    return $utf_binary + $block_decoded
    <# UTF-8 decode end #>
}

<# String divided into 4 character blocks to be encrypted start #>
$data = "aaaaaaaaaaaaaaannnnnæøå雨wxzQ"
$data_padding = $block_decoded = $block_decoded_temp = $data_crc = $null
$block_previous = $password_salted.Substring($password_salted.Length - 128,128) # CBC initialization vector

<# CRC padding start #>
for($i = 0; $i -lt $data.Length; $i++) {
    $data_crc += [double]$data[$i] + $data_crc % [math]::E
}

$data_crc = [string]$data_crc -replace "[^0-9]"

for($i = 0; $i -lt (4 - ($data.Length + 1) % 4) % 4; $i++) {
    $data_padding += [char]([int]($data_crc.ToString().Substring($i,3)) % 255)
}
<# CRC padding end #>

$data = ((4 - ($data.Length + 1) % 4) % 4).ToString() + $data + $data_padding # First byte counts how many padded characters has been added to the final block

for($i = 0; $i -lt $data.Length / 4; $i++) {
    $block_decoded_temp = saltshaker $block_previous $data.Substring($i * 4,4) ($i % 9)
    $block_previous = $block_decoded_temp.Substring(0,127)
    $block_decoded += $block_decoded_temp.Substring(128,4)
}

Write-Host ('Decrypted:        ' + $block_decoded.Substring(1, $block_decoded.Length - ([int]$block_decoded.Substring(0,1) + 1)))
<# String divided into 4 character blocks to be encrypted end #>
