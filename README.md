# OBS Replay HUD (Heads-Up Display)

A lightweight, zero-plugin ecosystem for **OBS Studio (Windows)** that gives you both **instant audio cues** and a **sleek visual screen overlay** whenever you start, stop, or save a clip using the Replay Buffer.

No heavy streaming plugins (like Advanced Scene Switcher) or external alert platforms required. It runs natively and quietly in the background without affecting your gaming performance.

---

## 📂 What is Inside the Package

This repository includes everything you need out of the box:

### 1. Audio Notification Engine
*   `replay_notifications.lua` — The core OBS Lua script that listens to Replay Buffer events and triggers asynchronous, non-blocking audio files.
*   **Default Sound Cues Included:** Three ready-to-use audio effects are pre-uploaded in this repository (`replay_start.wav`, `replay_save.wav`, and `replay_stop.wav`). You can easily replace them with your own sounds at any time!

### 2. Visual Overlay System
*   `ReplayOverlay.ps1` — A script (PowerShell + WPF) that renders a clean notification card directly on your screen. It is built to stay always-on-top, never steal your keyboard/mouse focus, and features click-through support so it won't interrupt your gameplay.
*   `replay_overlay_events.lua` — A small OBS helper script that communicates with the visual overlay to tell it exactly when to pop up on your screen.
*   `Start Overlay.vbs` — A silent launcher script that triggers the screen overlay in the background, completely hiding any command-prompt windows.

---

## 🚀 Installation & Setup Guide

### 📦 Step 1: Install & Organize the Files
To ensure OBS never loses track of your files and everything runs perfectly, we recommend putting all the project files into the central OBS configuration directory.

1. Press `Win + R` on your keyboard, paste the following path, and hit **Enter**:
   ```text
   %appdata%\obs-studio
   ```
   *(This automatically expands to your hidden `C:\Users\<YourUsername>\AppData\Roaming\obs-studio` directory).*
2. Look for a folder named **`scripts`**. **If it does not exist, create it manually.**
3. Extract and drop **ALL** downloaded files into this folder:
   *   `replay_notifications.lua`
   *   `replay_overlay_events.lua`
   *   `ReplayOverlay.ps1`
   *   `Start Overlay.vbs`
   *   The 3 `.wav` audio files

---

### 🎵 Step 2: Preparing Custom Audio Cues (Optional)
If you decide to swap our default sounds with your own custom audio clips, keep these strict rules in mind:
*   **Format Requirement:** Sound files must be uncompressed **`.wav`** format. (Compressed formats like `.mp3` will fail silently due to Windows API restrictions).
*   **Audio Conversion:** If your custom sound is an MP3, you can easily convert it online using [FreeConvert MP3 to WAV](https://www.freeconvert.com/mp3-to-wav).
*   **Naming Conventions:** Your custom sound files must be placed in the same folder and named exactly:
    *   `replay_start.wav` (plays when buffer turns on)
    *   `replay_save.wav` (plays when a clip is successfully captured)
    *   `replay_stop.wav` (plays when buffer turns off)

---

### ⚙️ Step 3: Activate in OBS Studio
1. Open OBS Studio and navigate to the top menu: **Tools > Scripts**.
2. Click the **`+`** (Plus) icon in the bottom-left corner.
3. Select and load both **`replay_notifications.lua`** and **`replay_overlay_events.lua`** from your scripts folder.

---

### 🖥️ Step 4: Launch & Test the HUD
1. Double-click **`Start Overlay.vbs`** inside your folder to launch the screen overlay silently.
2. A small system tray icon will appear next to your Windows taskbar clock (if hidden, check the `^` arrow icon).
3. **To test:** Right-click the tray icon and select **Prikaži test** (Show Test). This will cycle through all three overlay notification states consecutively on your screen to verify everything works.
4. **To exit:** To close the overlay completely, right-click that same tray icon and select **Izađi** (Exit).

---

### 🔄 Step 5: Run on Windows Startup (Recommended)
To make the visual overlay open automatically every single time you turn on your computer:
1. Press `Win + R` on your keyboard, type **`shell:startup`**, and hit **Enter**.
2. Right-click your **`Start Overlay.vbs`** file and click *Create shortcut*.
3. Cut and paste that newly created shortcut directly into the Windows Startup folder you just opened.

---

## 💡 Good to Know & Troubleshooting

*   **Windows Security Blocks:** If Windows SmartScreen blocks the script files after downloading them from GitHub, right-click the blocked file -> select **Properties** -> check **Unblock** -> click **Apply**.
*   **Game Display Mode:** Just like Python overlays, this visual indicator renders seamlessly over games running in **Windowed** or **Borderless** modes. Due to Windows desktop window architecture, overlays cannot draw over games running in strict *Exclusive Fullscreen* mode.
*   **Launch Order:** You can start the overlay launcher before or after opening OBS Studio—it does not matter, they will auto-sync instantly!
*   **Error Logs:** If something goes wrong or the test notification fails to show up, the system writes errors directly to a log file located at: `%TEMP%\obs_replay_overlay.log`.

---

## 🤖 AI Development Notice
This entire ecosystem (both the asynchronous Windows audio integration and the WPF click-through screen overlay system) was developed with the assistance of **AI**. This joint human-AI effort ensures minimal CPU overhead, flawless background launching, and maximum compatibility with modern streaming setups.

## 📄 License
MIT License. Feel free to modify, style, fork, and use it to elevate your streams!
