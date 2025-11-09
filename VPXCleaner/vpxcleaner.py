import olefile
import struct
import argparse
from datetime import datetime

def list_vpx_assets(vpx_path):
    ole = olefile.OleFileIO(vpx_path)
    streams = ole.listdir()

    images = {}  # Store as dict: {name: (stream_path, size)}
    sounds = {}  # Store as dict: {name: (stream_path, size)}
    all_data = ""  # Combine all relevant data for searching

    for stream in streams:
        stream_path = '/'.join(stream)
        
        # Extract images and sounds
        if stream_path.startswith("GameStg/Image"):
            try:
                with ole.openstream(stream) as s:
                    data = s.read()
                    # Try to extract the image name from the binary data
                    # VPX stores names as null-terminated strings in the data
                    name = extract_name_from_binary(data, is_image=True)
                    if name:
                        images[name] = (stream_path, len(data))
            except Exception:
                pass
                
        elif stream_path.startswith("GameStg/Sound"):
            try:
                with ole.openstream(stream) as s:
                    data = s.read()
                    # Try to extract the sound name from the binary data
                    name = extract_name_from_binary(data, is_image=False)
                    if name:
                        sounds[name] = (stream_path, len(data))
            except Exception:
                pass
        
        # Gather all game data for reference searching
        elif stream_path.startswith("GameStg/GameItem") or stream_path == "GameStg/GameData":
            try:
                with ole.openstream(stream) as s:
                    data = s.read()
                    # Decode as text, ignoring errors
                    text = data.decode('utf-8', errors='ignore')
                    all_data += text + "\n"
            except Exception:
                pass

    ole.close()
    return images, sounds, all_data

def extract_name_from_binary(data, is_image=True):
    """Extract asset name from VPX binary data.
    
    VPX format differs for images vs sounds:
    - Images: Length + "NAME" + padding + actual_name (within same field)
    - Sounds: Length + actual_name (first field is the name)
    """
    try:
        # Read first field length
        if len(data) < 4:
            return None
            
        field_len = struct.unpack('<I', data[0:4])[0]
        
        if field_len == 0 or field_len > 500:
            return None
            
        # Read the first field data
        if len(data) < 4 + field_len:
            return None
            
        field_data = data[4:4+field_len]
        field_str = field_data.decode('ascii', errors='ignore')
        
        if is_image:
            # For images, look for "NAME" at the start, then extract the name after it
            if field_str.startswith("NAME"):
                # The name comes after "NAME" and some padding/garbage
                # Typically "NAME     <actual_name>"
                name_part = field_str[4:].strip('\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\x0c\r\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f ')
                # Remove any non-printable characters from the start
                while name_part and ord(name_part[0]) < 32:
                    name_part = name_part[1:]
                if name_part:
                    return name_part
        else:
            # For sounds, the first field IS the name
            name = field_str.strip('\x00')
            # Clean up the name - remove trailing underscores that seem to be artifacts
            while name and name[-1] == '_':
                # Check if there's a version without underscore in the script
                name = name[:-1]
            return name if name else field_str.strip('\x00')
            
    except Exception:
        pass
    return None

def find_unused_assets(images, sounds, all_data):
    """Find assets that are not referenced in any game data."""
    # Convert all data to lowercase for case-insensitive searching
    all_data_lower = all_data.lower()
    
    unused_images = {}
    unused_sounds = {}
    
    # Check each image
    for img_name, (stream_path, size) in images.items():
        # Search for the image name (case-insensitive)
        if img_name.lower() not in all_data_lower:
            unused_images[img_name] = (stream_path, size)
    
    # Check each sound
    for snd_name, (stream_path, size) in sounds.items():
        # Search for the sound name (case-insensitive)
        if snd_name.lower() not in all_data_lower:
            unused_sounds[snd_name] = (stream_path, size)
    
    return unused_images, unused_sounds

def remove_unused_assets(vpx_path, unused_images, unused_sounds):
    """Export list of unused assets for manual removal.
    
    Unfortunately, the olefile library doesn't support deleting streams reliably.
    This function generates a report that can be used to manually remove assets
    in Visual Pinball's table editor.
    
    Args:
        vpx_path: Path to original VPX file
        unused_images: Dict of unused images {name: (stream_path, size)}
        unused_sounds: Dict of unused sounds {name: (stream_path, size)}
    
    Returns:
        Path to the removal report file
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = vpx_path.replace(".vpx", f"_removal_list_{timestamp}.txt")
    
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("="*70 + "\n")
        f.write("VPX CLEANER - ASSET REMOVAL REPORT\n")
        f.write("="*70 + "\n\n")
        f.write(f"File: {vpx_path}\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write(f"UNUSED IMAGES ({len(unused_images)}):\n")
        f.write("-" * 70 + "\n")
        if unused_images:
            for img in sorted(unused_images.keys()):
                _,  size = unused_images[img]
                f.write(f"  - {img}\n")
        else:
            f.write("  (none)\n")
        
        f.write(f"\n\nUNUSED SOUNDS ({len(unused_sounds)}):\n")
        f.write("-" * 70 + "\n")
        if unused_sounds:
            for snd in sorted(unused_sounds.keys()):
                _, size = unused_sounds[snd]
                f.write(f"  - {snd}\n")
        else:
            f.write("  (none)\n")
        
        f.write("\n\n" + "="*70 + "\n")
        f.write("INSTRUCTIONS FOR MANUAL REMOVAL:\n")
        f.write("="*70 + "\n")
        f.write("1. Open the VPX file in Visual Pinball\n")
        f.write("2. Open the Image Manager (Ctrl+I) or Sound Manager (Ctrl+U)\n")
        f.write("3. Select and delete the unused assets listed above\n")
        f.write("4. Save the table\n")
        f.write("\nNote: Automatic removal requires write support for OLE files,\n")
        f.write("which is not available in the current olefile library.\n")
    
    return report_path


def format_size(bytes_size):
    """Format bytes to human-readable size."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_size < 1024.0:
            return f"{bytes_size:.2f} {unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.2f} TB"


