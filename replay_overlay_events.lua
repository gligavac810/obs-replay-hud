-- Replay Overlay: sends Replay Buffer events (started / stopped / saved)
-- to the overlay (ReplayOverlay.ps1) through a small file in %TEMP%.
-- Does not interfere with your existing sound scripts; they can run side by side.

obs = obslua

local sig_path = (os.getenv("TEMP") or ".") .. "\\obs_replay_overlay.txt"
local counter = 0

local function push(kind, extra)
	counter = counter + 1
	local f = io.open(sig_path, "w")
	if f then
		-- format: type|path|unique-id
		f:write(kind .. "|" .. (extra or "") .. "|" .. tostring(os.time()) .. "-" .. tostring(counter))
		f:close()
	end
end

local function on_event(event)
	if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED then
		push("started")
	elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED then
		push("stopped")
	elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
		local path = obs.obs_frontend_get_last_replay()
		push("saved", path or "")
	end
end

function script_description()
	return "Sends Replay Buffer events to the overlay (ReplayOverlay.ps1)."
end

function script_load(settings)
	obs.obs_frontend_add_event_callback(on_event)
end

function script_unload()
	obs.obs_frontend_remove_event_callback(on_event)
end
