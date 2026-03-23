#!/bin/bash -x
UA="Mozilla/5.0 (Linux; Android 14; Mobile)"
Xem() { curl -sLNG -A "$UA" --connect-timeout 20 "$1"; }
Taive() { curl -sLk -A "$UA" --connect-timeout 20 "$1" -o "$2"; }

# load dữ liệu 
lib1="lib/revanced-cli.jar"
lib2="lib/revanced-patches.jar"
# tải patch ổn định
pbsta() {
PV1="$(Xem https://github.com/ReVanced/$1 | grep -om1 "ReVanced/$1/releases/tag/.*\"" | sed -e 's|/v|/|g' -e 's|\"||g')"
PV2="https://github.com/ReVanced/$1/releases/download/v${PV1##*/}/$2-${PV1##*/}$4.$3"
echo "- Url: $PV2"
Taive "$PV2" "lib/$1.jar"; 
}
# tải patch dev
pbdev() {
PV1="$(Xem https://github.com/ReVanced/$1/releases | grep -om1 "ReVanced/$1/releases/tag/.*dev" | cut -d '"' -f1 | sed -e 's|/v|/|g' -e 's|\"||g')"
PV2="https://github.com/ReVanced/$1/releases/download/v${PV1##*/}/$2-${PV1##*/}$4.$3"
echo "- Url: $PV2"
Taive "$PV2" "lib/$1.jar"; 
}

# tải json
if [ "$DEV" == "Develop" ]; then
Vop='-DEV'
Vop2=D
fi

# tải apk
taiyt() {
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
Tof='-d "Custom branding"'

# là amoled
[ "$AMOLED" == 'true' ] && amoled2='-Amoled'
[ "$AMOLED" == 'true' ] || theme='-d "Theme"'
[ "$TYPE" == 'true' ] && Mro='-d "GmsCore support"'

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
else
lib="lib/arm64-v8a/* lib/x86/* lib/x86_64/*"
libm="*arm64-v8a* *x86* *x86_64*"
ach="arm"
fi
echo
# Tải tool cli
echo "- Tải tool cli, patches, integrations..."
if [ "$DEV" == "Develop" ]; then
echo "  Dùng Dev"
pbdev revanced-cli revanced-cli jar -all
pbdev revanced-patches patches rvp
else
echo "  Dùng Sta"
pbsta revanced-cli revanced-cli jar -all
pbsta revanced-patches patches rvp
fi

# kiểm tra tải tool
#checkzip "$lib1"
#checkzip "$lib2"
echo

# kiểm tra phiên bản 
Vidon=$(Xem https://raw.githubusercontent.com/ReVanced/revanced-patches/main/patches/src/main/kotlin/app/revanced/patches/youtube/ad/general/HideAdsPatch.kt | awk -F'"' '/com.google.android.youtube/,/\)/ { print $2 }' | grep -E '^[0-9.]+$' | tail -n1)
echo "  $Vidon"
if [ "$VERSION" == 'New' ]; then
VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m 1 -oP '(?<=YouTube )[\d.]+')
[ -z "$VER" ] && VER=$Vidon
Kad=Build$Vop
V=V$Vop2
elif [ "$VERSION" == 'Auto' ]; then
VER=$Vidon
[ -z "$Vidon" ] && VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m 1 -oP '(?<=YouTube )[\d.]+')
Kad=Auto$Vop
V=U$Vop2
else
Vidon="$VERSION"
VER="$VERSION"
Kad=Edit$Vop
V=N$Vop2
fi

Upenv V "$V"
Upenv Kad "$Kad"
Upenv VER "$VER"

