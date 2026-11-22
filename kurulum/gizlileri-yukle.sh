#!/bin/bash
# GitHub Actions gizlilerini bir kez yükler (212.95.56.17 sunucusunda çalıştırılır; değerler ekrana basılmaz).
# Kullanım: bash kurulum/gizlileri-yukle.sh
# Jeton: /root/.config/bogahost/gh-token-bambumpos — depoya Secrets (write) erişimi olmalı.
set -e
D=/root/.config/bambumpos; C=/root/.config/bogahost-chat-apps; P=/opt/cpanel/ea-php83/root/usr/bin/php
cd $D
for g in "ASC_KEY_P8 AuthKey_5Z9AN85989.p8" "IOS_P12_B64 ios-imza/dagitim.p12 b64" "IOS_P12_PASS ios-imza/p12.sifre" \
         "MAC_APP_P12_B64 mac-imza/app.p12 b64" "MAC_INST_P12_B64 mac-imza/inst.p12 b64" "MAC_P12_PASS mac-imza/p12.sifre" \
         "ANDROID_KEYSTORE_B64 android-imza.p12 b64" "ANDROID_KEYSTORE_PASS android-imza.parola"; do
  # shellcheck disable=SC2086
  $P $C/gh_secret.php $g
done
