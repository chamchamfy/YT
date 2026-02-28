import sys
import requests
from bs4 import BeautifulSoup
import re

def get_link(version):
    # Header cực kỳ quan trọng để không bị coi là bot
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Referer': 'https://www.apkmirror.com/'
    }
    
    session = requests.Session()
    session.headers.update(headers)
    base_url = "https://www.apkmirror.com"
    ver_slug = version.replace('.', '-')
    search_url = f"{base_url}/apk/google-inc/youtube/youtube-{ver_slug}-release/"

    try:
        # Bước 1: Tìm trang Variant
        res = session.get(search_url, timeout=15)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # Tìm link APK đầu tiên (tránh Bundle)
        variant_link = ""
        for a in soup.find_all('a', href=re.compile(r"/download/")):
            parent_text = a.find_parent().get_text()
            if "APK" in parent_text and "Bundle" not in parent_text:
                variant_link = base_url + a['href']
                break
        
        if not variant_link:
            return "ERROR: Khong tim thay variant APK"

        # Bước 2: Truy cập trang Variant để tìm nút Download thật
        res_variant = session.get(variant_link, timeout=15)
        soup_variant = BeautifulSoup(res_variant.text, 'html.parser')
        
        # Tìm link đến trang cuối (thường có class 'download-button')
        final_page_tag = soup_variant.find('a', class_=re.compile(r"download-button", re.IGNORECASE))
        if not final_page_tag:
            # Dự phòng nếu class thay đổi
            final_page_tag = soup_variant.find('a', href=re.compile(r"key="))
            
        if not final_page_tag:
            return "ERROR: Khong tim thay nut download cuoi"
            
        final_page_url = base_url + final_page_tag['href']

        # Bước 3: Lấy Direct Link từ trang cuối
        res_final = session.get(final_page_url, timeout=15)
        soup_final = BeautifulSoup(res_final.text, 'html.parser')
        
        # Tìm link có chữ "here"
        direct_link_tag = soup_final.find('a', string=re.compile("here", re.IGNORECASE))
        if direct_link_tag:
            direct_link = direct_link_tag['href']
            if direct_link.startswith('/'):
                return base_url + direct_link
            return direct_link
        
        return "ERROR: Khong trich xuat duoc link 'here'"

    except Exception as e:
        return f"ERROR_EXCEPTION: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print(get_link(sys.argv[1]))