if [[ "$VERSION" == 'Auto' ]] && [[ "$(Xem https://github.com/$GITHUB_REPOSITORY/releases/download/Up/Up-K${V}notes.json | grep -cm1 "${VER//./}")" == 1 ]]; then
echo "! Là phiên bản mới nhất."
#gh run cancel $GITHUB_RUN_ID
#sleep 10
#exit 0
fi

echo "- Tải YouTube $VER apk, apks..."
# Tải YouTube apk

for v in -2 0 -4 -3; do 
 [ -f apk/YouTube.apkm -a -f apk/YouTube.apk ] && echo " - Đã tải apk và apkm" && break
 [ "$v" = "0" ] && v=${v//0/}
 yt="google-inc/youtube/youtube-${VER//./-}-release/youtube-${VER//./-}${v}-android-apk-download"
 echo " - Đang tải YouTube$v"
 taiyt "YouTube$v" "$yt"
 if [ -n "$(hexdump -n 2 "apk/YouTube$v" | grep '4b50')" ]; then 
  [ -n "$(unzip -l apk/YouTube$v | grep 'base.apk')" ] &&  mv -f apk/YouTube$v apk/YouTube.apkm && echo "- Xong .apkm"
  [ -n "$(unzip -l apk/YouTube$v | grep 'resources.arsc')" ] && mv -f apk/YouTube$v apk/YouTube.apk && echo "- Xong .apk"
 else 
  rm -f apk/YouTube$v
 fi 
done

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
apkeditor d -t sig -i "$tapk" -sig "tmp/signatures_dir" &>/dev/null 
zip -qr $tapk -d $lib
else 
tapk='apk/YouTube.apkm'
apkeditor d -t sig -i "$tapk" -sig "tmp/signatures_dir" &>/dev/null
zip -qr $tapk -d $libm
fi

# Xử lý revanced patches
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
eval "java -Djava.io.tmpdir=$HOME -jar $lib1 patch -b -p $lib2 apk/YouTube.apk -o YT.apk "$Mro $theme $Tof $Ton $feature""
echo '- Quá trình xây dựng apk xong.'
echo

ls YT-temporary-files/*.apk
cp -rf YT-temporary-files/*.apk YT2.apk

# Chờ xây dựng xong
if [ "$TYPE" == 'true' ]; then
echo "Tạo rsign..."
mv YT.apk $HOME/Tav/YouTube.apk
[ "$(ls -A tmp 2>/dev/null)" ] && cd tmp && zip -qr $HOME/YT2.apk *
cd $HOME
[ -f Tav/base.apk ] && rsign Tav/base.apk YT2.apk $HOME/Up/YT-$VER-$ach${amoled2}-rsign.apk || apkeditor b -t sig -i YT2.apk -sig "tmp/signatures_dir" -o "$HOME/Up/YT-$VER-$ach${amoled2}-rsign.apk" &>/dev/null
else
#apksign YT.apk $HOME/Up/YT-$VER-$ach${amoled2}.apk
cp -rf YT.apk $HOME/Up/YT-$VER-$ach${amoled2}.apk
ls Up
exit 0
fi

cd Tav
tar -cf - * | xz -9kz > $HOME/.github/Modun/common/lib.tar.xz
cd $HOME

# Tạo module.prop
echo 'id=YouTube
name=YouTube '$Kad'
author=chamchamfy
description=Build '$date', YouTube edited tool by Revanced mod added disable play store updates.
version='$VER'
versionCode='${VER//./}'
updateJson=https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-K'$V$ach$amoled2'.json
' > $HOME/.github/Modun/module.prop

# Tạo json
echo '{
"version": "'$VER'",
"versionCode": "'${VER//./}'",
"zipUrl": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/K'$V$VER'/YT-Hybrid-'$VER'-'$ach$amoled2'.Zip",
"changelog": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-K'$V'notes.json"
}' > Up-K$V$ach$amoled2.json

echo -e 'Update '$date' \nYouTube: '$VER' \nVersion: '${VER//./}' \nAuto by chamchamfy' > Up-K${V}notes.json

# Tạo module magisk
cd $HOME/.github/Modun
zip -qr $HOME/Up/YT-Hybrid-$VER-$ach$amoled2.zip *
cd $HOME
ls Up
