# OBS Replay HUD (Heads-Up Display)

A lightweight, zero-plugin ecosystem for **OBS Studio (Windows)** that gives you both **instant audio cues** and a **sleek visual screen overlay** whenever you start, stop, or save a clip using the Replay Buffer. 

No heavy streaming plugins (like Advanced Scene Switcher) or external alert platforms required. It runs natively and quietly in the background without affecting your gaming performance.

---

## 📂 What is Inside the Package

This project consists of two seamlessly interconnected parts:

### 1. Audio Notification Engine
*   `replay_notifications.lua` — The core OBS Lua script that listens to Replay Buffer events and triggers asynchronous, non-blocking audio files.

### 2. Visual Overlay System
*   `ReplayOverlay.ps1` — A script (PowerShell + WPF) that renders a clean notification card directly on your screen. It is built to stay always-on-top, never steal your keyboard/mouse focus, and features click-through support so it won't interrupt your gameplay.
*   `replay_overlay_events.lua` — A small OBS helper script that communicates with the visual overlay to tell it exactly when to pop up on your screen. It runs beautifully alongside your audio scripts.
*   `Start Overlay.vbs` — A silent launcher script that triggers the screen overlay in the background, completely hiding any ugly black command-prompt windows.

---

## 🚀 Installation & Setup Guide

### Step 1: Set Up the Visual Overlay Files
1. Create a dedicated folder on your computer to store the tools (e.g., `C:\Tools\ReplayOverlay\`).
2. Move **`ReplayOverlay.ps1`** and **`Start Overlay.vbs`** together into that exact folder.

### Step 2: Set Up Audio Cues & OBS Scripts
1. Prepare 3 notification sounds in **`.wav`** format. *(Compressed formats like .mp3 are not supported by the native Windows audio engine used here).*
2. Rename your sound files exactly to:
   *   `replay_start.wav` (buffer turned on)
   *   `replay_save.wav` (clip successfully captured)
   *   `replay_stop.wav` (buffer turned off)
3. Move your 3 `.wav` files into the **exact same folder** where your Lua scripts (`replay_notifications.lua` and `replay_overlay_events.lua`) are located. *(Note: The Lua scripts can live anywhere, but they must be in the same folder as your audio files).*
4. Open OBS Studio and navigate to **Tools > Scripts**.
5. Click the **`+`** (Plus) icon and add both **`replay_notifications.lua`** and **`replay_overlay_events.lua`**.

### Step 3: Launch & Test
1. Double-click **`Start Overlay.vbs`** to launch the overlay silently in the background.
2. A small system tray icon will appear next to your Windows clock (if hidden, check the `^` arrow icon).
3. **To test:** Right-click the tray icon and select **Prikaži test** (Show Test). This will cycle through all three overlay notification states consecutively on your screen to verify everything works.
4. *(Optional)* To close the overlay completely, right-click that same tray icon and select **Izađi** (Exit).

### Step 4: Automatic Startup (Recommended)
To make the overlay open automatically every time you turn on your PC:
1. Press `Win + R` on your keyboard, type **`shell:startup`**, and hit Enter.
2. Create a **shortcut** pointing to your `Start Overlay.vbs` file and drop that shortcut inside this folder.

---

## 💡 Good to Know / Troubleshooting

*   **Windows Security:** If Windows SmartScreen blocks the files after downloading, right-click the file -> select **Properties** -> check **Unblock** -> click **Apply**.
*   **Game Display Mode:** Just like Python overlays, this visual indicator renders seamlessly over games running in **Windowed** or **Borderless** modes. Due to Windows architecture, overlays cannot draw over games running in strict *Exclusive Fullscreen* mode.
*   **Launch Order:** You can start the overlay launcher before or after opening OBS Studio—it does not matter, they will auto-sync!
*   **Error Logs:** If something goes wrong or the test notification fails to show up, the system writes errors directly to a log file located at: `%TEMP%\obs_replay_overlay.log`. Please check this file or send it to us if you need help troubleshooting.

---

## 🤖 AI Development Notice
This entire ecosystem (both the asynchronous Windows audio integration and the WPF click-through screen overlay system) was developed with the assistance of **AI**. This joint human-AI effort ensures minimal CPU overhead, flawless background launching, and maximum compatibility with modern streaming setups.

## 📄 License
MIT License. Feel free to modify, style, fork, and use it to elevate your streams!
