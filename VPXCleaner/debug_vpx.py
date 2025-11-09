import olefile

vpx_file = "OnePieceBlues.test.vpx"
ole = olefile.OleFileIO(vpx_file)

# Look at a few image and sound streams
print("=== Sample Image Stream ===")
with ole.openstream(['GameStg', 'Image0']) as s:
    data = s.read()
    print(f"Size: {len(data)} bytes")
    print(f"First 500 bytes (hex): {data[:500].hex()}")
    print(f"First 500 bytes (text): {data[:500]}")
    print()

print("\n=== Sample Sound Stream ===")
with ole.openstream(['GameStg', 'Sound0']) as s:
    data = s.read()
    print(f"Size: {len(data)} bytes")
    print(f"First 500 bytes (hex): {data[:500].hex()}")
    print(f"First 500 bytes (text): {data[:500]}")

ole.close()
