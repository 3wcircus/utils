import requests
from datetime import datetime
from collections import Counter
import argparse
import os
from pathlib import Path

# === CONFIG ===
USERNAME = "3wcircus"
START_DATE = datetime.now().strftime("%Y-%m-%d")
END_DATE = datetime.now().strftime("%Y-%m-%d")
SHOW_FILENAMES = True  # Set to False to only show URLs
SORT_BY = "name"  # Options: "date" (most recent first) or "name" (alphabetical by first filename)
REMOVE_DUPLICATES = False  # Set to True to keep only the most recently updated gist for duplicate filenames

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
    
    # Count total duplicates (before any removal)
    total_duplicates_found = sum(count - 1 for count in filename_counts.values() if count > 1)
    
    duplicates_removed = 0
    
    # Remove duplicates if requested (keep most recently updated)
    if REMOVE_DUPLICATES:
        original_count = len(filtered_gists)
        seen_filenames = {}
        deduplicated_gists = []
        
        # Sort by updated date first to ensure we keep the most recent
        filtered_gists.sort(key=lambda g: g["updated_at"], reverse=True)
        
        for gist in filtered_gists:
            gist_filenames = list(gist["files"].keys())
            # Check if any filename in this gist hasn't been seen yet
            has_new_filename = False
            for filename in gist_filenames:
                if filename not in seen_filenames:
                    has_new_filename = True
                    seen_filenames[filename] = gist["html_url"]
            
            # Only include gist if it has at least one filename we haven't seen
            if has_new_filename:
                deduplicated_gists.append(gist)
        
        filtered_gists = deduplicated_gists
        duplicates_removed = original_count - len(filtered_gists)
        
        # Recalculate filename counts after deduplication
        filename_counts = Counter()
        for gist in filtered_gists:
            for filename in gist["files"].keys():
                filename_counts[filename] += 1
    
    # Check if any gists were found
    if not filtered_gists:
        print(f"No gists found for date range {start} to {end}")
        return None, (total_duplicates_found, duplicates_removed)
    
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
    
    return filtered_gists, (total_duplicates_found, duplicates_removed)

# === FIND LOCAL FILES ===
def find_local_files(project_dir):
    """Recursively find all files in project directory and map by filename"""
    file_map = {}  # filename -> (path, mtime)
    project_path = Path(project_dir)
    
    if not project_path.exists():
        raise Exception(f"Project directory does not exist: {project_dir}")
    
    for file_path in project_path.rglob("*"):
        if file_path.is_file():
            filename = file_path.name
            mtime = file_path.stat().st_mtime
            
            # Keep the most recently modified file if duplicates exist
            if filename not in file_map or mtime > file_map[filename][1]:
                file_map[filename] = (str(file_path), mtime)
    
    return file_map

# === UPDATE GIST ===
def update_gist(gist_id, filename, content, token):
    """Update a specific file in a gist"""
    url = f"https://api.github.com/gists/{gist_id}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "files": {
            filename: {
                "content": content
            }
        }
    }
    
    response = requests.patch(url, json=data, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Failed to update gist: {response.status_code} - {response.text}")
    return response.json()

# === DELETE GIST ===
def delete_gist(gist_id, token):
    """Delete a gist from GitHub"""
    url = f"https://api.github.com/gists/{gist_id}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.delete(url, headers=headers)
    if response.status_code != 204:
        raise Exception(f"Failed to delete gist: {response.status_code} - {response.text}")
    return True

# === CREATE GIST ===
def create_gist(filename, content, token):
    """Create a new public gist with a single file"""
    url = "https://api.github.com/gists"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "description": f"{filename} - automatically added from local project",
        "public": True,
        "files": {
            filename: {
                "content": content
            }
        }
    }
    
    response = requests.post(url, json=data, headers=headers)
    if response.status_code != 201:
        raise Exception(f"Failed to create gist: {response.status_code} - {response.text}")
    return response.json()

