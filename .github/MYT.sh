User="User-Agent: Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
UA="Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
Xem() { curl -sLNG -A "$UA" --connect-timeout 20 "$1"; }
Taive() { curl -sL -A "$UA" --connect-timeout 20 "$1" -o "$2"; }
# load dữ liệu 
lib1="lib/morphe-cli.jar"
lib2="lib/morphe-patches.jar"
# tải patch ổn định
R='MorpheApp'
pbsta() {
#PV1=$(Xem "https://github.com/$R/$1/releases" | grep "releases/tag/v" | grep -vm1 "\-dev" | awk -F'/v|"' '{print $7}')
PV1=$(Xem https://api.github.com/repos/$R/$1/releases/latest | grep -oPm1 '"tag_name":\s*"v\K[^"]+')
PV2="https://github.com/$R/$1/releases/download/v${PV1}/$2-${PV1}$4.$3"
echo "-Url: $PV2"
Taive "$PV2" "lib/$1.jar";
}
# tải patch dev
pbdev() {
#PV1=$(Xem https://github.com/$R/$1/releases | grep "releases/tag/v" | grep -m1 "\-dev" | awk -F'/v|"' '{print $7}')
PV1=$(Xem https://api.github.com/repos/$R/$1/releases | grep -oPm1 '"tag_name":\s*"v\K[^"]+' | grep -m1 "\-dev")
PV2="https://github.com/$R/$1/releases/download/v${PV1}/$2-${PV1}$4.$3"
echo "- Url: $PV2"
Taive "$PV2" "lib/$1.jar"; 
}

# tải apk
taiyt() {
LT="https://www.apkmirror.com"
( L1="$LT$(wget -q -U "$UA" "$LT/apk/$2" -O - | grep -m1 'downloadButton' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2)"
[ -n "$L1" ] && L2="$LT$(wget -q -U "$UA" "$L1" -O - | grep -m1 '>here<' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2 | sed 's|amp;||')"
echo "Link: $L2"
wget -q -U "$UA" "$L2" -O "apk/$1"; ) || (
L1="$LT$(Xem "$LT/apk/$2" | grep -m1 'downloadButton' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2)"
[ -n "$L1" ] && L2="$LT$(Xem "$L1" | grep -m1 '>here<' | tr ' ' '\n' | grep -m1 'href=' | cut -d \" -f2 | sed 's|amp;||')"
echo "Link: $L2"
Taive "$L2" "apk/$1"; )
file "apk/$1" | tee "apk/$1.txt";
}

# Load dữ liệu cài đặt: . $HOME/.github/
#Ton=' -e "feature"'
Tof=' -e "Disable Play Store updates" -e "Hide ads" -e "Copy video URL" -e "Double tap to seek" -e "Downloads" -e "Loop video" -e "Reload video" -e "Seekbar" -e "Swipe controls" -e "Change header" -e "Navigation bar" -e "Captions" -e "Ambient mode" -e "Miniplayer" -e "Exit fullscreen mode" -e "Open videos fullscreen" -e "Custom player overlay opacity" -e "Return YouTube Dislike" -e "Open Shorts in regular player" -e "SponsorBlock" -e "Spoof app version" -e "Alternative thumbnails" -e "Bypass image region restrictions" -e "Spoof device dimensions" -e "Bypass URL redirects" -e "Open links externally" -e "Sanitize sharing links" -e "Open system share sheet" -e "Video quality" -e "Playback speed" -e "Change start page" -d "Custom branding" -e "Video ads" -d "Override YouTube Music actions" -d "Shorts autoplay" -d "Disable layout updates" -d "Change form factor" '

# là amoled
[ "$AMOLED" == 'true' ] && amoled2='-Amoled'
[ "$AMOLED" == 'true' ] && theme='-e "Theme"' || theme='-d "Theme"'
[ "$TYPE" == 'true' ] && Mro='-d "GmsCore support" -d "Change package name"' || Mro='-e "GmsCore support" -e "Change package name"'

# Xoá lib dựa vào abi
if [ "$DEVICE" == "arm64-v8a" ]; then
lib="lib/x86/* lib/x86_64/* lib/armeabi-v7a/*"
libm="*x86* *x86_64* *armeabi_v7a*"
ach="arm64"
elif [ "$DEVICE" == "x86" ]; then
lib="lib/x86_64/* lib/arm64-v8a/* lib/armeabi-v7a/*"
libm="*x86_64* *arm64-v8a* *armeabi-v7a*"
ach="x86"
elif [ "$DEVICE" == "x86_64" ]; then
lib="lib/x86/* lib/arm64-v8a/* lib/armeabi-v7a/*"
libm="*x86* *arm64-v8a* *armeabi-v7a*"
ach="x64"
elif [ "$DEVICE" == "armeabi-v7a" ]; then
lib="lib/arm64-v8a/* lib/x86/* lib/x86_64/*"
libm="*arm64-v8a* *x86* *x86_64*"
ach="arm"
fi

echo
# Tải tool cli
echo "- Tải tool cli, patches, integrations..."
if [ "$DEV" == "Develop" ]; then
echo "  Dùng Dev"
pbdev morphe-cli morphe-cli jar -all
pbdev morphe-patches patches mpp
Vidon=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages[] | select(.packageName == "com.google.android.youtube") | .targets[] | select(.isExperimental == true) | .version' | head -n 1)

else
echo "  Dùng Stable"
pbsta morphe-cli morphe-cli jar -all
pbsta morphe-patches patches mpp
Vidon=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages[] | select(.packageName == "com.google.android.youtube") | .targets[] | select(.isExperimental == false) | .version' | head -n 1)
fi

echo
# Lấy phiên bản
#Vidon=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages[] | select(.packageName == "com.google.android.youtube") | .targets[0].version')
echo " Phiên bản: $Vidon"
if [ "$VERSION" == 'New' ]; then
VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
[ -z "$VER" ] && VER=$Vidon
Kad=Build
V=V
elif [ "$VERSION" == 'Auto' ]; then
VER=$Vidon
[ -z "$Vidon" ] && VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
Kad=Auto
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

if [[ "$VERSION" == 'Auto' ]] && [[ "$(Xem https://github.com/$GITHUB_REPOSITORY/releases/download/Up/Up-M${V}notes.json | grep -cm1 "${VER//./}")" == 1 ]]; then
echo "! Là phiên bản mới nhất."
#gh run cancel $GITHUB_RUN_ID
#sleep 10
#exit 0
fi

echo "- Tải YouTube $VER apk, apks..."
# Tải YouTube apk

for v in 0 -2 -4 -3; do 
 [ -f apk/YouTube.apkm -a -f apk/YouTube.apk ] && echo " - Đã tải apk và apkm" && break
 [ "$v" = "0" ] && v=${v//0/}
 yt="google-inc/youtube/youtube-${VER//./-}-release/youtube-${VER//./-}${v}-android-apk-download"
 echo " - Đang tải YouTube$v"
 find apk/ -type f -empty -delete
 taiyt "YouTube$v" "$yt"
 if [ -n "$(hexdump -n 2 "apk/YouTube$v" 2>/dev/null | grep '4b50')" ]; then
  if [ -n "$(unzip -l "apk/YouTube$v" 2>/dev/null | grep 'base.apk')" ]; then 
    mv -f "apk/YouTube$v" apk/YouTube.apkm && echo " - Xong .apkm"
  elif [ -n "$(unzip -l "apk/YouTube$v" 2>/dev/null | grep 'resources.arsc')" ]; then 
    mv -f "apk/YouTube$v" apk/YouTube.apk && echo " - Xong .apk"
  fi 
 else 
  rm -f "apk/YouTube$v" 2>/dev/null
 fi
done

ls apk/*.apk*

if [ "$TYPE" == 'true' ]; then
 if [ -f apk/YouTube.apk ]; then 
 echo "- Giải nén Lib" 
 cp apk/YouTube.apk Tav/base.apk 
 unzip -qo apk/YouTube.apk lib/$DEVICE/* -d tmp
 fi
 if [ -f apk/YouTube.apkm ]; then 
 echo "- Giải nén base.apk" 
 unzip -qo apk/YouTube.apkm 'base.apk' "split_config.${DEVICE//-/_}.apk" split_config.xxhdpi.apk split_config.vi.apk -d Tav
 fi
fi

# Copy 
echo > $HOME/.github/Modun/common/$ach
cp -rf $HOME/.github/Tools/sqlite3_$ach $HOME/.github/Modun/common/sqlite3

if [ -f apk/YouTube.apk ]; then 
echo "- Xoá lib thừa."
tapk='apk/YouTube.apk'
apkeditor d -t sig -i "$tapk" -sig "signatures_dir" &>/dev/null 
zip -qr $tapk -d $lib
fi
if [ -f apk/YouTube.apkm ]; then
echo "- Xoá lib thừa."
tapk='apk/YouTube.apkm'
zip -qr $tapk -d $libm
fi

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
echo
tenapk=$(ls $PWD/apk/*.apk 2>/dev/null) || tenapk=$(ls $PWD/apk/*.apkm 2>/dev/null)
eval "java -Djava.io.tmpdir=$HOME -jar $lib1 patch -p $lib2 $tapk -o YT.apk "$Tof $Ton $Mro $theme $feature""
echo '- Quá trình xây dựng apk xong.'
echo

cp -rf *-temporary-files/*.apk YT2.apk 2>/dev/null || cp -rf lib/*/tmp/*.apk YT2.apk 2>/dev/null

# Chờ xây dựng xong
if [ "$TYPE" == 'true' ]; then
echo "Tạo rsign..."
mv YT.apk $HOME/Tav/YouTube.apk
[ "$(ls -A tmp 2>/dev/null)" ] && cd tmp && zip -qr $HOME/YT2.apk *
cd $HOME
[ -f Tav/base.apk ] && apkeditor d -t sig -i "Tav/base.apk" -sig "signatures_dir" &>/dev/null && apkeditor b -t sig -i YT2.apk -sig "$PWD/signatures_dir" -o "$HOME/Up/MYT-$VER-$ach${amoled2}-rsign.apk" &>/dev/null
else
#apksign YT.apk $HOME/Up/MYT-$VER-$ach${amoled2}.apk
cp -rf YT.apk $HOME/Up/MYT-$VER-$ach${amoled2}.apk
ls Up
exit 0
fi

cd Tav && tar -cf - * | xz -9kz > $HOME/.github/Modun/common/lib.tar.xz
cd $HOME

# Tạo module.prop
echo 'id=YouTube
name=YouTube Morphe '$Kad'
author=chamchamfy
description=Build '$date', YouTube edited tool by Morphe mod added disable play store updates.
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
