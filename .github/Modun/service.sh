#!/system/bin/sh
MODDIR=${0%/*}

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
sleep 5

PKG="com.google.android.youtube"
CUSTOM_DIR="$MODDIR/custom"
MOD_APK="$CUSTOM_DIR/YouTube.apk"
SQLITE_BIN="$CUSTOM_DIR/sqlite3"
BASE_PATH=$(pm path "$PKG" | grep "base.apk" | cut -d: -f2)

umount -l "$BASE_PATH" 2>/dev/null

if [ -n "$BASE_PATH" ] && [ -f "$MOD_APK" ]; then
    chcon u:object_r:apk_data_file:s0 "$MOD_APK"
    chmod 644 "$MOD_APK"
    mount -o bind "$MOD_APK" "$BASE_PATH"
    am force-stop "$PKG"
fi

if [ -x "$SQLITE_BIN" ]; then
    SQLITE="$SQLITE_BIN"
elif command -v sqlite3 >/dev/null 2>&1; then
    SQLITE="sqlite3"
else
    SQLITE=""
fi

PLAY_DB="/data/data/com.android.vending/databases/library.db"
if [ -n "$SQLITE" ] && [ -f "$PLAY_DB" ]; then
    am force-stop com.android.vending
    "$SQLITE" "$PLAY_DB" "UPDATE ownership SET library_id = 'u-wl' WHERE doc_id = '$PKG';" 2>/dev/null
    "$SQLITE" "$PLAY_DB" "UPDATE ownership SET library_id = 'u-wl' WHERE doc_id = '$PKG' AND library_id = '3';" 2>/dev/null
fi

pm disable-user --user 0 com.android.vending/com.google.android.finsky.scheduler.process.mainimpl.PhoneskyJobServiceScheduler 2>/dev/null
