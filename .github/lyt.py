import sys
import requests
from bs4 import BeautifulSoup
import re

def get_link(version):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
    }
    
    base_url = "https://www.apkmirror.com"
    # Format lại version: ví dụ 19.05.36 thành 19-05-36
    ver_slug = version.replace('.', '-')
    search_url = f"{base_url}/apk/google-inc/youtube/youtube-{ver_slug}-release/"

    session = requests.Session()

    try:
        # Bước 1: Lấy trang danh sách variant
        res = session.get(search_url, headers=headers, timeout=15)
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # Tìm link download bản APK (không lấy BUNDLE)
        # Chúng ta dùng tìm kiếm chặt chẽ hơn để không bị lặp link
        download_page_url = ""
        # Tìm tất cả các thẻ <a> có chứa link download
        all_links = soup.find_all('a', href=re.compile(r"download/"))
        
        for link in all_links:
            # Kiểm tra xem link này có nằm trong vùng ghi là 'APK' không
            parent_text = link.find_parent().get_text() if link.find_parent() else ""
            if "APK" in parent_text and "Bundle" not in parent_text:
                download_page_url = base_url + link['href']
                break # Tìm thấy cái đầu tiên thì dừng luôn để tránh lặp
        
        if not download_page_url: return "ERROR_NO_URL"

        # Bước 2: Lấy link cuối
        res_final = session.get(download_page_url, headers=headers, timeout=15)
        soup_final = BeautifulSoup(res_final.text, 'html.parser')
        
        final_tag = soup_final.find('a', string=re.compile("here", re.IGNORECASE))
        if final_tag:
            return base_url + final_tag['href']

    except:
        return "ERROR_EXCEPTION"
    return "ERROR_NOT_FOUND"

if __name__ == "__main__":
    # Chỉ nhận 1 tham số duy nhất
    if len(sys.argv) > 1:
        # CHỈ PRINT ĐÚNG 1 DÒNG NÀY
        print(get_link(sys.argv[1]))
