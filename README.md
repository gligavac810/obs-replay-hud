# OBS Studio - Replay Buffer Sound Notifications

A lightweight, native Lua script for **OBS Studio (Windows)** that plays distinct audio cues when you start, save, or stop the Replay Buffer. No heavy plugins like Advanced Scene Switcher required.

---

## 🚀 Installation & Setup

1. **Download the Script:** Download `replay_notifications.lua` and save it anywhere on your PC.
2. **Prepare Your Audio Cues:** 
   * Get 3 sound effects in **`.wav`** format. *(Compressed formats like .mp3 are not supported by the Windows API used in this script).*
   * Rename your files exactly to:
     * `replay_start.wav` (plays when the buffer starts)
     * `replay_save.wav` (plays when a clip is successfully saved)
     * `replay_stop.wav` (plays when the buffer stops)
3. **Place Everything Together:** Move your 3 `.wav` files into the **exact same folder** where you placed `replay_notifications.lua`.
4. **Load into OBS:**
   * Open OBS Studio and go to **Tools > Scripts**.
   * Click the **`+`** (Plus) icon.
   * Select `replay_notifications.lua` and click **Open**.

---

## 🛠️ Customizing the Script

### Changing Audio File Names
If you want to use different names for your audio files, open `replay_notifications.lua` in any text editor (like Notepad) and change the filenames inside the quotes on lines 4, 5, and 6:
```lua
PROP_START_SOUND = script_path() .. "your_custom_start_name.wav"
PROP_SAVE_SOUND  = script_path() .. "your_custom_save_name.wav"
PROP_STOP_SOUND  = script_path() .. "your_custom_stop_name.wav"
```
*Remember to click **Reload** in the OBS Scripts window after saving your changes.*

---

## 🤖 Disclaimer / AI Notice
This project was developed with the assistance of **AI** to ensure proper integration with the Windows Multimedia library (`winmm.dll`) and to prevent OBS performance issues using non-blocking asynchronous audio playback.

## 📄 License
MIT License. Feel free to modify, distribute, and use it in your streams!
