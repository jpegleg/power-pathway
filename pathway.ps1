if ( stat ~/.config/powershell ) {
    echo "PowerShell config directory found..."
} else { 
    echo "Creating PowerShell config directory..."
    mkdir ~/.config/powershell
}

echo "Copying prompt file to PowerShell config dir..."
cp Microsoft.PowerShell_profile.ps1 /root/.config/powershell/

if ( stat /usr/local/bin/wormsign ) {
    echo "wormsign found..."
} else { 
    echo "compiling wormsign..."
    git clone https://github.com/jpegleg/wormsign
    cd wormsign
    cargo build --release
    cp target/release/wormsign /usr/local/bin/
    cd ..
}

if ( stat /usr/local/bin/AES256CTR ) {
    echo "AES256CTR found..."
} else { 
    echo "compiling AES256CTR..."
    git clone https://github.com/jpegleg/file_encryption_AES256
    cd file_encryption_AES256/rust
    cargo build --release
    cp target/release/AES256CTR /usr/local/bin/
    cd ..
}
