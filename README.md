Actually it is possible to boot Windows with [MrChromebox's RW_LEGACY Payload](https://docs.mrchromebox.tech/docs/getting-started.html), without unlock WP, without UEFI Full ROM!

Note: If you are on a AMD Zen2 based chromebook, you can also check this Coolstar's ACPI patching solution: https://coolstar.org/chromebook/windows-rwl/install-rwl.sh 

(Looks like this script is designed to be run on ChromeOS, and automatically download OpenCore & ACPI Patch, create EFI partition, etc)

## What works / doesn't work

The whole thing I was working on my Acer Chromebook Plus 512 (roric, Intel N355/Alder Lake-N/Twin Lake), since I only have this. For similar platforms it might behave similar, you can use the similar idea and have a try.

| Feature              | Remark                             |
| -------------------- | ---------------------------------- |
| ☑️Boot               | ⚠️By disabling `intelpep`         |
| ☑️Battery indicator  | ⚠️By patching ACPI                |
| ☑️Screen backlight   | ⚠️By patching ACPI                |
| ☑️Keyboard backlight | ⚠️By custom drievr                |
| ✅WIFI               | ✅Just works by installing driver |
| ✅GPU                | ✅Just works by installing driver |
| ☑️Bluetooth          | ✅Disable power management        |
| ☑️Audio              | ✅By Coolstar's driver            |
| ⚠️Sleep              | ⚠️Partially                       |
| ✅Hibernate          | ✅Works                           |
| ✅Auto boot Windows  | ✅Possible!                       |

## 1. Boot
If your device also able to boot into the install media/WinPE/Safe Mode in RW_LEGACY, that is a good signal, means at least, the minimal/basic Windows is happy with that.

That means, if you unable to boot into full installed Windows in normal mode, should be caused by some drivers(services), which is not loaded in WinPE/Safe Mode. We can find out which one and disabled it.

On my device with RW_LEGACY, it can boot into Windows 11 Installer/WinPE. But after installed and boot into the normal Windows, BSOD: `INTERNAL_POWER_ERROR (0x000000A0)`.

Some of the models/Windows versions might show `ACPI_BIOS_ERROR (0x000000A5)`, which all indicates a ACPI/Power related issue. 

For my `roric` device, I can boot into Windows normal mode by disabling `intelpep` driver.
After the Windows installation, you can boot into the install media/WinPE, open registry, mount `C:\Windows\System32\config\system` for editing. Then set 

```
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\intelpep]
"Start"=dword:00000004
```

Then you will be able to boot into Windows/continue the installation in normal mode. If still not, you have to figure out what is the blocker.

Once you are able to boot into Windows & the installation is finished. Go to `Device Manager`

<img width="1265" height="556" alt="image" src="https://github.com/user-attachments/assets/6e4543d0-64bd-436c-9769-a20f5c88f5e8" />

Switch the `Intel(R) Power Engine Plug-in` with warning symbol to `Standard Power Management Controller` driver. Otherwise the `intelpep` might be re-enabled automatically by Windows/driver updates.

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
You can try [Coolstar's EC & Keyboard driver](https://coolstar.org/chromebook/) first.

If it doesn't work, try my keyboard brightness driver & userland program. Check: https://github.com/liyafe1997/chromebook-windows-keyboard-backlight 

## 5. Audio
Coolstar's driver works on my machine. If you don't want to pay, check https://github.com/akibaGumi/akibaPatcher

If you found your speaker works but crappy, you may have a `rt5650` codec but lack of driver.

Tick `Show hidden devices` in Device Manager.
<img width="278" height="327" alt="{B8E96425-D9AB-4FAA-9959-4022B8FE3472}" src="https://github.com/user-attachments/assets/b54feb58-adf1-4674-9cef-18e3d2653af2" />

And check if you have `ACPI\10EC5650` under `Other devices`.

If you found it and it lack of driver, try this [rt5650.zip](https://github.com/liyafe1997/chromebook_rw_legacy_windows/raw/refs/heads/master/rt5650.zip)

## 6. Bluetooth
On my machine, once the `Intel Bluetooth` driver loaded, it would always jumping/toggling appear/disapper. If you also have this problem, untick this `Allow the computer to turn off this device to save power`.

<img width="490" height="585" alt="image" src="https://github.com/user-attachments/assets/121470f1-3b4a-4a77-b2a8-de8a53161115" />

If you feel hard to do that(you need to do it quickly, you have to save the setting within the time window of the device appeared), you can also try:
```
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_USB USBSELECTIVE SUSPEND 0
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_USB USBSELECTIVE SUSPEND 0
powercfg /SETACTIVE SCHEME_CURRENT
```

## 7. Sleep / Hibernate
In Windows it looks like support `s0ix`, but mostly only software, which means Windows can enter `s0ix` mode, it may limits some background activities, disconnect WIFI (if you set `Disconnected Standby`), but due to the lack of ACPI and `intelpep` driver, it can not really put the whole platform into a really low power status, so the power consumption can be higher than expected.

Basically, you can use the `Sleep` feature as a advanced `Screen Off` feature for temporary away. 

The good thing is `Hibernate` is working! So if you really need a low power status for a long-term away, you can use `Hibernate`.

## 8. Automatically boot into RW_LEGACY / Alternate Bootloader
It is possible without unlocking WP or set GBB flags!

Simply do 
```bash
sudo crossystem dev_default_boot=altfw
# or 
sudo crossystem dev_default_boot=legacy # could be for old platform.
```
In ChromeOS.

You can also run `sudo crossystem` check it has been set or not.

It can not remove the developer screen, but it can make the cursor choose `Select alternate bootloader` by default and automatically boot it after 1 minute timeout.
This is really helpful if you are working on a remote `RW_LEGACY` Chromebook and you reboot it remotely, it can automatically boot into the `RW_LEGACY` firmware/payload.

Note: looks like the `crossystem` set things only works in ChromeOS(I tested on Ubuntu, it only able to read but refuse to write), so better to do that before you have erased the ChromeOS. 

If you have already erased ChromeOS and don't want to restore it just for this simple thing (because restoring ChromeOS will erase your whole disk), you can try [FydeOS USB LiveCD](https://fydeos.io/download/), which is another ChromiumOS based project. I tested `crossystem` works in `FydeOS 22.1` on my Chromebook.
