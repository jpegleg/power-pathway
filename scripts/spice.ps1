Get-Content ./files.json -Raw |
    ConvertFrom-Json |
    ForEach-Object -Parallel {
        $path = $_.target
        $signature = $_.sig_path
        $key_path = $_.key_path
        $pub_path = $_.pub_path
        if (Test-Path $path) {
            "$path => file found, processing..."
            $rdir = (uidgen)
            mkdir $rdir
            cd $rdir
            wormsign-confgen $path $pub_path $signature $key_path
            wormsign -ats
        } else {
            "$path => file not found, skipping..."
        }
    } -ThrottleLimit 200
