-- ============================================================================
-- Title: OBS Replay Buffer Sound Notifications
-- Author: [gligavac810]
-- Created with the assistance of AI
-- Version: 1.0.0
-- Description: Lightweight Lua script for OBS Studio (Windows) to play
--              distinct audio cues for Replay Buffer events.
-- ============================================================================

local obs = obslua
local ffi = require("ffi")

-- Paths to the three separate .wav files in the script folder
PROP_START_SOUND = script_path() .. "replay_start.wav"
PROP_SAVE_SOUND  = script_path() .. "replay_save.wav"
PROP_STOP_SOUND  = script_path() .. "replay_stop.wav"

-- Load the Windows multimedia library
local winmm = ffi.load("winmm")

ffi.cdef[[
    bool PlaySoundA(const char *pszSound, void *hmod, uint32_t fdwSound);
]]

function playsound(filepath)
    -- 0x0002 = SND_ASYNC (prevents OBS from freezing during playback)
    -- 0x00020000 = SND_FILENAME
    winmm.PlaySoundA(filepath, nil, 0x0002 + 0x00020000)
end

function on_event(event)
    -- 1. Play sound when the Replay Buffer is started
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
        playsound(PROP_START_SOUND)
        
    -- 2. Play sound when a clip is successfully saved
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        playsound(PROP_SAVE_SOUND)
        
    -- 3. Play sound when the Replay Buffer is completely stopped
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
        playsound(PROP_STOP_SOUND)
    end
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
end

function script_description()
    return "All-in-one script: Plays distinct sound notifications for starting, saving, and stopping the OBS Replay Buffer.\n\nCreated by [Tvoje Ime] & AI"
end
