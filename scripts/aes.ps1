param (
    [Parameter(Mandatory=$true)]
    [string]$TargetFile,

    [Parameter(Mandatory=$true)]
    [string]$EncryptedFile,

    [string]$DecryptedFile = "$TargetFile.dec",

    [string]$KeyFile = "aes_key.bin",

    [string]$ProtectedKeyFile = "aes_key.bin.e",

    [Parameter(Mandatory=$true)]
    [string]$ScriptMode
)

function Get-Password {
    Read-Host "Enter password" -AsSecureString | ForEach-Object {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($_)
        [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
}

function Protect-AESKey {
    param (
        [string]$keyFile = "aes_key.bin",
        [string]$protectedFile = "aes_key.bin.e"
    )

    $password = Get-Password
    $salt = [byte[]]::new(16)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)

    $keyDeriver = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($password, $salt, 100000)
    $derivedKey = $keyDeriver.GetBytes(32)

    $iv = [byte[]]::new(16)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($iv)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = "CBC"
    $aes.Padding = "PKCS7"
    $aes.Key = $derivedKey
    $aes.IV = $iv

    $encryptor = $aes.CreateEncryptor()
    $plainKey = [System.IO.File]::ReadAllBytes($keyFile)
    if ($plainKey.Length -ne 32) {
        throw "AES key must be exactly 32 bytes (256 bits)."
    }

    $mem = New-Object System.IO.MemoryStream
    $crypto = New-Object System.Security.Cryptography.CryptoStream($mem, $encryptor, 'Write')
    $crypto.Write($plainKey, 0, $plainKey.Length)
    $crypto.Close()

    $payload = $salt + $iv + $mem.ToArray()
    [System.IO.File]::WriteAllBytes($protectedFile, $payload)

    Write-Output "Protected AES key saved to $protectedFile"
}

function Unprotect-AESKey {
    param (
        [string]$protectedFile = "aes_key.bin.e"
    )

    $password = Get-Password
    $payload = [System.IO.File]::ReadAllBytes($protectedFile)

    if ($payload.Length -lt 48) {
        throw "Protected file is too short to contain salt, IV, and ciphertext."
    }

    $salt = $payload[0..15]
    $iv   = $payload[16..31]
    $cipherKey = $payload[32..($payload.Length - 1)]

    $keyDeriver = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($password, $salt, 100000)
    $derivedKey = $keyDeriver.GetBytes(32)

    if ($null -eq $derivedKey -or $derivedKey.Length -ne 32) {
        throw "Derived key is null or not 256 bits."
    }

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = "CBC"
    $aes.Padding = "PKCS7"
    $aes.KeySize = 256
    $aes.Key = $derivedKey
    $aes.IV = $iv

    $decryptor = $aes.CreateDecryptor()
    $mem = New-Object System.IO.MemoryStream(,$cipherKey)
    $crypto = New-Object System.Security.Cryptography.CryptoStream($mem, $decryptor, 'Read')
    $reader = New-Object System.IO.MemoryStream
    $crypto.CopyTo($reader)
    $crypto.Close()

    $decryptedKey = $reader.ToArray()
    if ($decryptedKey.Length -ne 32) {
        throw "Decrypted AES key is not 256 bits (32 bytes)."
    }

    return $decryptedKey
}

function Encrypt-File {
    param (
        [string]$inputPath,
        [string]$outputPath,
        [byte[]]$key
    )

    try {
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256
        $aes.Mode = "CBC"
        $aes.Padding = "PKCS7"
        $aes.Key = $key
        $aes.GenerateIV()
        $iv = $aes.IV

        $encryptor = $aes.CreateEncryptor()
        $inputBytes = [System.IO.File]::ReadAllBytes($inputPath)

        $memoryStream = New-Object System.IO.MemoryStream
        $memoryStream.Write($iv, 0, $iv.Length)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $encryptor, 'Write')
        $cryptoStream.Write($inputBytes, 0, $inputBytes.Length)
        $cryptoStream.Close()

        [System.IO.File]::WriteAllBytes($outputPath, $memoryStream.ToArray())
        Write-Output "Encrypted '$inputPath' to '$outputPath'."

    }

    catch {
        Write-Error "ERROR - Encryption failed for '$inputPath': $_"
    }
}

function Decrypt-File {
    param (
        [string]$inputPath,
        [string]$outputPath,
        [byte[]]$key
    )

    try {
        $inputBytes = [System.IO.File]::ReadAllBytes($inputPath)
        $iv = $inputBytes[0..15]
        $cipherBytes = $inputBytes[16..($inputBytes.Length - 1)]

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256
        $aes.Mode = "CBC"
        $aes.Padding = "PKCS7"
        $aes.Key = $key
        $aes.IV = $iv

        $decryptor = $aes.CreateDecryptor()
        $cipherStream = [System.IO.MemoryStream]::new($cipherBytes)
        $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($cipherStream, $decryptor, 'Read')
        $reader = New-Object System.IO.MemoryStream
        $cryptoStream.CopyTo($reader)
        $cryptoStream.Close()

        [System.IO.File]::WriteAllBytes($outputPath, $reader.ToArray())
        Write-Output "Decrypted '$inputPath' to '$outputPath'."
    }

    catch {
        Write-Error "ERROR - Decryption failed for '$inputPath': $_"
    }
}

$keyFile = "aes_key.bin"
$protectedKeyFile = "aes_key.bin.e"

if (-not (Test-Path $ProtectedKeyFile)) {
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    [System.IO.File]::WriteAllBytes($KeyFile, $aes.Key)
    Write-Output "Generated new AES-256 key."
    Protect-AESKey -keyFile $KeyFile -protectedFile $ProtectedKeyFile
    Write-Output "Encrypted secret key."
}

if (-not (Test-Path $TargetFile)) {
    Write-Error "Target file '$TargetFile' does not exist."
    exit 1
}

try {
    $key = Unprotect-AESKey -protectedFile $ProtectedKeyFile
}
catch {
    Write-Error "ERROR - Key decryption failed!"
}

if ($ScriptMode -eq "encrypt") {
    Encrypt-File -inputPath $TargetFile -outputPath $EncryptedFile -key $key
} elseif ($ScriptMode -eq "decrypt") {
    Decrypt-File -inputPath $EncryptedFile -outputPath $DecryptedFile -key $key
} else {
    Write-Error "Set ScriptMode parameter to either encrypt or decrypt"
}
