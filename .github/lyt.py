import sys
import cloudscraper
from bs4 import BeautifulSoup
import re

def get_link(version):
    scraper = cloudscraper.create_scraper()
    base_url = "https://www.apkmirror.com"
    
    # Tạo URL tìm kiếm trực tiếp cho phiên bản cụ thể
    search_url = f"{base_url}/apk/google-inc/youtube/youtube-{version.replace('.', '-')}-release/"
    
    try:
        # 1. Truy cập trang danh sách các biến thể (variants)
        response = scraper.get(search_url)
        if response.status_code != 200:
            return ""

        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Tìm variant đầu tiên (thường là kiến trúc arm64-v8a hoặc universal)
        # Chúng ta tìm nút dẫn đến trang download cụ thể
        download_page_link = soup.find('a', {'title': 'Download APK'})
        
        if not download_page_link:
            # Tìm link chứa chữ "download" trong bảng biến thể
            variant = soup.find('a', class_='accent_color', href=re.compile(r"download/"))
            if not variant: return ""
            download_page_url = base_url + variant['href']
        else:
            download_page_url = base_url + download_page_link['href']

        # 2. Truy cập trang lấy link cuối cùng
        res_final = scraper.get(download_page_url)
        soup_final = BeautifulSoup(res_final.text, 'html.parser')
        
        # Tìm link "Click here" - Đây là link tải thực tế (direct link)
        final_tag = soup_final.find('a', text=re.compile("here"))
        if final_tag:
            return base_url + final_tag['href']
            
    except Exception:
        return ""
    
    return ""

if __name__ == "__main__":
    # Nhận biến VER từ tham số dòng lệnh
    if len(sys.argv) > 1:
        ver = sys.argv[1]
        print(get_link(ver))
