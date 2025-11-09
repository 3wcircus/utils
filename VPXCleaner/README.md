# VPX Cleaner

A Python utility to identify and report unused images and sounds in Visual Pinball VPX files, helping you significantly reduce file sizes.

## Features

- 📊 **Scan VPX files** to identify all imported images and sounds
- 🔍 **Detect unused assets** by analyzing table data and script references
- 💾 **Calculate potential space savings** with detailed size information
- 📄 **Generate removal reports** listing all unused assets
- 🎯 **Accurate detection** using proper VPX binary format parsing

## Requirements

```bash
pip install olefile
```

## Usage

### Scan Only (Default)
Analyze a VPX file and display unused assets:

```bash
python vpxcleaner.py table.vpx
```

### Generate Removal Report
Create a text file listing all unused assets for manual removal:

```bash
python vpxcleaner.py table.vpx --remove
```

or

```bash
python vpxcleaner.py table.vpx -r
```

## Output Example

```
======================================================================
VPX CLEANER - Visual Pinball Asset Analyzer
======================================================================

📁 Analyzing VPX file...
   File: OnePieceBlues.test.vpx
   Size: 88.74 MB

Found 106 images
Found 149 sounds

======================================================================
CHECKING FOR UNUSED ASSETS...
======================================================================

🖼️  Unused Images: 75 (65.87 MB)
🔊 Unused Sounds: 110 (13.60 MB)

======================================================================
💾 Total potential space savings: 79.47 MB
   (89.6% of file size)
======================================================================
```

## How It Works

1. **Parses VPX OLE File Structure**: Opens the VPX file as an OLE compound document
2. **Extracts Asset Names**: Reads asset names from binary streams using proper TLV format parsing
3. **Analyzes Table Data**: Searches all game data, scripts, and object definitions for asset references
4. **Identifies Unused Assets**: Compares imported assets against references to find unused ones
5. **Calculates Savings**: Reports exact file sizes and potential space savings

## Removing Unused Assets

Currently, automatic removal is not supported due to limitations in the `olefile` library. Use the generated removal report to manually delete unused assets:

1. Run: `python vpxcleaner.py table.vpx --remove`
2. Open the VPX file in Visual Pinball
3. Open the Image Manager (Ctrl+I) or Sound Manager (Ctrl+U)
4. Select and delete the unused assets listed in the report
5. Save the table

## Limitations

- Automatic asset removal requires OLE file write support (not available in current `olefile` version)
- Very complex or obfuscated references may not be detected
- Assets referenced only in comments or unused code will be flagged as unused

## Technical Details

- **VPX Format**: VPX files use Microsoft's OLE (Object Linking and Embedding) compound document format
- **Asset Storage**: Images stored in `GameStg/Image*` streams, sounds in `GameStg/Sound*` streams
- **Binary Parsing**: Uses proper TLV (Type-Length-Value) parsing to extract asset names
- **Reference Detection**: Case-insensitive string matching across all game data

## Example Test Results

From the test file `OnePieceBlues.test.vpx`:
- Original size: 88.74 MB
- Unused images: 75 (65.87 MB)
- Unused sounds: 110 (13.60 MB)
- **Potential savings: 89.6%** 🎉

## Contributing

Contributions are welcome! Especially:
- Implementing proper OLE file write support for automatic removal
- Improving asset reference detection algorithms
- Adding support for additional asset types

## License

MIT License - Feel free to use and modify as needed.

## Author

Created as a utility for the Visual Pinball community to help reduce bloated table file sizes.
