$PWord = Read-Host -Prompt 'Enter AES256CTR password' -AsSecureString
$ptr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PWord)
$pass  = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

$Env:TEMPAESP = $pass

Get-Content ./crypt.json -Raw |
    ConvertFrom-Json |
    ForEach-Object -Parallel {
        $path = $_.target
        $sample = $_.sample
        $cipher = $_.destination
        if (Test-Path $path) {
            "$path => file found, processing..."
            AES256CTR $path $cipher $sample -ae
        } else {
            "$path => file not found, skipping..."
        }
    } -ThrottleLimit 10

$env:TMPAESP = $null
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