# === DELETE DUPLICATE GISTS ===
def delete_duplicate_gists(all_gists, start, end, token, force=False):
    """Find and delete duplicate gists, keeping the most recently updated"""
    if not token:
        print("Error: GitHub token required for deleting gists. Set GITHUB_TOKEN or use --token")
        return 0, 0
    
    start_dt = datetime.fromisoformat(start + "T00:00:00+00:00")
    end_dt = datetime.fromisoformat(end + "T23:59:59+00:00")
    
    # Filter gists by date range
    filtered_gists = []
    filename_counts = Counter()
    
    for gist in all_gists:
        created = datetime.fromisoformat(gist["created_at"].replace("Z", "+00:00"))
        if start_dt <= created <= end_dt:
            filtered_gists.append(gist)
            for filename in gist["files"].keys():
                filename_counts[filename] += 1
    
    # Count duplicates
    total_duplicates = sum(count - 1 for count in filename_counts.values() if count > 1)
    
    if total_duplicates == 0:
        return 0, 0
    
    # Prompt for confirmation if not force
    if not force:
        print(f"\nFound {total_duplicates} duplicate files across multiple gists.")
        response = input("Delete outdated duplicate gists from GitHub? This cannot be undone! (y/n): ")
        if response.lower() != 'y':
            print("Deletion cancelled")
            return total_duplicates, 0
    
    # Sort by updated date (most recent first)
    filtered_gists.sort(key=lambda g: g["updated_at"], reverse=True)
    
    seen_filenames = {}
    gists_to_delete = []
    
    for gist in filtered_gists:
        gist_filenames = list(gist["files"].keys())
        
        # Check if all filenames in this gist have been seen before
        all_seen = all(filename in seen_filenames for filename in gist_filenames)
        
        if all_seen:
            # This gist is a duplicate - mark for deletion
            gists_to_delete.append(gist)
        else:
            # Mark these filenames as seen
            for filename in gist_filenames:
                if filename not in seen_filenames:
                    seen_filenames[filename] = gist["html_url"]
    
    # Delete the duplicate gists
    deleted_count = 0
    for gist in gists_to_delete:
        try:
            delete_gist(gist["id"], token)
            print(f"  ✓ Deleted: {gist['html_url']}")
            deleted_count += 1
        except Exception as e:
            print(f"  ✗ Failed to delete {gist['html_url']}: {e}")
    
    return total_duplicates, deleted_count

# === SYNC GISTS WITH LOCAL FILES ===
def sync_gists_with_local(gists, project_dir, token, force=False):
    """Compare gists with local files and update outdated gists"""
    if not token:
        print("Error: GitHub token required for updating gists. Set GITHUB_TOKEN or use --token")
        return
    
    file_map = find_local_files(project_dir)
    updates_made = 0
    skipped = 0
    up_to_date = 0
    
    for gist in gists:
        gist_id = gist["id"]
        gist_updated = datetime.fromisoformat(gist["updated_at"].replace("Z", "+00:00"))
        
        for filename, file_info in gist["files"].items():
            if filename in file_map:
                local_path, local_mtime = file_map[filename]
                local_dt = datetime.fromtimestamp(local_mtime).astimezone()
                
                # Check if local file is newer
                if local_dt > gist_updated:
                    print(f"\nFound outdated gist file: {filename}")
                    print(f"  Gist URL: {gist['html_url']}")
                    print(f"  Local file: {local_path}")
                    print(f"  Local modified: {local_dt.strftime('%Y-%m-%d %H:%M:%S')}")
                    print(f"  Gist updated: {gist_updated.strftime('%Y-%m-%d %H:%M:%S')}")
                    
                    update = force
                    if not force:
                        response = input("  Update gist with local file? (y/n): ")
                        update = response.lower() == 'y'
                    
                    if update:
                        try:
                            with open(local_path, 'r', encoding='utf-8') as f:
                                content = f.read()
                            update_gist(gist_id, filename, content, token)
                            print("  ✓ Updated successfully")
                            updates_made += 1
                        except Exception as e:
                            print(f"  ✗ Error updating: {e}")
                    else:
                        print("  Skipped")
                        skipped += 1
                else:
                    # Gist is up-to-date or newer than local file
                    up_to_date += 1
    
    print("\n--- Sync Summary ---")
    print(f"Updates made: {updates_made}")
    print(f"Up-to-date (no update needed): {up_to_date}")
    print(f"Skipped (user declined): {skipped}")
    print(f"Local files scanned: {len(file_map)}")

# === CREATE MISSING GISTS ===
def create_missing_gists(gists, project_dir, token, file_pattern=None, force=False):
    """Create new gists for local files that don't have gists yet"""
    if not token:
        print("Error: GitHub token required for creating gists. Set GITHUB_TOKEN or use --token")
        return
    
    # Get all local files
    project_path = Path(project_dir)
    if not project_path.exists():
        raise Exception(f"Project directory does not exist: {project_dir}")
    
    # Collect existing gist filenames
    existing_filenames = set()
    for gist in gists:
        for filename in gist["files"].keys():
            existing_filenames.add(filename)
    
    print(f"Found {len(existing_filenames)} existing gist filenames")
    
    # Find local files that don't have gists
    missing_files = []
    
    if file_pattern:
        # Use glob pattern
        for file_path in project_path.rglob(file_pattern):
            if file_path.is_file():
                filename = file_path.name
                if filename not in existing_filenames:
                    missing_files.append((filename, str(file_path)))
    else:
        # All files - warn user
        print("\nWARNING: No --file-pattern specified. This will create gists for ALL files in the directory!")
        if not force:
            response = input("Continue and create gists for all files? (y/n): ")
            if response.lower() != 'y':
                print("Cancelled")
                return
        
        for file_path in project_path.rglob("*"):
            if file_path.is_file():
                filename = file_path.name
                if filename not in existing_filenames:
                    missing_files.append((filename, str(file_path)))
    
    if not missing_files:
        print("\nNo missing gists to create. All files already have gists.")
        return
    
    print(f"\nFound {len(missing_files)} files without gists")
    
    if not force:
        response = input(f"Create {len(missing_files)} new public gists? (y/n): ")
        if response.lower() != 'y':
            print("Cancelled")
            return
    
    # Create gists
    created_count = 0
    skipped_count = 0
    for filename, file_path in missing_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Skip empty files
            if not content or not content.strip():
                print(f"  ⊘ Skipped {filename}: File is empty")
                skipped_count += 1
                continue
            
            result = create_gist(filename, content, token)
            print(f"  ✓ Created gist for {filename}: {result['html_url']}")
            created_count += 1
        except UnicodeDecodeError:
            print(f"  ⊘ Skipped {filename}: Binary file or encoding issue")
            skipped_count += 1
        except Exception as e:
            print(f"  ✗ Failed to create gist for {filename}: {e}")
    
    print("\n--- Create Summary ---")
    print(f"Gists created: {created_count}")
    print(f"Skipped: {skipped_count}")
    print(f"Total files checked: {len(missing_files)}")

