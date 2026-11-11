#!/system/bin/sh

PKG="com.google.android.youtube"
ARCHIVE="$MODPATH/lib.tar.xz"
CUSTOM_DIR="$MODPATH/custom"
MOD_APK="$CUSTOM_DIR/YouTube.apk"
SQLITE_BIN="$CUSTOM_DIR/sqlite3"

ui_print "- Đang gỡ bỏ mount cũ (nếu có)..."
OLD_PATH=$(pm path "$PKG" 2>/dev/null | grep "base.apk" | cut -d: -f2)
[ -n "$OLD_PATH" ] && umount -l "$OLD_PATH" 2>/dev/null

if [ ! -f "$ARCHIVE" ]; then
    abort "! Lỗi: Không tìm thấy file lib.tar.xz trong module!"
fi

ui_print "- Đang giải nén lib.tar.xz ..."
mkdir -p "$CUSTOM_DIR"
for BB in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -x "$BB" ]; then
        alias tar="$BB tar"
        break
    fi
done
tar -xJf "$ARCHIVE" -C "$CUSTOM_DIR" || abort "! Giải nén lib.tar.xz thất bại!"

rm -f "$ARCHIVE"

if [ ! -f "$MOD_APK" ] || [ ! -f "$CUSTOM_DIR/base.apk" ]; then
    abort "! Lỗi: Thiếu file YouTube.apk hoặc base.apk bên trong lib.tar.xz!"
fi

if [ -f "$SQLITE_BIN" ]; then
    chmod 755 "$SQLITE_BIN"
    chown 0:0 "$SQLITE_BIN"
    chcon u:object_r:system_file:s0 "$SQLITE_BIN" 2>/dev/null
fi

install_splits() {
    SESSION_ID=$(pm install-create -r -d | grep -oE '[0-9]+')
    [ -z "$SESSION_ID" ] && return 1

    INDEX=0
    for APK in "$CUSTOM_DIR"/*.apk; do
        FILENAME=$(basename "$APK")
        if [ "$FILENAME" = "YouTube.apk" ]; then
            continue
        fi
        
        SIZE=$(wc -c < "$APK")
        pm install-write -S "$SIZE" "$SESSION_ID" "split_${INDEX}.apk" "$APK" >/dev/null 2>&1 || return 1
        INDEX=$((INDEX + 1))
    done

    pm install-commit "$SESSION_ID" >/dev/null 2>&1
    return $?
}

ui_print "- Đang cài đặt YouTube..."
install_splits

if [ $? -ne 0 ]; then
    ui_print "! Xung đột phiên bản, đang gỡ cập nhật hiện tại để cài lại..."
    pm uninstall "$PKG" >/dev/null 2>&1
    install_splits || abort "! Cài đặt YouTube gốc thất bại!"
fi

for APK in "$CUSTOM_DIR"/*.apk; do
    FILENAME=$(basename "$APK")
    if [ "$FILENAME" != "YouTube.apk" ]; then
        rm -f "$APK"
    fi
done

ui_print "- Cài đặt xong!."
