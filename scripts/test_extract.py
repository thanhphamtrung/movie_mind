import asyncio
from scrapling import Fetcher

def test_extract(url):
    fetcher = Fetcher()
    res = fetcher.get(url)
    
    original_title = ""
    # Try different selectors for original title
    ot_el = res.css('.name2')
    if not ot_el: ot_el = res.css('.original-title')
    if ot_el: original_title = ot_el[0].text.strip()
    
    # Countries
    countries = [a.text.strip() for a in res.css('.motchill-info-item:contains("Quốc gia:") a')]
    
    # Directors
    directors = [a.text.strip() for a in res.css('.motchill-info-item:contains("Đạo diễn:") a')]
    
    # Genres
    genres = [a.text.strip() for a in res.css('.motchill-info-item:contains("Thể loại:") a')]
    
    # Year
    year = None
    year_links = res.css('.motchill-info-item:contains("Năm phát hành:") a')
    if year_links:
        year = year_links[0].text.strip()
    else:
        year_el = res.css('.motchill-info-item:contains("Năm phát hành:") .motchill-info-value')
        if year_el:
            year = year_el[0].text.strip()

    # Actors
    actors = [a.text.strip() for a in res.css('.motchill-actors-slider .actor-name')]
    if not actors:
         actors = [a.attrib.get('title', '') for a in res.css('.motchill-actors-slider a') if a.attrib.get('title')]
         
    print(f"URL: {url}")
    print(f"Original Title: {original_title}")
    print(f"Countries: {countries}")
    print(f"Directors: {directors}")
    print(f"Genres: {genres}")
    print(f"Year: {year}")
    print(f"Actors: {actors}")

if __name__ == "__main__":
    test_extract("https://eyephotodoc.com/phim/truc-ngoc/")
    print("-" * 50)
    test_extract("https://eyephotodoc.com/phim/co-be-ma-ca-rong/")
