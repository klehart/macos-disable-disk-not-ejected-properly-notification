# macOS: Disable "Disk Not Ejected Properly" Notification

A small shell script that changes how macOS shows the **"Disk Not Ejected Properly"** notification: turn it off, make it a banner that disappears on its own, or keep it as an alert.

By default macOS shows this message as an **alert** that stays on screen until you close it, and it does not appear in Notification Center. The message is sent by a system service (`DiskArbitrationAgent`) that is **not listed** in *System Settings → Notifications*, so you cannot change it there. This script changes it for you.

## What you can change

| Setting | Options |
|---|---|
| Style | None · Banners (disappear automatically) · Alerts (stay until dismissed) |
| Show on Lock Screen | yes / no |

## Requirements

- macOS (only built-in tools are used: `bash`, `defaults`, `PlistBuddy`, `killall`)
- The "Disk Not Ejected Properly" message must have appeared **at least once** on the Mac, otherwise macOS has no settings entry for it yet
- No admin rights needed, the script only changes settings of the current user

## Usage

1. Download `eject-notification-style.sh`
2. Open Terminal and run:

   ```bash
   bash ~/Downloads/eject-notification-style.sh
   ```

3. The script shows the current settings and asks what you want:

   ```
   Notification settings for "Disk Not Ejected Properly"

     Style:               Alerts
     Show on Lock Screen: yes

   Style:
     1) None     - no notification
     2) Banners  - disappears automatically
     3) Alerts   - stays until dismissed
   Choice (1-3, Enter = keep "Alerts"): 2

   Show on Lock Screen? (y/n, Enter = keep "yes"):
   ```

   Pressing **Enter** keeps the current value. If nothing changes, nothing is written.

You can also pass the style directly (the Lock Screen question is still asked):

```bash
bash eject-notification-style.sh banners   # none, banners or alerts
```

## Undo

Before every change the script saves a backup:

```
~/Library/Preferences/com.apple.ncprefs.backup-<date>.plist
```

To restore one:

```bash
defaults import com.apple.ncprefs ~/Library/Preferences/com.apple.ncprefs.backup-<date>.plist
killall usernoted NotificationCenter
```

Or simply run the script again and pick the old values.

## How it works

macOS stores notification settings per app in `~/Library/Preferences/com.apple.ncprefs.plist`. Each entry has a `flags` number in which every setting is one bit. Apple does not document these bits. They were worked out by toggling settings in System Settings and comparing the values:

| Bit | Meaning |
|---|---|
| 0 | Do **not** show in Notification Center |
| 3–5 | Style: 0 = None, 1 = Banners, 2 = Alerts |
| 8 | Probably a marker that the Notification Center setting was changed by the user (set by the script as well) |
| 12 | Do **not** show on Lock Screen |
| 25 | Allow notifications |

The script exports the settings, changes only the bits of the `_SYSTEM_CENTER_:com.apple.DiskArbitration.DiskArbitrationAgent` entry with `PlistBuddy`, imports them again and restarts the notification services.

## Tested on

| | |
|---|---|
| Mac | Apple Silicon |
| macOS | 15 Sequoia |
| Shell | `/bin/bash` 3.2 (the version included with macOS) |

| Option | Result |
|---|---|
| Style (Banners) | ✅ Works |
| Show in Notification Center | ❌ No effect. The setting was saved, but the notification never showed up in Notification Center, not even while the disk was still disconnected. The option was therefore removed from the script. |
| Show on Lock Screen | Not tested yet |

## Limitations

- **Undocumented format.** A future macOS version may store these settings differently. If the script reads a style value it does not understand, it stops without changing anything.
- **Managed Macs.** On Macs managed by a company or school (MDM), a configuration profile may override notification settings.
- **Major updates** can reset the settings. Just run the script again.

Use at your own risk.

## License

[MIT](LICENSE)
