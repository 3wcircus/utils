import requests
from datetime import datetime
from collections import Counter

# === CONFIG ===
USERNAME = "3wcircus"
START_DATE = "2025-11-06"
END_DATE = "2025-11-08"
SHOW_FILENAMES = False  # Set to False to only show URLs
SORT_BY = "name"  # Options: "date" (most recent first) or "name" (alphabetical by first filename)

# === FETCH GISTS ===
def fetch_gists(username):
    gists = []
    page = 1
    while True:
        url = f"https://api.github.com/users/{username}/gists?page={page}&per_page=100"
        response = requests.get(url)
        if response.status_code != 200:
            raise Exception(f"GitHub API error: {response.status_code}")
        data = response.json()
        if not data:
            break
        gists.extend(data)
        page += 1
    return gists

# === FILTER AND DISPLAY ===
def filter_gists(gists, start, end):
    start_dt = datetime.fromisoformat(start + "T00:00:00+00:00")
    end_dt = datetime.fromisoformat(end + "T23:59:59+00:00")
    
    # First pass: collect filtered gists and count filenames
    filtered_gists = []
    filename_counts = Counter()
    
    for gist in gists:
        created = datetime.fromisoformat(gist["created_at"].replace("Z", "+00:00"))
        if start_dt <= created <= end_dt:
            filtered_gists.append(gist)
            for filename in gist["files"].keys():
                filename_counts[filename] += 1
    
    # Sort by updated date (most recent first) or by filename
    if SORT_BY == "name":
        filtered_gists.sort(key=lambda g: list(g["files"].keys())[0].lower())
    else:
        filtered_gists.sort(key=lambda g: g["updated_at"], reverse=True)
    
    # Second pass: display with duplicate highlighting
    for gist in filtered_gists:
        url = gist["html_url"]
        if SHOW_FILENAMES:
            updated = datetime.fromisoformat(gist["updated_at"].replace("Z", "+00:00"))
            updated_str = updated.strftime("%Y-%m-%d %H:%M")
            filenames = []
            for filename in gist["files"].keys():
                if filename_counts[filename] >= 2:
                    filenames.append(f"**{filename}**")  # Highlight duplicates
                else:
                    filenames.append(filename)
            print(f"{url} → {', '.join(filenames)} (Updated: {updated_str})")
        else:
            print(url)

# === RUN ===
if __name__ == "__main__":
    all_gists = fetch_gists(USERNAME)
    filter_gists(all_gists, START_DATE, END_DATE)