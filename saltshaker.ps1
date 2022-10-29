Clear-Host

<# Password start #>
$password = "Password"
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($password)))
$password_salted = $password_salted_temp = ''

$x = ([long][char]$password.Substring(0,1) / [math]::E).ToString().Substring(3)
$y = ''

for($i = 0; $i -lt $password.Length; $i++) {
    $x += ([long][char]$password.Substring($i,1) / [math]::E).ToString() + $y
    $y += ($x.Substring($x.Length - 6,6) / [math]::E).ToString()
}

$password_salted_temp = $x -replace "[^0-9]"

for($i = 0; $i -le $password_salted_temp.Length - ($password_salted_temp.Length % 3) - 1; $i += 3) {
    $password_salted += [System.Convert]::ToString($password_salted_temp.Substring($i,3) % 255,2).PadLeft(8,'0')
}
<# Password end #>

function saltshaker() {
     param (
        [Parameter(Mandatory = $true)] [string]$block,
        [Parameter(Mandatory = $true)] [int]$rotations,
        [Parameter(Mandatory = $true)] [byte]$debugging
    )

    if($debugging -eq 1){Write-Host ('Password salted:  ' + ($password_salted).Substring(0,128) + '...')} # Salt is way too long to display

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

    if($debugging -eq 1){Write-Host ('UTF-8 encoded:    ' + $blocks_encoded)}
    <# UTF-8 encode into 16 byte blocks end #>

    <# Encrypt start #>
    $utf_binary = ''

    foreach($block in [System.Text.Encoding]::Default.GetBytes($blocks_encoded)) {
        $utf_binary += [System.Convert]::ToString($block,2).PadLeft(8,'0')
    }

    if($debugging -eq 1){Write-Host ('UTF-8 binary:     ' + $utf_binary -join ' ')}

    for($i = 0; $i -lt $rotations; $i++) {
        for($j = 0; $j -lt 128; $j++) {
            $utf_binary += $utf_binary.Substring($i * 128,128).Substring($j,1) -bxor $password_salted.Substring($i * 128,128).Substring($j,1)
        }
    }

    $utf_binary = $utf_binary.Substring($utf_binary.Length - 128,128)

    if($debugging -eq 1){Write-Host ('Encrypted binary: ' + $utf_binary)}
    <# Decrypt start #>
    for($i = 0; $i -lt $rotations; $i++) {
        for($j = 0; $j -lt 128; $j++) {
            $utf_binary += $utf_binary.Substring($i * 128,128).Substring($j,1) -bxor $password_salted.Substring($i * 128,128).Substring($j,1)
        }
    }

    $utf_binary = $utf_binary.Substring($utf_binary.Length - 128,128)
    $blocks_encoded = ''

    for($i = 0; $i -lt 16; $i++) {
        $blocks_encoded += [char][convert]::ToInt32($utf_binary.Substring($i * 8,8),2)
    }

    if($debugging -eq 1){Write-Host ('UTF-8 decoded:    ' + $blocks_encoded)}
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

    return $blocks_decoded
    <# UTF-8 decode end #>
}

<# String divided into 4 character blocks to be encrypted start #>
$data = "aaaaaaaaaaaaaaaaaæøå雨wxzQ"
$data_padding = ''
$blocks_decoded_array = @()
$blocks_decoded_string = ''

for($i = 0; $i -lt (4 - ($data.Length + 1) % 4) % 4; $i++) {
    $data_padding += [char](Get-Random -Minimum 32 -Maximum 126)
}

$data = ((4 - ($data.Length + 1) % 4) % 4).ToString() + $data + $data_padding # First byte counts how many padded characters has been added to the final block

for($i = 0; $i -lt $data.Length / 4; $i++) {
    $blocks_decoded_array += saltshaker $data.Substring($i * 4,4) ($i / 4 % 5) 1
}

for($i = 0; $i -lt $blocks_decoded_array.Count; $i++) {
    $blocks_decoded_string += $blocks_decoded_array[$i]
}

Write-Host ('Decrypted:        ' + $blocks_decoded_string.Substring(1, $blocks_decoded_string.Length - ([int]$blocks_decoded_string.Substring(0,1) + 1)))
<# String divided into 4 character blocks to be encrypted end #>