# === RUN ===
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Fetch and filter GitHub gists by date range",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python gist_fetcher.py
  python gist_fetcher.py --username myuser --start 2025-01-01 --end 2025-12-31
  python gist_fetcher.py --show-filenames --sort name
  python gist_fetcher.py --remove-duplicates --sort date
  python gist_fetcher.py --project-dir ./myproject --token YOUR_TOKEN
  python gist_fetcher.py --project-dir ./myproject --token YOUR_TOKEN --force
        """
    )
    
    parser.add_argument("--username", default=USERNAME, help=f"GitHub username (default: {USERNAME})")
    parser.add_argument("--start", default=START_DATE, help=f"Start date YYYY-MM-DD (default: {START_DATE})")
    parser.add_argument("--end", default=END_DATE, help=f"End date YYYY-MM-DD (default: {END_DATE})")
    parser.add_argument("--show-filenames", action="store_true", default=SHOW_FILENAMES, 
                        help="Show filenames with URLs (default: False)")
    parser.add_argument("--sort", choices=["date", "name"], default=SORT_BY,
                        help=f"Sort by 'date' or 'name' (default: {SORT_BY})")
    parser.add_argument("--remove-duplicates", action="store_true", default=REMOVE_DUPLICATES,
                        help="Delete duplicate gists from GitHub, keeping most recent (requires --token)")
    parser.add_argument("--project-dir", help="Local project directory to sync with gists")
    parser.add_argument("--token", default="***REMOVED***", help="GitHub personal access token (required for syncing/deleting)")
    parser.add_argument("--force", action="store_true", help="Skip confirmation prompts for deletion and updates")
    parser.add_argument("--create-missing", action="store_true", help="Create new gists for files without existing gists")
    parser.add_argument("--file-pattern", help="File pattern for creating gists (e.g., *.dart, *.py)")
    
    args = parser.parse_args()
    
    all_gists = fetch_gists(args.username)
    
    # Temporarily override globals for filter_gists function
    original_show = SHOW_FILENAMES
    original_sort = SORT_BY
    original_remove = REMOVE_DUPLICATES
    
    SHOW_FILENAMES = args.show_filenames
    SORT_BY = args.sort
    REMOVE_DUPLICATES = False  # We'll handle deletion separately, not in filter_gists
    
    # Handle remove duplicates - actually delete from GitHub
    if args.remove_duplicates:
        duplicates_found, deleted_count = delete_duplicate_gists(
            all_gists, args.start, args.end, args.token, args.force
        )
        
        if deleted_count > 0:
            print(f"\nDuplicate files found: {duplicates_found}, Gists deleted: {deleted_count}")
            # Re-fetch gists after deletion
            all_gists = fetch_gists(args.username)
        elif duplicates_found > 0:
            print(f"\nDuplicate files found: {duplicates_found}, No gists deleted")
    
    filtered_gists, (duplicates_found_display, _) = filter_gists(all_gists, args.start, args.end)
    
    # Display remaining duplicates if any (after deletion or if no deletion happened)
    if not args.remove_duplicates and duplicates_found_display > 0 and filtered_gists:
        print(f"\nDuplicate files found: {duplicates_found_display} (use --remove-duplicates to delete)")
    
    # Sync with local project directory if specified
    if args.project_dir and filtered_gists:
        print("\n--- Starting sync with local files ---")
        sync_gists_with_local(filtered_gists, args.project_dir, args.token, args.force)
    
    # Create missing gists if specified - use ALL gists, not filtered by date
    if args.create_missing and args.project_dir:
        print("\n--- Creating missing gists ---")
        create_missing_gists(all_gists, args.project_dir, args.token, args.file_pattern, args.force)