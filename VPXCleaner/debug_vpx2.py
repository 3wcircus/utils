import olefile
import struct

vpx_file = "OnePieceBlues.test.vpx"
ole = olefile.OleFileIO(vpx_file)

print("=== Analyzing Image0 ===")
with ole.openstream(['GameStg', 'Image0']) as s:
    data = s.read()
    
    # Parse the structure manually
    offset = 0
    for i in range(10):  # First 10 fields
        if offset >= len(data):
            break
            
        # Read 4-byte length
        length = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        
        # Read the field
        field = data[offset:offset+length]
        offset += length
        
        # Try to decode
        try:
            field_str = field.decode('ascii')
            print(f"Field {i}: len={length}, data='{field_str}'")
        except:
            print(f"Field {i}: len={length}, data={field[:min(50, len(field))]}")
        
        if offset > 500:
            break

print("\n=== Analyzing Sound0 ===")
with ole.openstream(['GameStg', 'Sound0']) as s:
    data = s.read()
    
    # Parse the structure manually
    offset = 0
    for i in range(10):  # First 10 fields
        if offset >= len(data):
            break
            
        # Read 4-byte length
        length = struct.unpack('<I', data[offset:offset+4])[0]
        offset += 4
        
        # Read the field
        field = data[offset:offset+length]
        offset += length
        
        # Try to decode
        try:
            field_str = field.decode('ascii')
            print(f"Field {i}: len={length}, data='{field_str}'")
        except:
            print(f"Field {i}: len={length}, data={field[:min(50, len(field))]}")
        
        if offset > 500:
            break

ole.close()
