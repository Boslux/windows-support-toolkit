# Windows Support Toolkit

A lightweight PowerShell toolkit for Windows support technicians. It collects read-only system, disk, network, service, device and recent event-log information, runs basic network diagnostics, and exports support reports as JSON or HTML.

## Requirements

- Windows 10/11 or Windows Server with Windows PowerShell 5.1 (PowerShell 7 on Windows should also work).
- No third-party modules are required.
- Some event-log details may be unavailable to a non-administrator. Run elevated only when your support policy requires it.

## Start

Double-click `launcher.bat`, or run from PowerShell:

```powershell
.\scripts\launcher.ps1
```

The interactive menu keeps the individual system, network, disk, service and device checks and adds a full report, network diagnostics, recent System log errors, and service-name queries.

## Command line

Run one or more check groups and optionally save a report:

```powershell
.\scripts\launcher.ps1 -Check System,Disk,Network,Services,Drivers,Events,Diagnostics -OutputPath .\reports\support.html
```

Report checks are `System`, `Disk`, `Network`, `Services`, `Drivers`, `Printers`, `Events`, and `Diagnostics`. Omit `-Check` to run all groups. Supported report extensions are `.json`, `.html`, and `.htm`.

```powershell
# JSON summary report; identifying details are not collected
.\scripts\launcher.ps1 -OutputPath .\reports\support.json

# Query selected services and check specified host:port endpoints (port defaults to 443)
.\scripts\launcher.ps1 -Check Services,Diagnostics -ServiceName Spooler,WinRM -Target helpdesk.example.com:443,10.0.0.20:3389

# Recent System log errors from the last 3 days, up to 50 events
.\scripts\launcher.ps1 -Check Events -EventDays 3 -EventLimit 50 -OutputPath .\reports\events.html
```

The toolkit avoids collecting direct identifiers such as computer name, serial number, IP/MAC addresses, device IDs, printer names, print-document names, and event messages. Reports contain summary health data only; user-supplied TCP targets are checked but their values are not included in output. DNS and TCP checks still make network requests to perform the requested diagnostics.

The batch launcher starts PowerShell with a process-scoped execution policy so the menu can run without changing the machine's PowerShell policy. Organizational Group Policy can still prevent scripts from running. For command-line options, invoke `scripts\launcher.ps1` directly from PowerShell.

## Diagnostic interpretation

- Network adapter reporting returns only the number of enabled adapters; it does not show addresses or adapter names.
- DNS lookup checks resolution of `www.microsoft.com` without recording the resolved address.
- TCP checks attempt a connection to each `-Target` host and port without including target values in results.
- Device checks list Plug and Play devices with a non-zero Configuration Manager error code.
- Printer checks report only the total number of configured printers and counts by status; printer and document names are not included.
- Event checks summarize Error and Critical event counts by level and ID, without retaining timestamps or message text.
- Disk and service checks are read-only. The toolkit does not modify system settings or start/stop services.

## Project structure

```text
windows-support-toolkit/
├── launcher.bat
├── README.md
└── scripts/
    ├── launcher.ps1
    ├── SupportToolkit.psm1
    ├── system-info.ps1
    ├── network-info.ps1
    ├── disk-check.ps1
    ├── service_check.ps1
    └── driver-check.ps1
```
