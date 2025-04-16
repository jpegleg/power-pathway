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
            mkdir $uidir_path 2>/dev/null
            cd $uidir_path
            cp fim_checksum.txt fim_checksum.txt__backup 2>/dev/null
            cp pub_checksum.txt pub_checksum.txt__backup 2>/dev/null
            cp sig_checksum.txt sig_checksum.txt__backup 2>/dev/null
            crown $path > fim_checksum.txt
            crown $pub_path > pub_checksum.txt
            crown $signature > sig_checksum.txt
            diff fim_checksum.txt fim_checksum.txt__backup >> fim_diff.log
            diff pub_checksum.txt pub_checksum.txt__backup >> fim_diff.log
            diff sig_checksum.txt sig_checksum.txt__backup >> fim_diff.log
        } else {
            "$path => file not found, skipping..."
        }
    } -ThrottleLimit 200
