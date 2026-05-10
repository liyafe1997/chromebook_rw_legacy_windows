Actually it is possible to boot Windows with [MrChromebox's RW_LEGACY Payload](https://docs.mrchromebox.tech/docs/getting-started.html), without unlock WP, without UEFI Full ROM!

Note: If you are on a AMD Zen2 based chromebook, you can also check this Coolstar's ACPI patching solution: https://coolstar.org/chromebook/windows-rwl/install-rwl.sh 

(Looks like this script is designed to be run on ChromeOS, and automatically download OpenCore & ACPI Patch, create EFI partition, etc)

## What works/ doesn't work

The whole thing I was working on my Acer Chromebook Plus 512 (roric, Intel N355/Alder Lake-N/Twin Lake), since I only have this. For similar platforms it might behave similar, you can use the similar idea and have a try.

| Feature             | Remark                           |
| ------------------- | -------------------------------- |
| ☑️Boot               | ⚠️By disabling `intelpep`         |
| ☑️Battery indicator  | ⚠️By patching ACPI                |
| ☑️Screen backlight   | ⚠️By patching ACPI                |
| ☑️Keyboard backlight | ⚠️By custom drievr                |
| ✅WIFI               | ✅Just works by installing driver |
| ✅GPU                | ✅Just works by installing driver |
| ☑️Bluetooth          | ✅Disable power management        |
| ☑️Audio              | ✅By Coolstar's driver            |

## 1. Boot
If your device also able to boot into the install media/WinPE/Safe Mode in RW_LEGACY, that is a good signal, means at least, the minimal/basic Windows is happy with that.

That means, if you unable to boot into full installed Windows in normal mode, should be caused by some drivers(services), which is not loaded in WinPE/Safe Mode. We can find out which one and disabled it.

On my device with RW_LEGACY, it can boot into Windows 11 Installer/WinPE. But after installed and boot into the normal Windows, BSOD: `INTERNAL_POWER_ERROR (0x000000A0)`.

Some of the models/Windows versions might show `ACPI_BIOS_ERROR (0x000000A5)`, which all indicates a ACPI/Power related issue. 

For my `roric` device, I can boot into Windows normal mode by disabling `intelpep` driver.
After the Windows installation, you can boot into the install media/WinPE, open registry, mount `C:\Windows\System32\config\system` for editing. Then set 

```
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\intelpep]
"Start"=dword:00000000
```

Then you will be able to boot into Windows/continue the installation in normal mode. 

If still not, you have to figure out what is the blocker.

## 2. Battery Indicator/Charging status
According to Microsoft's [ACPI implementation requirements](https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/acpi-firmware-implementation-requirements), Windows only happy with `Power Unit = 0 (mW/mWh)`, but the stock Chromebook coreboot firmware's ACPI is reporting `Power Unit = 1 (mA/mAh)`. That is the reason why Windows does not display the battery indicator and level.

So we have to patch the ACPI, contver the unit from mA/mAh to mW/mWh. This has been done in `EFI\OC\ACPI\SSDT-BATX.aml`

## 3. Internal screen backlight adjustment
Similar, Windows requires the panel in ACPI `\_SB.PCI0.GFX0.LCD0` has `_BCL _BCM _BQC` methods, also `_DOD=0x80010400 / _ADR=0x400` means that is a internal panel and supports brightness control. 

But stock coreboot firmware ACPI is lack of that. So we need to fill in this to make Windwos happy :) 

The patch is `EFI\OC\ACPI\SSDT-BRTFIX.aml`

You can just use my `config.plist` and boot OpenCore.efi, it will apply these patches and chainload Windows.

If you like to automatically boot OpenCore, you can put the `EFI\BOOT\BOOTx64.efi` into the same directory of your EFI partition.

For OpenCore, check: https://github.com/acidanthera/OpenCorePkg/releases/

These patches and config are tested on [OpenCore 1.0.7](https://github.com/acidanthera/OpenCorePkg/releases/tag/1.0.7). You can also just use the binary in this repo.

## 4. Keyboard backlight adjustment.
You can try [Coolstar's EC & Keyboard driver](https://coolstar.org/chromebook/) first, if it doesn't work, try my keyboard brightness driver & userland program.

## 5. Audio
Coolstar's driver works on my machine. If you don't want to pay, check https://github.com/akibaGumi/akibaPatcher
