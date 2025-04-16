Get-Content ./files.json -Raw |
    ConvertFrom-Json |
    ForEach-Object -Parallel {
        $path = $_.target
        $signature = $_.sig_path
        $key_path = $_.key_path
        $pub_path = $_.pub_path
        $uidir_path = $_.uid_path
        if (Test-Path $path) {
            "$path => file found, processing..."
            cd $uidir_path
            wormsign -av > verify.json
        } else {
            "$path => file not found, skipping..."
        }
    } -ThrottleLimit 200
