#!/usr/bin/env bash
set -euo pipefail

#######################################
# Fetch android id from an existing android os with roblox installed

# Android 11 or less
# adb -s 127.0.0.1:5555 shell cat /data/system/users/0/settings_ssaid.xml

# Android 12+
# adb -s 127.0.0.1:55513 shell su -mm -c "abx2xml /data/system/users/0/settings_ssaid.xml - | grep -n com.domain.name || true"

#######################################

#######################################
# CONFIG — EDIT HERE ONLY
#######################################
SSAID="49b5b3fffef56111"
DEVICES=(
    "127.0.0.1:55513"
)

IN="/data/system/users/0/settings_ssaid.xml"
TMP="/data/local/tmp/settings_ssaid.xml"

for SERIAL in "${DEVICES[@]}"; do
  echo "========================================"
  echo "[$SERIAL] Setting APP SSAID = $SSAID"
  echo "========================================"

  adb -s "$SERIAL" shell su -mm -c "set -e
VAL=$SSAID

# sanity
test -f $IN

# ABX -> XML
abx2xml $IN $TMP

sed -i '/package=\"com\.domain\.nae\"/ {
  s/value=\"[^\"]*\"/value=\"'"\"\$VAL\""'\"/;
  s/defaultValue=\"[^\"]*\"/defaultValue=\"'"\"\$VAL\""'\"/;
}' $TMP

# XML -> ABX overwrite
xml2abx $TMP $IN
chown system:system $IN
chmod 600 $IN
restorecon $IN 2>/dev/null || true
sync

# verify (value or defaultValue)
LINE=\$(abx2xml $IN - | grep 'package=\"com\.roblox\.client\"' || true)
echo \"VERIFY: \$LINE\"
echo \"\$LINE\" | grep -q \"value=\\\"$SSAID\\\"\" || echo \"\$LINE\" | grep -q \"defaultValue=\\\"$SSAID\\\"\"

# restart roblox
am force-stop com.domain.name 2>/dev/null || true
echo OK"
done

echo "🎉 Done"