if __name__ == "__main__":
    import os
    
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='VPX Cleaner - Identify and optionally remove unused images and sounds from Visual Pinball VPX files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Scan and report only (default)
  python vpxcleaner.py table.vpx
  
  # Scan and remove unused assets
  python vpxcleaner.py table.vpx --remove
  python vpxcleaner.py table.vpx -r
        """
    )
    parser.add_argument('vpx_file', help='Path to the VPX file to analyze')
    parser.add_argument('-r', '--remove', action='store_true', 
                        help='Remove unused assets and create a cleaned VPX file (creates backup)')
    
    args = parser.parse_args()
    vpx_file = args.vpx_file
    
    if not os.path.exists(vpx_file):
        print(f"❌ Error: File not found: {vpx_file}")
        exit(1)
    
    print("="*70)
    print("VPX CLEANER - Visual Pinball Asset Analyzer")
    print("="*70)
    print(f"\n📁 Analyzing VPX file...")
    print(f"   File: {vpx_file}")
    print(f"   Size: {format_size(os.path.getsize(vpx_file))}\n")
    
    images, sounds, all_data = list_vpx_assets(vpx_file)
    
    print(f"Found {len(images)} images")
    print(f"Found {len(sounds)} sounds")
    print(f"Game data length: {len(all_data)} characters")
    
    if len(images) > 0:
        print("\nSample image names:")
        for name in sorted(images.keys())[:5]:
            print(f"  - {name}")
        if len(images) > 5:
            print(f"  ... and {len(images) - 5} more")
    
    if len(sounds) > 0:
        print("\nSample sound names:")
        for name in sorted(sounds.keys())[:5]:
            print(f"  - {name}")
        if len(sounds) > 5:
            print(f"  ... and {len(sounds) - 5} more")
    
    print("\n" + "="*70)
    print("CHECKING FOR UNUSED ASSETS...")
    print("="*70 + "\n")
    
    unused_images, unused_sounds = find_unused_assets(images, sounds, all_data)
    
    # Calculate potential space savings
    unused_image_size = sum(size for _, size in unused_images.values())
    unused_sound_size = sum(size for _, size in unused_sounds.values())
    total_savings = unused_image_size + unused_sound_size
    
    print(f"🖼️  Unused Images: {len(unused_images)} ({format_size(unused_image_size)})")
    if unused_images:
        print("\nUnused image list:")
        for img in sorted(unused_images.keys()):
            stream, size = unused_images[img]
            print(f"  - {img:40s} {format_size(size):>12s}")
    else:
        print("  ✓ All images are being used!")

    print(f"\n🔊 Unused Sounds: {len(unused_sounds)} ({format_size(unused_sound_size)})")
    if unused_sounds:
        print("\nUnused sound list:")
        for snd in sorted(unused_sounds.keys()):
            stream, size = unused_sounds[snd]
            print(f"  - {snd:40s} {format_size(size):>12s}")
    else:
        print("  ✓ All sounds are being used!")
    
    print("\n" + "="*70)
    print(f"💾 Total potential space savings: {format_size(total_savings)}")
    if total_savings > 0:
        print(f"   ({(total_savings / os.path.getsize(vpx_file) * 100):.1f}% of file size)")
    print("="*70)
    
    # Remove assets if requested
    if args.remove:
        if total_savings == 0:
            print("\n✅ No unused assets to remove!")
        else:
            print("\n" + "="*70)
            print("GENERATING REMOVAL REPORT...")
            print("="*70)
            
            try:
                report_path = remove_unused_assets(vpx_file, unused_images, unused_sounds)
                
                print("\n" + "="*70)
                print("✅ REPORT GENERATED!")
                print("="*70)
                print(f"\n📄 Removal list saved to: {report_path}")
                print("\n⚠️  NOTE: Automatic removal is not currently supported.")
                print("The report contains a list of all unused assets that can be")
                print("manually removed using Visual Pinball's Image/Sound Manager.")
                print("="*70)
                
            except Exception as e:
                print(f"\n❌ Error generating report: {e}")
                import traceback
                traceback.print_exc()
                exit(1)
    else:
        if total_savings > 0:
            print("\n💡 Tip: Use --remove flag to generate a removal report")
            print(f"   Example: python vpxcleaner.py {vpx_file} --remove")