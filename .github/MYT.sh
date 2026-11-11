User="User-Agent: Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
UA="Mozilla/5.0 (Linux; Android 14; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.6998.39 Mobile Safari/537.36"
Xem() { curl -sLNG -A "$UA" --connect-timeout 20 "$1"; }
Taive() { curl -sL -A "$UA" --connect-timeout 20 "$1" -o "$2"; }
czip() { [ -n "$(unzip -t $1 | grep 'No errors')" ] && echo "FILE: ${1##*/} OK" || echo "- Lỗi file ${1##*/}"; }
lib1="lib/morphe-desktop.jar"
lib2="lib/morphe-patches.jar"
KN="$HOME/.github/Tools/cc.keystore"
KA="cc_alias"
KP="chamchamfy"
R='MorpheApp'
pbsta() {
PV1=$(Xem https://api.github.com/repos/$R/$1/releases/latest | grep -oPm1 '"tag_name":\s*"v\K[^"]+')
PV2="https://github.com/$R/$1/releases/download/v${PV1}/$2-${PV1}$4.$3"
echo "-Url: $PV2"
wget -q -U "$UA" "$PV2" -O "lib/$1.jar" || Taive "$PV2" "lib/$1.jar"
czip "lib/$1.jar";
}
pbdev() {
PV1=$(Xem https://api.github.com/repos/$R/$1/releases | grep -oPm1 '"tag_name":\s*"v\K[^"]+' | grep -m1 "\-dev")
PV2="https://github.com/$R/$1/releases/download/v${PV1}/$2-${PV1}$4.$3"
echo "- Url: $PV2"
wget -q -U "$UA" "$PV2" -O "lib/$1.jar" || Taive "$PV2" "lib/$1.jar"
czip "lib/$1.jar";
}
tapkm() {
PV1=$(Xem https://api.github.com/repos/tanishqmanuja/apkmirror-downloader/releases/latest | grep -oPm1 '"tag_name":\s*"v\K[^"]+')
PV2="https://github.com/tanishqmanuja/apkmirror-downloader/releases/download/v${PV1}/apkmd"
echo "-Tải APKMD: $PV2"
wget -q -U "$UA" "$PV2" -O "$HOME/.github/apkmd" || Taive "$PV2" "$HOME/.github/apkmd"
checkfile "$HOME/.github/apkmd"
chmod +x $HOME/.github/apkmd;
}

taiyt() {
local target_version="${1:-$VER}"
local save_dir="${2:-$LUU}"
if ! python3 -c "import curl_cffi, bs4" 2>/dev/null; then pip3 install --quiet --break-system-packages curl_cffi beautifulsoup4 >/dev/null 2>&1 || pip3 install --quiet curl_cffi beautifulsoup4 >/dev/null 2>&1 || { echo "❌ Lỗi cài đặt curl_cffi / beautifulsoup4"; return 1; }; fi
YT_VER="$target_version" YT_DIR="$save_dir" python3 - << 'EOF'
import os
import sys
import re
import time
import hashlib
import zipfile
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup
from curl_cffi import requests

target_version = os.environ.get("YT_VER", "").strip()
save_dir = os.environ.get("YT_DIR", ".").strip()
base_url = "https://www.apkmirror.com"
rss_url = f"{base_url}/apk/google-inc/youtube/feed/"

session = requests.Session(impersonate="chrome")

print(f"Đang tìm YouTube {target_version}...")
res_rss = session.get(rss_url)
release_url = None

if res_rss.status_code == 200:
    try:
        root = ET.fromstring(res_rss.text)
        for item in root.findall(".//item"):
            title_el = item.find("title")
            link_el = item.find("link")
            if title_el is not None and link_el is not None:
                if target_version in title_el.text:
                    release_url = link_el.text
                    break
    except Exception:
        pass

if not release_url:
    version_slug = target_version.replace(".", "-")
    release_url = f"{base_url}/apk/google-inc/youtube/youtube-{version_slug}-release/"

res_rel = session.get(release_url)
if res_rel.status_code != 200:
    print(f"❌ Không mở được trang phiên bản (Mã lỗi: {res_rel.status_code}).")
    sys.exit(1)

soup_rel = BeautifulSoup(res_rel.text, "html.parser")

targets = {"apk": None, "apkm": None}
fallback_targets = {"apk": None, "apkm": None}

for row in soup_rel.select("div.table-row"):
    row_text = row.get_text(" ", strip=True)
    link_tag = row.select_one("a.accent_color")
    if not link_tag or not link_tag.get("href"):
        continue

    href = link_tag["href"]
    if href.startswith("/"):
        href = base_url + href
    elif href.startswith("https://apkmirror.com"):
        href = href.replace("https://apkmirror.com", base_url, 1)

    ext = "apkm" if "BUNDLE" in row_text else "apk"

    if any(u in row_text.lower() for u in ["universal", "noarch"]):
        if not targets[ext]:
            targets[ext] = href
    elif "arm64-v8a" in row_text.lower():
        if not fallback_targets[ext]:
            fallback_targets[ext] = href

final_list = []
for ext in ["apk", "apkm"]:
    chosen_url = targets[ext] or fallback_targets[ext]
    if chosen_url:
        arch_label = "universal" if targets[ext] else "arm64-v8a"
        final_list.append((ext, arch_label, chosen_url))

if not final_list:
    print("❌ Không tìm thấy biến thể APK hay APKM nào phù hợp.")
    sys.exit(1)

print(f"✔ Tìm thấy {len(final_list)} định dạng: {', '.join(e.upper() for e, _, _ in final_list)}")

def get_sha256(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def extract_direct_link(html_text, dl_page_url):
    soup = BeautifulSoup(html_text, "html.parser")
    
    for tag in soup.find_all("a", href=True):
        href = tag["href"].replace("&amp;", "&")
        if "download.php" in href and "key=" in href:
            return href

    form = soup.find("form", action=re.compile(r"download\.php"))
    if form:
        id_input = form.find("input", {"name": "id"})
        key_input = form.find("input", {"name": "key"})
        if id_input and key_input and id_input.get("value") and key_input.get("value"):
            return f"/wp-content/themes/APKMirror/download.php?id={id_input['value']}&key={key_input['value']}"

    raw_match = re.search(r'(/wp-content/themes/APKMirror/download\.php\?id=[0-9]+&(?:amp;)?key=[a-zA-Z0-9_-]+)', html_text)
    if raw_match:
        return raw_match.group(1).replace("&amp;", "&")

    return None

def download_variant(ext, arch_label, variant_url):
    res_var = session.get(variant_url)
    soup_var = BeautifulSoup(res_var.text, "html.parser")

    expected_sha256 = None
    sha_match = re.search(r"SHA-256:\s*([a-fA-F0-9]{64})", soup_var.get_text())
    if sha_match:
        expected_sha256 = sha_match.group(1).lower()

    dl_btn = soup_var.select_one("a.downloadButton")
    if not dl_btn or not dl_btn.get("href"):
        dl_btn = soup_var.find("a", href=re.compile(r"/download/\?key="))

    if not dl_btn or not dl_btn.get("href"):
        print(f"❌ Không tìm thấy nút Download ({ext.upper()}).")
        return

    dl_page_url = dl_btn["href"].replace("&amp;", "&")
    if dl_page_url.startswith("/"):
        dl_page_url = base_url + dl_page_url
    elif dl_page_url.startswith("https://apkmirror.com"):
        dl_page_url = dl_page_url.replace("https://apkmirror.com", base_url, 1)

    res_dl_page = session.get(dl_page_url, headers={"Referer": variant_url})
    direct_href = extract_direct_link(res_dl_page.text, dl_page_url)

    if not direct_href:
        print(f"❌ Không trích xuất được link download.php hợp lệ ({ext.upper()}).")
        return

    direct_url = base_url + direct_href if direct_href.startswith("/") else direct_href
    output_path = os.path.join(save_dir, f"YouTube.{ext}")

    print(f"⏳ Đang tải ({arch_label}): {output_path}...")
    res_file = session.get(
        direct_url,
        headers={
            "Referer": dl_page_url,
            "Accept": "application/vnd.android.package-archive,application/octet-stream,*/*"
        },
        allow_redirects=True
    )

    if "text/html" in res_file.headers.get("Content-Type", "").lower():
        soup_err = BeautifulSoup(res_file.text, "html.parser")
        err_msg = soup_err.find(string=re.compile(r"expired|blocked|wait", re.I))
        print(f"❌ Máy chủ từ chối tải {ext.upper()}: {err_msg.strip() if err_msg else 'Trả về HTML'}")
        print(f"   URL gọi: {direct_url}")
        return

    with open(output_path, "wb") as f:
        f.write(res_file.content)

    if zipfile.is_zipfile(output_path):
        with zipfile.ZipFile(output_path, 'r') as zf:
            bad_file = zf.testzip()
            if bad_file is None:
                size_mb = os.path.getsize(output_path) / (1024 * 1024)
                actual_sha256 = get_sha256(output_path)
                sha_status = "Khớp SHA-256" if (expected_sha256 and actual_sha256 == expected_sha256) else f"SHA-256: {actual_sha256[:12]}..."
                print(f"🎉 Hoàn tất {output_path} ({size_mb:.2f} MB) | {sha_status}")
            else:
                print(f"⚠️ File {bad_file} trong {output_path} bị hỏng.")
    else:
        print(f"⚠️ File {output_path} không đúng định dạng ZIP/APK.")

for idx, (ext, arch_label, url) in enumerate(final_list):
    download_variant(ext, arch_label, url)
    if idx < len(final_list) - 1:
        time.sleep(3)
EOF
}

# Load dữ liệu cài đặt: . $HOME/.github/
#Ton=' -e "feature"'
Tof=' -e "Disable Play Store updates" -e "Hide ads" -e "Video ads" -e "SponsorBlock" -e "Copy video URL" -e "Double tap to seek" -e "Downloads" -e "Loop video" -e "Reload video" -e "Seekbar" -e "Swipe controls" -e "Change header" -e "Navigation bar" -e "Captions" -e "Ambient mode" -e "Miniplayer" -e "Exit fullscreen mode" -e "Open videos fullscreen" -e "Custom player overlay opacity" -e "Return YouTube Dislike" -e "Open Shorts in regular player" -e "Spoof app version" -e "Alternative thumbnails" -e "Bypass image region restrictions" -e "Spoof device dimensions" -e "Bypass URL redirects" -e "Open links externally" -e "Sanitize sharing links" -e "Open system share sheet" -e "Video quality" -e "Playback speed" -e "Change start page" -d "Override YouTube Music actions" -d "Shorts autoplay" -d "Disable layout updates" -d "Change form factor" '
[ "$TYPE" == 'true' ] && Mro='-d "GmsCore support" -d "Change package name" -d "Custom branding"' || Mro='-e "GmsCore support" -e "Change package name" -e "Custom branding"'

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
echo "- Tải tool cli, patches..."
if [ "$DEV" == "Develop" ]; then echo "  Dùng Dev"
pbdev morphe-desktop morphe-desktop jar -all
pbdev morphe-patches patches mpp
Ves1=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages[] | select(.packageName == "com.google.android.youtube") | .targets[] | select(.isExperimental == true) | .version' | head -n 1)
Ves2=$(java -jar $lib1 list-versions --patches $lib2 --prerelease | sed -n '/com.google.android.youtube/,$p' | grep -oEm1 '[0-9]+\.[0-9]+\.[0-9]+')
else echo "  Dùng Stable"
pbsta morphe-desktop morphe-desktop jar -all
pbsta morphe-patches patches mpp
Ves1=$(Xem https://raw.githubusercontent.com/MorpheApp/morphe-patches/main/patches-list.json | jq -r '.patches[0].compatiblePackages[] | select(.packageName == "com.google.android.youtube") | .targets[] | select(.isExperimental == false) | .version' | head -n 1)
Ves2=$(java -jar $lib1 list-versions --patches $lib2 | sed -n '/com.google.android.youtube/,$p' | grep -oEm1 '[0-9]+\.[0-9]+\.[0-9]+')
fi

Ves=$Ves2
echo " Phiên bản: $Ves"

if [ "$VERSION" == 'New' ]; then
VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
[ -z "$VER" ] && VER=$Ves
Kad=Build
V=V
elif [ "$VERSION" == 'Auto' ]; then
VER=$Ves
[ -z "$Ves" ] && VER=$(Xem "https://www.apkmirror.com/apk/google-inc/youtube/feed/" | grep -m1 -oP '(?<=YouTube )[\d.]+')
Kad=Auto
V=U
else
Ves="$VERSION"
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

if [ "$Ves" != "$VER" ]; then echo "- Không hỗ trợ phiên bản $VER" && exit 0; fi

echo "- Tải YouTube $VER apk, apks..."
# Tải YouTube apk
printf '{
  "options": {
    "outDir": "apk"
  },
  "apps": [
    {
      "org": "google-inc",
      "repo": "youtube",
      "version": "$VER",
      "type": "apk",
      "outFile": "YouTube"
    }
  ]
}' > apps.json
#tapkm
#$HOME/.github/apkmd apps.json

LUU="$PWD/apk" && taiyt

ls apk/*.apk*

if [ "$TYPE" == 'true' ]; then
 if [ -f apk/YouTube.apk ]; then 
 echo "- Giải nén Lib"
 unzip -qo apk/YouTube.apk lib/$DEVICE/* -d tmp || echo " •Không có lib!"
 fi
 if [ -f apk/YouTube.apkm ]; then 
 echo "- Giải nén base.apk"
 for f in 'base.apk' "split_config.${DEVICE//-/_}.apk" 'split_config.xxhdpi.apk' 'split_config.vi.apk'; do unzip -qo apk/YouTube.apkm "$f" -d Tav || echo " •Không có tập tin $f"; done
 fi
fi

if [ -f apk/YouTube.apk ]; then 
echo "- Xoá lib thừa apk"
rm -f apk/YouTube.apkm 2>/dev/null
tapk='apk/YouTube.apk'
apkeditor d -t sig -i "$tapk" -sig "signatures_dir" &>/dev/null 
zip -qr $tapk -d $lib || echo " •Không có lib cần xoá!"
fi
if [ -f apk/YouTube.apkm ]; then
echo "- Xoá lib thừa apkm"
[ -f Tav/base.apk ] && apkeditor d -t sig -i "Tav/base.apk" -sig "signatures_dir" &>/dev/null
tapk='apk/YouTube.apkm'
zip -qr $tapk -d $libm || echo " •Không có lib cần xoá!"
fi

# MOD YouTube 
echo "▼ Bắt đầu quá trình xây dựng..."
echo
tam=$PWD/lib/tam && mkdir -p $tam
tenapk=$(find "$PWD/apk" -maxdepth 1 -name "*.apk" | head -n 1)
[ -z "$tenapk" ] && tenapk=$(find "$PWD/apk" -maxdepth 1 -name "*.apkm" | head -n 1)
eval "java -Djava.io.tmpdir=$HOME -jar $lib1 patch -p $lib2 -t $tam --disable-purge --keystore "$KN" --keystore-password "$KP" --keystore-entry-alias "$KA" --keystore-entry-password "$KP" -o YT.apk $tapk "$Tof $Ton $Mro $feature""
echo '- Quá trình xây dựng apk xong.'
echo

# Chờ xây dựng xong
if [ "$TYPE" == 'true' ]; then
echo "Tạo rsign..."
cp -rf YT.apk $HOME/Tav/YouTube.apk
cp -rf YT.apk "$HOME/Up/MYT-$VER-$ach-rsign.apk" 2>/dev/null
[ "$(ls -A tmp 2>/dev/null)" ] && cd tmp && zip -qr $HOME/YT.apk *
cd $HOME
apkeditor b -f -t sig -i YT.apk -sig "$PWD/signatures_dir" -o "$HOME/Up/MYT-$VER-$ach-rsigns.apk" &>/dev/null
else
#apksigns YT.apk $HOME/Up/MYT-$VER-$ach.apk
cp -rf YT.apk $HOME/Up/MYT-$VER-$ach.apk
ls Up
exit 0
fi

# Tạo thư viện
cp -rf $HOME/.github/Tools/sqlite3_$ach Tav/sqlite3
cd Tav && tar -cf - * | xz -9kz > $HOME/.github/Modun/lib.tar.xz
cd $HOME

# Tạo module.prop
echo 'id=YouTube
name=YouTube Morphe '$Kad'
author=chamchamfy
description=Build '$date', YouTube edited tool by Morphe mod added disable play store updates.
version='$VER'
versionCode='${VER//./}'
updateJson=https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-M'$V$ach'.json
' > $HOME/.github/Modun/module.prop

# Tạo json
echo '{
"version": "'$VER'",
"versionCode": "'${VER//./}'",
"zipUrl": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/M'$V$VER'/MYT-Hybrid-'$VER'-'$ach'.Zip",
"changelog": "https://github.com/'$GITHUB_REPOSITORY'/releases/download/Up/Up-M'$V'notes.json"
}' > "Up-M$V$ach.json"

echo -e 'Update '$date' \nYouTube: '$VER' \nVersion: '${VER//./}'\nAuto by chamchamfy' > Up-M${V}notes.json

# Tạo module
cd $HOME/.github/Modun
zip -qr $HOME/Up/MYT-Hybrid-$VER-$ach.zip *
cd $HOME
ls Up
