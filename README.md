# Visual C++ Redistributable Updater

A comprehensive PowerShell script that automatically detects, downloads, and updates all Visual C++ Redistributable packages (2005-2022) on Windows systems.

## Features

- ✅ **Comprehensive Coverage**: Supports all major Visual C++ versions (2005, 2008, 2010, 2012, 2013, 2015-2022)
- ✅ **Intelligent Detection**: Only updates packages that are actually installed and need updating
- ✅ **Silent Installation**: Runs completely unattended with no user interaction required
- ✅ **Version Comparison**: Smart version checking to avoid unnecessary downloads and installations
- ✅ **Administrative Privileges**: Automatically requires and validates admin rights
- ✅ **Clean Operation**: Automatically cleans up temporary files after completion
- ✅ **EOL Support**: Handles end-of-life versions with fixed target versions
- ✅ **Active Monitoring**: Dynamically checks latest versions for actively maintained redistributables

## Supported Versions

| Version | Status | Target Version | Notes |
|---------|--------|----------------|-------|
| Visual C++ 2005 | EOL | 8.0.50727.6195 | KB2538242 - Final security update |
| Visual C++ 2008 | EOL | 9.0.30729.5677 | KB2538243 - Final security update |
| Visual C++ 2010 | EOL | 10.0.40219 | KB2565063 - Final security update |
| Visual C++ 2012 | Active | Dynamic | Update 4 - Latest available |
| Visual C++ 2013 | Active | Dynamic | Latest available |
| Visual C++ 2015-2022 | Active | Dynamic | Latest unified redistributable |

## Requirements

- Windows operating system
- PowerShell 5.0 or later
- Administrative privileges
- Internet connection for downloads

## Usage

### One-Liner (Run as Administrator)

```powershell
# Recommended: URL-safe filename (avoids encoding issues)
powershell -ExecutionPolicy Bypass -Command "iex (Invoke-RestMethod 'https://raw.githubusercontent.com/monobrau/visualcplusplusupdater/main/visualcpp-updater.ps1')"

# Alternative: direct script with URL-encoded filename
powershell -ExecutionPolicy Bypass -Command "iex (Invoke-RestMethod 'https://raw.githubusercontent.com/monobrau/visualcplusplusupdater/main/visualc%2B%2Bupdater.ps1')"
```

### Basic Usage

1. **Download the script** to your preferred directory
2. **Open PowerShell as Administrator**
3. **Navigate to the script directory**
4. **Run the script:**

```powershell
.\visualc++updater.ps1
```

### Advanced Usage

The script can be integrated into deployment scripts, scheduled tasks, or system maintenance routines:

```powershell
# Run with execution policy bypass
powershell -ExecutionPolicy Bypass -File ".\visualc++updater.ps1"

# Run silently in background
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PWD\visualc++updater.ps1`"" -Verb RunAs -WindowStyle Hidden
```

## How It Works

### Detection Phase
1. **Registry Scan**: Searches Windows registry for installed Visual C++ redistributables
2. **Version Analysis**: Compares installed versions with target versions
3. **Architecture Detection**: Identifies both x86 and x64 installations
4. **KB Validation**: Checks for security update KB numbers (EOL versions)

### Update Phase
1. **Smart Downloads**: Only downloads installers when version checking is needed
2. **Version Comparison**: Compares downloaded installer versions with installed versions
3. **Silent Installation**: Runs installers with appropriate silent parameters
4. **Progress Tracking**: Provides detailed progress information
5. **Cleanup**: Removes temporary installer files

### Silent Installation Parameters

| Version | Arguments | Description |
|---------|-----------|-------------|
| 2005 | `/Q` | Quiet installation |
| 2008-2010 | `/quiet /norestart` | Quiet with no restart |
| 2012+ | `/install /quiet /norestart` | Modern silent installation |

## Sample Output

```
=============================================
Visual C++ All Versions Updater (2005-2022)
=============================================

Scanning for installed Visual C++ redistributables...

Visual C++ 2010 [EOL] (KB2565063):
  [x86] INSTALLED
        Current Version: 10.0.40219
        Status: UP TO DATE (will skip)
  [x64] INSTALLED
        Current Version: 10.0.40219
        Status: UP TO DATE (will skip)

Visual C++ 2015-2022 [Active] (Latest):
  [x86] INSTALLED
        Current Version: 14.44.35211.0
        Status: Will check latest version dynamically

Total updates to process: 2

=============================================
Beginning updates...
=============================================

[1/2] Processing x86 version...
  Downloading...
  Download complete.
  Downloaded version: 14.44.35211.0
  Current version (14.44.35211.0) is up to date - Skipping installation

=============================================
Update process completed.
=============================================
```

## Error Handling

The script includes comprehensive error handling:

- **Network Issues**: Graceful handling of download failures
- **Permission Errors**: Clear messaging for insufficient privileges
- **Installation Failures**: Detailed exit code analysis
- **Registry Access**: Safe registry operations with error recovery

## Security

- **Official Sources**: All downloads are from official Microsoft URLs
- **Integrity Checking**: Version validation before installation
- **Administrative Validation**: Requires elevated privileges
- **Safe Cleanup**: Secure temporary file handling

## Troubleshooting

### Common Issues

**"Script requires elevation"**
- Solution: Run PowerShell as Administrator

**"Execution Policy Restricted"**
- Solution: Use `-ExecutionPolicy Bypass` parameter

**"Download Failed"**
- Check internet connection
- Verify firewall/proxy settings
- Ensure access to Microsoft download servers

**"Installation Failed"**
- Verify administrative privileges
- Check for conflicting installations
- Review Windows Event Logs for details

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Guidelines

1. Maintain backward compatibility
2. Follow PowerShell best practices
3. Include comprehensive error handling
4. Update documentation for new features
5. Test on multiple Windows versions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### Version 2.0 (Current)
- ✅ Fixed Visual C++ 2010 false positive update detection
- ✅ Enhanced silent installation parameters
- ✅ Improved version comparison logic
- ✅ Added comprehensive debug output
- ✅ Optimized download and installation process

### Version 1.0
- Initial release with basic functionality
- Support for all major Visual C++ versions
- Silent installation capabilities

## Acknowledgments

- Microsoft for providing official redistributable packages
- PowerShell community for best practices and techniques
- Contributors and users for feedback and improvements

---

**Note**: This script is designed for system administrators and advanced users. Always test in a controlled environment before deploying to production systems.
