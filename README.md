# Windows Support Toolkit

A lightweight PowerShell-based Windows support toolkit for collecting basic system, network, disk, service, and driver health information.

## Purpose

This project is designed to help a support technician quickly gather key information about a Windows machine during troubleshooting or initial diagnostics.

## Included checks

- System information
- Network information
- Disk usage
- Service status
- Driver/device status

## Project structure

```text
windows-support-toolkit/
├── scripts/
│   ├── system-info.ps1
│   ├── network-info.ps1
│   ├── disk-check.ps1
│   ├── service_check.ps1
│   ├── driver-check.ps1
│   ├── launcher.ps1
│   └── ...
├── launcher.bat
```

## How to run

From PowerShell:

```powershell
cd "d:\MyApps\Windows Support Toolkit\scripts"
.\launcher.ps1
```

Or double-click the launcher batch file:

```text
launcher.bat
```

## Notes

This is a simple troubleshooting toolkit intended for learning, support workflows, and basic diagnostics in a Windows environment.
