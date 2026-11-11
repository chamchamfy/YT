#!/system/bin/sh
MODDIR=${0%/*}
PKG="com.google.android.youtube"
SQLITE_BIN="$MODDIR/custom/sqlite3"

BASE_PATH=$(pm path "$PKG" 2>/dev/null | grep "base.apk" | cut -d: -f2)
if [ -n "$BASE_PATH" ]; then
    umount -l "$BASE_PATH" 2>/dev/null
    am force-stop "$PKG"
fi

pm enable com.android.vending/com.google.android.finsky.scheduler.process.mainimpl.PhoneskyJobServiceScheduler 2>/dev/null

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
    "$SQLITE" "$PLAY_DB" "UPDATE ownership SET library_id = '3' WHERE doc_id = '$PKG' AND library_id = 'u-wl';" 2>/dev/null
fi
