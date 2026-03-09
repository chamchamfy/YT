UA="Mozilla/5.0 (Linux; Android 14; Mobile)"
Xem() { curl -sLNG -A "$UA" --connect-timeout 20 "$1"; }
Taive() { curl -sLk -A "$UA" --connect-timeout 20 "$1" -o "$2"; }
# load dữ liệu 
lib1="lib/morphe-cli.jar"
lib2="lib/morphe-patches.jar"
# tải patch ổn định
pbsta() {
PV1=$(Xem https://github.com/MorpheApp/$1 | grep -om1 "MorpheApp/$1/releases/tag/.*\"" | sed -e 's|/v|/|g' -e 's|\"||g')
PV2="https://github.com/MorpheApp/$1/releases/download/v${PV1##*/}/$2-${PV1##*/}$4.$3"
echo "-Url: $PV2"
Taive "$PV2" "lib/$1.jar";
}
# tải patch dev
pbdev() {
PV1="$(Xem https://github.com/MorpheApp/$1/releases | grep -om1 "MorpheApp/$1/releases/tag/.*dev" | cut -d '"' -f1 | sed -e 's|/v|/|g' -e 's|\"||g')"
PV2="https://github.com/MorpheApp/$1/releases/download/v${PV1##*/}/$2-${PV1##*/}$4.$3"
echo "- Url: $PV2"
Taive "$PV2" "lib/$1.jar"; 
}

# tải apk
TaiYT() {
LT="https://www.apkmirror.com"
L1="$LT$(wget -q -U "$UA" "$LT/apk/$2" -O - | grep -m1 'downloadButton' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2)"
L2="$LT$(wget -q -U "$UA" "$L1" -O - | grep -m1 '>here<' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2 | sed 's|amp;||')"
wget -q -U "$UA" "$L2" -O "apk/$1"
#L1="$LT$(Xem "$LT/apk/$2" | grep -m1 'downloadButton' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2)"
#L2="$LT$(Xem "$L1" | grep -m1 '>here<' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2 | sed 's|amp;||')"
#Taive "$L2" "apk/$1"
echo "Link: $L2"
file "apk/$1" | tee "apk/$1.txt";
}

# Load dữ liệu cài đặt: . $HOME/.github/
#Ton=' -e "feature"'
Tof=' -d "Custom branding" -d "Custom branding icon YouTube" -d "Custom branding icon for YouTube" '

# là amoled
[ "$AMOLED" == 'true' ] && amoled2='-Amoled'
[ "$AMOLED" == 'true' ] || theme='-d Theme'
[ "$TYPE" == 'true' ] && Mro='-d "GmsCore support"'

# Xoá lib dựa vào abi
if [ "$DEVICE" == "arm64-v8a" ]; then
lib="lib/x86/* lib/x86_64/* lib/armeabi-v7a/*"
ach="arm64"
elif [ "$DEVICE" == "x86" ]; then
lib="lib/x86_64/* lib/arm64-v8a/* lib/armeabi-v7a/*"
ach="x86"
elif [ "$DEVICE" == "x86_64" ]; then
lib="lib/x86/* lib/arm64-v8a/* lib/armeabi-v7a/*"
ach="x64"
else
lib="lib/arm64-v8a/* lib/x86/* lib/x86_64/*"
ach="arm"
fi

echo
# Tải tool cli
echo "- Tải tool cli, patches, integrations..."
if [ "$DEV" == "Develop" ]; then
echo "  Dùng Dev"
pbdev morphe-cli morphe-cli jar -all
pbdev morphe-patches patches mpp

else
echo "  Dùng Sta"
pbsta morphe-cli morphe-cli jar -all
pbsta morphe-patches patches mpp
fi

# kiểm tra tải tool
checkzip "$lib1"
checkzip "$lib2"
echo

# lấy dữ liệu phiên bản mặc định
#[0] = lấy số đầu, [-1] = lấy số cuối
Vidon=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages."com.google.android.youtube"[0]')

echo "     $Vidon"
if [ "$VERSION" == 'New' ]; then
VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
Kad=Build
V=V
elif [ "$VERSION" == 'Auto' ]; then
VER=$Vidon
[ -z "$Vidon" ] && VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
V=U
else
Vidon="$VERSION"
VER="$VERSION"
Kad=Edit
V=N
fi


Upenv V "$V"
Upenv Kad "$Kad"
Upenv VER "$VER"

if [[ "$VERSION" == 'Auto' ]] && [[ "$(Xem https://github.com/$GITHUB_REPOSITORY/releases/download/Up/Up-X${V}notes.json | grep -cm1 "${VER//./}")" == 1 ]]; then
echo "! Là phiên bản mới nhất."
#gh run cancel $GITHUB_RUN_ID
#sleep 10
#exit 0
fi

echo "- Tải YouTube $VER apk, apks..."
# Tải YouTube apk
kkk1="google-inc/youtube/youtube-${VER//./-}-release/youtube-${VER//./-}-2-android-apk-download"
kkk2="google-inc/youtube/youtube-${VER//./-}-release/youtube-${VER//./-}-android-apk-download"

# Tải
TaiYT 'YouTube1' "$kkk1" & TaiYT 'YouTube2' "$kkk2"

# Chờ tải xong
Loading apk/YouTube1.txt apk/YouTube2.txt

# Xem xét apk
[ -z "$(hexdump -n 2 apk/YouTube1 | grep '4b50')" ] && rm -rf apk/YouTube1
[ -z "$(hexdump -n 2 apk/YouTube2 | grep '4b50')" ] && rm -rf apk/YouTube2

if [ -f apk/YouTube1 ]; then
 if [ "$(unzip -l apk/YouTube1 | grep -cm1 'base.apk')" == 1 ]; then
 echo "- apk1 thành apks."
 mv apk/YouTube1 apk/YouTube.apks
 else 
 echo "- apk1 thành apk."
 mv apk/YouTube1 apk/YouTube.apk
 fi
else
echo "- không có file apk1"
fi

if [ -f apk/YouTube2 ]; then
 if [ "$(unzip -l apk/YouTube2 | grep -cm1 'base.apk')" == 1 ]; then
 echo "- apk2 thành apks."
 mv apk/YouTube2 apk/YouTube.apks
 else
 echo "- apk2 thành apk."
 mv apk/YouTube2 apk/YouTube.apk
 fi
else
echo "- không có file apk2"
fi


if [ "$TYPE" == 'true' ]; then
[ -f apk/YouTube.apks ] && echo "- Giải nén base.apk" && unzip -qo apk/YouTube.apks 'base.apk' "split_config.${DEVICE//-/_}.apk" split_config.xxhdpi.apk -d Tav
[ -f apk/YouTube.apk ] && echo "- Giải nén Lib" && cp apk/YouTube.apk Tav/base.apk && unzip -qo apk/YouTube.apk lib/$DEVICE/* -d tmp
fi

# Copy 
echo > $HOME/.github/Modun/common/$ach
cp -rf $HOME/.github/Tools/sqlite3_$ach $HOME/.github/Modun/common/sqlite3

echo "- Xoá lib thừa."
zip -qr apk/YouTube.apk -d $lib

# Xử lý morphe patches
if [ "$Vidon" != "$VER" ]; then
echo "- Chuyển đổi phiên bản $VER"
unzip -qo "$lib2" -d $HOME/jar
for vak in $(grep -Rl "$Vidon" $HOME/jar); do
cp -rf $vak test
XHex test | sed -e "s/$(echo -n "$Vidon" | XHex)/$(echo -n "$VER" | XHex)/" | ZHex > $vak
done
cd $HOME/jar
rm -fr $lib2
zip -qr "$HOME/$lib2" *
cd $HOME
fi

# MOD YouTube 
echo "▼ Bắt đầu quá trình xây dựng..."
eval "java -Djava.io.tmpdir=$HOME -jar $lib1 patch -p $lib2 apk/YouTube.apk -o YT.apk "$Tof $Ton $Mro $theme $feature""
echo '- Quá trình xây dựng apk xong.'
echo

ls YT-temporary-files/*.apk
cp -rf YT-temporary-files/*.apk YT2.apk

if [ "$TYPE" == 'true' ]; then
echo "Tạo rsign..."
echo
mv YT.apk $HOME/Tav/YouTube.apk
cd tmp
zip -qr $HOME/YT2.apk *
cd $HOME
rsign Tav/base.apk YT2.apk $HOME/Up/MYT-$VER-$ach${amoled2}-rsign.apk
else
apksign YT.apk $HOME/Up/MYT-$VER-$ach${amoled2}.apk
ls Up
exit 0
fi
cd Tav
tar -cf - * | xz -9kz > $HOME/.github/Modun/common/lib.tar.xz
cd $HOME

# Tạo module.prop
echo 'id=YouTube
name=YouTube Morphe '$Kad'
author=chamchamfy
description=Build '$date', YouTube edited tool by Revanced mod added disable play store updates.
version='$VER'
versionCode='${VER//./}'
updateJson=https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-M'$V$ach$amoled2'.json
' > $HOME/.github/Modun/module.prop

# Tạo json
echo '{
"version": "'$VER'",
"versionCode": "'${VER//./}'",
"zipUrl": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/M'$V$VER'/MYT-Hybrid-'$VER'-'$ach$amoled2'.Zip",
"changelog": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-M'$V'notes.json"
}' > "Up-M$V$ach$amoled2.json"

echo -e 'Update '$date' \nYouTube: '$VER' \nVersion: '${VER//./}'\nAuto by chamchamfy' > Up-M${V}notes.json

# Tạo module magisk
cd $HOME/.github/Modun
zip -qr $HOME/Up/MYT-Hybrid-$VER-$ach$amoled2.zip *
cd $HOME
ls Up
