--[[============================================================================
-- Duplex.Application.Mlrx
============================================================================]]--

--[[--

Mlrx is a live performance loop sequencer.

#

[View the README.md](https://github.com/renoise/xrnx/blob/master/Tools/com.renoise.Duplex.xrnx/Docs/Applications/Mlrx.md) (github)

]]

--==============================================================================

-- global song reference 

rns = nil

--==============================================================================

class 'Mlrx' (Application)

-- constants

Mlrx.NUM_GROUPS = 4
Mlrx.VOID_GROUP = 5

Mlrx.MASTER_GROUP_NAME = "mlrx"

Mlrx.DRIFT_RANGE = 256
Mlrx.INT_8BIT = 255 
Mlrx.INT_7BIT = 127 -- track levels, MIDI input

-- option consts

Mlrx.GRP_VELOCITY_OFF = 1
Mlrx.GRP_VELOCITY_KEY_VEL = 2
Mlrx.GRP_VELOCITY_MIDI_VEL = 3
Mlrx.GRP_VELOCITY_MIDI_PRESS = 4
Mlrx.GRP_VELOCITY_MIDI_VEL_PRESS = 5
Mlrx.GRP_VELOCITY_PAD_X = 6
Mlrx.GRP_VELOCITY_PAD_Y = 7

Mlrx.TRK_VELOCITY_OFF = 1
Mlrx.TRK_VELOCITY_KEY_VEL = 2
Mlrx.TRK_VELOCITY_MIDI_VEL = 3
Mlrx.TRK_VELOCITY_MIDI_PRESS = 4
Mlrx.TRK_VELOCITY_MIDI_VEL_PRESS = 5
Mlrx.TRK_VELOCITY_PAD_X = 6
Mlrx.TRK_VELOCITY_PAD_Y = 7

Mlrx.GRP_PANNING_OFF = 1
Mlrx.GRP_PANNING_PAD_X = 2
Mlrx.GRP_PANNING_PAD_Y = 3

Mlrx.TRK_PANNING_OFF = 1
Mlrx.TRK_PANNING_PAD_X = 2
Mlrx.TRK_PANNING_PAD_Y = 3

Mlrx.COLLAPSE_TRACKS_ON = 1
Mlrx.COLLAPSE_TRACKS_AUTO = 2
Mlrx.COLLAPSE_TRACKS_OFF = 3

Mlrx.AUTOMATION_READ = 1
Mlrx.AUTOMATION_WRITE = 2
Mlrx.AUTOMATION_READ_WRITE = 3

Mlrx.ACTIVE_TRACK_MANUAL = 1
Mlrx.ACTIVE_TRACK_AUTO = 2

Mlrx.PLAY_ON_TRIG = 2

Mlrx.FOCUS_DISABLED = 1
Mlrx.FOCUS_TRACKS = 2
Mlrx.FOCUS_INSTR = 3
Mlrx.FOCUS_TRACKS_INSTR = 4

Mlrx.SAMPLE_PREP_ON = 1
Mlrx.SAMPLE_PREP_OFF = 2


-- include the supporting classes
require "Duplex/Applications/Mlrx/Mlrx_view"
require "Duplex/Applications/Mlrx/Mlrx_settings"
require "Duplex/Applications/Mlrx/Mlrx_group"
require "Duplex/Applications/Mlrx/Mlrx_note"
require "Duplex/Applications/Mlrx/Mlrx_pos"
require "Duplex/Applications/Mlrx/Mlrx_track"


Mlrx.default_options = {
  active_track = {
    label = "Track-select",
    description = "Determine how to select the active mlrx-track",
    items = {
      "Manually select",
      "Auto-select last triggered",
    },
    value = 2,
  },
  set_focus = {
    label = "Set Focus",
    description = "Determine how focus in Renoise follows the active mlrx-track",
    items = {
      "Disabled",
      "Active track",
      "Active instrument",
      "Active track + instr.",
    },
    value = 4,
  },

  collapse_tracks = {
    label = "Collapse tracks",
    description = "Determine if tracks in the pattern editor should be collapsed",
    items = {
      "Yes (collapse all tracks)",
      "Auto (collapse all but active)",
      "No (all tracks are expanded)",
    },
    value = 3,
    on_change = function(inst)
      if not inst.active then return false end
      inst:decorate_tracks()
    end,
  },
  midi_controller = {
    label = "MIDI-Input",
    description = "Specify a MIDI controller for transpose & triggering",
    items = {
      "None",
    },
    value = 1,
    on_change = function(inst)
      if not inst.active then return false end
      inst:select_midi_port(inst.options.midi_controller.value-1)
    end,
  },
  group_velocity = {
    label = "Group-velocity",
    description = "Choose input for controlling the active group velocity",
    items = {
      "Unassigned",
      "Renoise key-velocity",
      "MIDI-Input (velocity)",
      "MIDI-Input (aftertouch)",
      "MIDI-Input (velocity+aftertouch)",
      "XYPad, X Axis",
      "XYPad, Y Axis",
    },
    value = 1,
  },
  group_panning = {
    label = "Group-panning",
    description = "Choose input for controlling the active group panning",
    items = {
      "Unassigned",
      "XYPad, X Axis",
      "XYPad, Y Axis",
    },
    value = 1,
  },
  track_velocity = {
    label = "Track-velocity",
    description = "Choose input for controlling the active track velocity",
    items = {
      "Unassigned",
      "Renoise key-velocity",
      "MIDI-Input (velocity)",
      "MIDI-Input (aftertouch)",
      "MIDI-Input (velocity+aftertouch)",
      "XYPad, X Axis",
      "XYPad, Y Axis",
    },
    value = 1,
  },
  track_panning = {
    label = "Track-panning",
    description = "Choose input for controlling the active track panning",
    items = {
      "Unassigned",
      "XYPad, X Axis",
      "XYPad, Y Axis",
    },
    value = 1,
  },

  play_on_trig = {
    label = "Start on trigger",
    description = "Determine how to handle playback & recording",
    items = {
      "No (start manually)",
      "Yes (start on first trigger)",
    },
    value = 2,
  },
  sample_prep = {
    label = "Prepare samples",
    description = "Determine how to handle newly added samples",
    items = {
      "Yes (loop & beat-sync)",
      "No (leave as they are)",
    },
    value = 1,
  },
  automation = {
    label = "Automation",
    description = "Select automation mode",
    items = {
      "Read",
      "Write",
      "Read+Write",
    },
    value = 3,
    on_change = function(inst)
      if not inst.active then return false end
      inst:update_automation_mode()
    end,
  },
}


Mlrx.available_mappings = {

  -- global

  triggers = {    
    description = "Mlrx: Sample trigger",
    orientation = ORIENTATION.HORIZONTAL,
    greedy = true,
  },
  matrix = {
    description = "Mlrx: Assign this track to group A/B/C/D",
    greedy = true,
  },
  select_track = {
    description = "Mlrx: Set the active track"
                  .."\n(hold the button and simultaneously press a group"
                  .."\ntoggle-button to assign this track to that group)",
    greedy = true,
  },
  track_labels = {
    description = "Mlrx: Display information about this track",
    greedy = true,
  },
  erase = {
    description = "Mlrx: Press to erase the entire pattern",
  },
  clone = {
    description = "Mlrx: Press to create a duplicate of the current pattern",
  },
  automation = {
    description = "Mlrx: Automation mode"
                  .."\nREAD = Only display automation data"
                  .."\nREAD + WRITE = Display automation, record when moved"
                  .."\nWRITE = Start recording from the moment a parameter is moved",
  },

  -- mixer

  group_toggles = {
    description = "Mlrx: Toggle group recording/mute state"
                  .."\nWhen blinking, press to stop recording"
                  .."\nWhen not blinking, press to toggle mute state",
    greedy = true,
  },
  group_levels = {
    description = "Mlrx: Adjust velocity for each group",
    greedy = true,
  },
  group_panning = {
    description = "Mlrx: Adjust panning for each group",
    greedy = true,
  },

  -- track mixer

  track_levels = {
    description = "Mlrx: Adjust velocity for each track",
    greedy = true,
  },
  track_panning = {
    description = "Mlrx: Adjust panning for each track",
    greedy = true,
  },

  -- tracks

  set_source_slice = {
    description = "Mlrx: Set source to SLICE mode"
                  .."\n[Hold] to apply/remove slicing from selected sample",
  },
  set_source_phrase = {
    description = "Mlrx: Set source to PHRASE mode"
                  .."\n[Press] to toggle phrase playback for instrument"
                  .."\n[Hold] to capture pattern data into phrase (when stopped),"
                  .."\n or start a phrase recording (when playing)",
  },
  set_mode_hold = {
    description = "Mlrx: Set track to HOLD mode"
                  .."\n(continously looping sound)",
  },
  set_mode_toggle = {
    description = "Mlrx: Set track to TOGGLE mode"
                  .."\n(continously looping & toggleable, clears existing data)",
  },
  set_mode_write = {
    description = "Mlrx: Set track to WRITE mode"
                  .."\n(produce output only while pressed, clears existing data)",
  },
  set_mode_touch = {
    description = "Mlrx: Set track to TOUCH mode"
                  .."\n(produce output only while pressed)",
  },
  toggle_arp = {
    description = "Mlrx: Toggle arpeggiator on/off",
  },
  arp_mode = {
    description = "Mlrx: Set arpeggiator mode"
                  .."\nALL = pick random offset from all triggers"
                  .."\nRND = pick random offset among held triggers"
                  .."\nFW  = step through held triggers, order of arrival"
                  .."\n4TH = pick random offset (in step of four) from most recent trigger"
                  .."\n4TH = pick random offset (in step of two) from most recent trigger",
  },
  toggle_loop = {
    description = "Mlrx: Enable/disable sample loop",
  },

  shuffle_label = {
    description = "Mlrx: Displays info about shuffle",
  },
  shuffle_amount = {
    description = "Mlrx: Set shuffle amount (0-255)",
  },
  toggle_shuffle_cut = {
    description = "Mlrx: Enable/disable shuffle cut (Cxx)",
  },
  drift_label = {
    description = "Mlrx: Display drifting info",
  },
  drift_amount = {
    description = "Mlrx: Set drift amount (between -256 and 256)"
  },
  drift_enable = {
    description = "Mlrx: Select drifting mode"
                  .."\nOFF = do not apply drift"
                  .."\n'*' = apply drift using entire sample"
                  .."\n'/' = apply drift using cycle range"
  },

  transpose_up = {
    description = "Mlrx: Transpose up"
                  .."\n[Press] to transpose by a single semitone"
                  .."\n[Hold] to transpose by an octave",
  },
  transpose_down = {
    description = "Mlrx: Transpose down"
                  .."\n[Press] to transpose by a single semitone"
                  .."\n[Hold] to transpose by an octave",
  },
  tempo_up = {
    description = "Mlrx: Tempo up"
                  .."\n[Press] to increase by a single tempo/LPB"
                  .."\n[Hold] to double current tempo (when possible)",
  },
  tempo_down = {
    description = "Mlrx: Tempo down"
                  .."\n[Press] to decrease by a single tempo/LPB"
                  .."\n[Hold] to halve current tempo (when possible)",
  },
  toggle_sync = {
    description = "Mlrx: Enable 'beat-sync' in instrument",
  },
  toggle_note_output = {
    description = "Mlrx: Toggle output of notes",
  },
  toggle_sxx_output = {
    description = "Mlrx: Toggle output of sample offset commands",
  },
  toggle_exx_output = {
    description = "Mlrx: Toggle output of envelope offset commands",
  },
  set_cycle_2 = {
    description = "Mlrx: Set cycle length to half",
  },
  set_cycle_4 = {
    description = "Mlrx: Set cycle length to quarter",
  },
  set_cycle_8 = {
    description = "Mlrx: Set cycle length to an eigth",
  },
  set_cycle_16 = {
    description = "Mlrx: Set cycle length to a sixteenth",
  },
  set_cycle_es = {
    description = "Mlrx: Sync cycle length with Renoise edit-step",
  },
  set_cycle_custom = {
    description = "Mlrx: Set cycle length to exact value",
  },
  increase_cycle = {
    description = "Mlrx: Increase cycle length",
  },
  decrease_cycle = {
    description = "Mlrx: Decrease cycle length",
  },

  -- special mappings

  xy_pad = {
    description = "Mlrx: XY-Pad input",
  },

}

Mlrx.default_palette = {

  group_a       = {color={0xFF,0x00,0x00},val=true},  
  group_a_dimmed= {color={0x40,0x00,0x00},val=true},  
  group_b       = {color={0xFF,0x80,0x00},val=true},  
  group_b_dimmed= {color={0x80,0x40,0x00},val=true},  
  group_c       = {color={0xFF,0xFF,0x00},val=true},  
  group_c_dimmed= {color={0x40,0x40,0x00},val=true},  
  group_d       = {color={0x00,0xFF,0x00},val=true},  
  group_d_dimmed= {color={0x00,0x40,0x00},val=true},  
  group_default = {color={0xFF,0xFF,0xFF},val=true},  
  group_default_off = {color={0x70,0x70,0x70},val=false}, 
  master_group  = {color={0x36,0x36,0x36}},               
  enabled       = {color={0xFF,0xFF,0xFF},val=true},  
  disabled      = {color={0x00,0x00,0x00},val=false}, 

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Mlrx:__init(...)
  TRACE("Mlrx:__init",...)

  -- (table) available mlrx-tracks (how many depends on controller)
  self.tracks = table.create()

  -- (int) the selected mlrx-track (1 - NUM_TRACK, _always_ defined)
  self.selected_track = nil

  -- (table) available mlrx-groups (1 - Mlrx.NUM_GROUPS)
  self.groups = table.create()

  -- (bool) detect when Renoise toggles playing
  self._playing = rns.transport.playing

  -- (int) this value is observed in Renoise (between 1 - 32)
  self._quantize = nil

  -- (SongPos) store the last playback position in this variable
  -- (to save us from unneeded idle updates)
  self._last_playpos = nil

  -- (int) remember the note-column index (detect when changed)
  self._last_notecol_index = nil

  -- (int) internally keep track of the number of lines in the
  -- currently playing pattern (used for metronome/blinking)
  self._patt_num_lines = nil

  -- (int) when application is first run, check the
  -- controller to see how many slices we can offer 
  self._num_triggers = nil

  -- (table) currently held MIDI notes
  self.midi_held_keys = table.create()

  -- (int) the last MIDI pitch we received 
  self.midi_last_key = nil

  -- (int) the last MIDI triggered track
  --self.midi_last_track_idx = nil 

  -- (bool) when false, we (temporarily) ignore changes to tracks
  self._track_observable_enabled = true

  -- (bool) true when ready to assign track via group toggle-buttons
  self._track_reassign_mode = nil

  -- (int) control lights synced with the beat 
  self.metronome_count = nil 

  -- (bool) the metronome state, lit or not
  self._metronome_blink = nil

  -- (bool) rapid blinking state, lit or not
  self._rapid_blink = nil

  -- (bool) flag that certain methods should be called in idle loop
  self.group_level_update_requested = false
  self.group_panning_update_requested = false
  self.track_shuffle_update_requested = false
  self.initiate_settings_requested = false
  self.purge_instrument_list = false

  -- (ScheduledTask) call methods with a certain delay
  self._local_settings_task = nil
  self._update_track_task = nil

  --- keep references to our UI controls here
  self._controls = table.create()
  self._controls.triggers = table.create()
  self._controls.matrix = table.create()
  self._controls.track_labels = table.create()
  self._controls.group_toggles = table.create()
  self._controls.group_levels = table.create()
  self._controls.group_panning = table.create()
  self._controls.select_track = table.create()
  self._controls.track_levels = table.create()
  self._controls.track_panning = table.create()

  -- extend default options with the available midi ports
  local input_devices = renoise.Midi.available_input_devices()
  local options = select(3,...)
  local items = Mlrx.default_options.midi_controller.items
  for k,v in ipairs(input_devices) do
    items[k+1] = v
    options.midi_controller.items[k+1] = v
  end

  Application.__init(self,...)

  -- set up external midi control
  self.midi_in = nil
  self:select_midi_port(self.options.midi_controller.value-1)

  --self:list_mappings_and_options(Mlrx.available_mappings,Mlrx.default_options)

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Mlrx:on_idle()

  if not self.active then return false end

  if self.purge_instrument_list then
    self.purge_instrument_list = false
    self:purge_instruments()
  end

  if self.group_level_update_requested then
    self.group_level_update_requested = false
    self:update_group_levels()
  end

  if self.group_panning_update_requested then
    self.group_panning_update_requested = false
    self:update_group_panning()
  end

  if self.track_shuffle_update_requested then
    self.track_shuffle_update_requested = false
    self:update_track_shuffle()
  end

  if self.rebuild_indices_requested then
    self.rebuild_indices_requested = false
    self:rebuild_indices()
  end

  if self.initiate_settings_requested then
    self.initiate_settings_requested = false
    self:initiate_settings_task()
  end

  local notecol_index = rns.selected_note_column_index
  if (notecol_index ~= self._last_notecol_index) then
    self._last_notecol_index = notecol_index
    for k,v in ipairs(self.tracks) do
      if (v.rns_track_idx == rns.selected_track_index) then
        v.note_col_idx = (notecol_index ~= 0) and notecol_index or 1
        --print("v.note_col_idx",v.note_col_idx,v)
      end
    end
  end

  -- now for stuff that update with the song position 
  local playing = rns.transport.playing
  local playpos = Mlrx_pos(rns.transport.playback_pos)
  if playing and
    (playpos ~= self._last_playpos) 
  then

    -- output notes and (possibly) automation
    for _,g in ipairs(self.groups) do
      if (#g.tracks > 0) then
        g:group_output(true)
      end
    end

    if not self._last_playpos or (playpos.sequence ~= self._last_playpos.sequence) then
      -- switched pattern, check the pattern length
      local patt_idx = rns.sequencer.pattern_sequence[playpos.sequence]
      local patt = rns:pattern(patt_idx)
      self._patt_num_lines = patt.number_of_lines
      --print("self._patt_num_lines",self._patt_num_lines)
    end

    -- update stuff that is synchronized to the metronome 
    local update_blink = false
    local tmp = (math.floor((playpos.line-1)/self.metronome_count)%2 == 0) and true or false
    if (tmp ~= self._metronome_blink) then
      self._metronome_blink = tmp
      update_blink = true
    end
    if update_blink then
      self:update_group_toggles()
      self:update_automation_mode()
      self:update_sound_source()
    end

    -- update rapidly blinking stuff
    self._rapid_blink = not self._rapid_blink
    local trk = self.tracks[self.selected_track]
    if trk.phrase_record_armed then
      self:update_sound_source()
    end

  end

  self._last_playpos = playpos

  if (not playing and playing ~= self._playing) then
    -- when we stop playing
    self._last_playpos = nil
    self:panic()
  end

  self._playing = playing

end

--------------------------------------------------------------------------------

--- Update all UI components, called when initializing

function Mlrx:update()  
  TRACE("Mlrx:update()")

  if not self.active then return false end

  self:update_matrix()
  self:update_group_levels()
  self:update_group_panning()
  self:update_group_toggles()
  self:update_track_levels()
  self:update_track_panning()
  self:update_track_shuffle()
  self:update_track_selector()
  self:update_automation_mode()
  self:update_track()
  self:update_summary()

end

--------------------------------------------------------------------------------

--- Update track-related UI components

function Mlrx:update_track_task()  
  self.display.scheduler:remove_task(self._update_track_task)
  self._update_track_task = self.display.scheduler:add_task(
    self, Mlrx.update_track, 0.2)
end

function Mlrx:update_track()  
  TRACE("Mlrx:update_track()")

  self:update_linesync()
  self:update_output_filter()
  self:update_trigger_mode()
  self:update_cycle_length()
  self:update_sound_source()
  self:update_toggle_loop()
  self:update_arp_mode()
  self:update_track_shuffle()
  self:update_track_drift()

  self:update_summary(self.selected_track)

end

--------------------------------------------------------------------------------

--- Reset the state of the application, make it ready for a new session

function Mlrx:initialize_app()
  TRACE("Mlrx:initialize_app()")

  local first_run = true

  self.active = true
  self._track_observable_enabled = true
  self:import_or_create()
  self:purge_instruments(first_run)
  Mlrx_settings.retrieve_local_settings(self)
  self:_attach_to_song()
  self:clear_settings_task()
  self:determine_metronome()
  self:get_quantize()
  self:input_key_velocity()

  self:update()

end

--------------------------------------------------------------------------------

--- Remove references to active song, stop running tasks

function Mlrx:clear_references()

  self.display.scheduler:remove_task(self._update_track_task)
  self.display.scheduler:remove_task(self._local_settings_task)

  for _,trk in ipairs(self.tracks) do
    trk:clear_references()
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Mlrx:start_app(start_running)
  TRACE("Mlrx.start_app()",start_running)

  self.selected_track = 1

  if not Application.start_app(self) then
    return
  end

  --print("start_running",start_running)

  local group_track_index = self:retrieve_group_track_index()
  if start_running and not group_track_index then
    self._process.browser:stop_current_configuration()
    return 
  end


  --print("rns.transport.timing_model",rns.transport.timing_model,renoise.Transport.TIMING_MODEL_SPEED)
  if (rns.transport.timing_model == renoise.Transport.TIMING_MODEL_SPEED) then
    local msg = "Warning: mlrx does not support the old 'speed' based timing model,"
      .."\nplease go to Song > Playback & Compability Options and upgrade the song"
    renoise.app():show_warning(msg)
    return
  end

  self:initialize_app()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.stop_app

function Mlrx:stop_app()
  TRACE("Mlrx:stop_app()")
  
  self:panic()
  self:clear_references()

  Application.stop_app(self)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_release_document

function Mlrx:on_release_document()
  TRACE("Mlrx:on_release_document")

  self:panic()
  self:clear_references()
  self.active = false

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Mlrx:on_new_document()
  TRACE("Mlrx:on_new_document")

  rns = renoise.song()

  -- make Automation class aware of the new song
  --[[
  for _,g in ipairs(self.groups) do
    g.automation:attach_to_song(true)
  end
  ]]
  
  for _,trk in ipairs(self.tracks) do
    trk.instr = nil
  end

  local group_track_index = self:retrieve_group_track_index()
  if not group_track_index then
    self._process.browser:stop_current_configuration()
    return 
  end


  self:initialize_app()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Mlrx:_build_app()
  TRACE("Mlrx:_build_app(")

  -- 
  if not Mlrx_view._build_app(self) then 
    LOG("*** Mlrx: Failed to build application")
    return false 
  end
  
  Application._build_app(self)
  return true

end 

--------------------------------------------------------------------------------

--- Enable track observables with some delay 

function Mlrx:_enable_track_observable()
  self._track_observable_enabled = true
end

--------------------------------------------------------------------------------

--- Add notifiers to song
-- invoked when first run, and when a new document becomes available

function Mlrx:_attach_to_song()
  TRACE("Mlrx:_attach_to_song")

  rns.transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Mlrx:edit_mode_observable fired...")
      if not self.active then return false end
      self:on_edit_mode_change()
    end
  )
  rns.transport.edit_step_observable:add_notifier(
    function()
      TRACE("Mlrx:edit_step_observable fired...")
      if not self.active then return false end
      local trk = self.tracks[self.selected_track]
      trk:update_summary_task()
      for _,t in ipairs(self.tracks) do
        t:determine_cycle_lines()
      end

    end
  )
  rns.transport.bpm_observable:add_notifier(
    function()
      TRACE("Mlrx:bpm_observable fired...")
      if not self.active then return false end
      self:on_host_tempo_change()
    end
  )
  rns.transport.lpb_observable:add_notifier(
    function()
      TRACE("Mlrx:lpb_observable fired...")
      if not self.active then return false end
      self:on_host_tempo_change()
    end
  )
  rns.transport.metronome_lines_per_beat_observable:add_notifier(
    function()
      TRACE("Mlrx:metronome_lines_per_beat fired...")
      self:determine_metronome()
    end
  )
  rns.transport.keyboard_velocity_enabled_observable:add_notifier(
    function()
      TRACE("Mlrx:keyboard_velocity_enabled fired...")
      self:input_key_velocity()
    end
  )
  rns.transport.keyboard_velocity_observable:add_notifier(
    function()
      TRACE("Mlrx:keyboard_velocity fired...")
      self:input_key_velocity()
    end
  )

  rns.transport.record_quantize_enabled_observable:add_notifier(
    function()
      TRACE("Mlrx:record_quantize_enabled_observable fired...")
      self:get_quantize()
    end
  )
  rns.transport.record_quantize_lines_observable:add_notifier(
    function()
      TRACE("Mlrx:record_quantize_lines_observable fired...")
      self:get_quantize()
    end
  )
  rns.selected_track_index_observable:add_notifier(
    function()
      TRACE("Mlrx:selected_track_index_observable fired...")
      --if (self.options.set_focus.value == Mlrx.FOCUS_TRACKS) or
      --  (self.options.set_focus.value == Mlrx.FOCUS_TRACKS_INSTR)
      --then
        for k,v in ipairs(self.tracks) do
          if (v.rns_track_idx == rns.selected_track_index) then
            self:select_track(k)
          end
        end
      --end
    end
  )
  

  -- observe the instrument list
  rns.instruments_observable:add_notifier(
    function(param)
      TRACE("Mlrx:instruments_observable fired...",param)
      self.purge_instrument_list = true
    end
  )

  -- observe when tracks are inserted, swapped or deleted,
  -- and update mlrx track properties accordingly...
  rns.tracks_observable:add_notifier(
    function(arg)
      TRACE("Mlrx:tracks_observable fired...",arg)

      if not self.active then return false end

      self.rebuild_indices_requested = true

    end
  )

end


--------------------------------------------------------------------------------

--- Rebuild indices when the tracks_observable require it - 
-- when we encounter a condition that may have changed the track order

function Mlrx:rebuild_indices()
  TRACE("Mlrx:rebuild_indices()")
  
  local group_track_index,num_members = self:retrieve_group_track_index()
  local group_offset = group_track_index - num_members

  if not group_track_index then
    renoise.app():show_warning("mlrx group-track was deleted or renamed, "
      .."shutting down application...")
    self:stop_app()
    return
  end

  -- if num_members isn't the same, 
  -- a track got removed, inserted or dragged into/out from group

  if (num_members ~= #self.tracks) then
    --print("compare the names of tracks")
    for k,v in ipairs(self.tracks) do

      local trk_name = v:get_name()
      local matched_name = false
      for i = group_offset, group_track_index do
        local tmp_trk = rns.tracks[i]
        --print(k,i,"tmp_trk.name",tmp_trk.name,"v.get_name()",v:get_name())
        if (trk_name == tmp_trk.name) and (k+group_offset-1 == i) then
          matched_name = true
          break
        end
      end
      --print("***",k,"matched_name",matched_name)

      if not matched_name then
        local track_idx = group_offset + k - 1
        if (num_members < #self.tracks) then
          --print("insert track")
          local rns_trk = self:insert_track_at(track_idx)
          rns_trk.name = trk_name
        else
          --print("delete track")
          self:delete_track_at(track_idx)
        end
      end

    end

  end

  self._track_observable_enabled = true

  local rns_trk_idx = group_offset - 1
  for k,trk in ipairs(self.tracks) do
    trk.rns_track_idx = rns_trk_idx + k
    --print("*** rebuild_indices - trk",k,"rns_track_idx",trk.rns_track_idx)
    trk:attach_to_track()
  end

  self:decorate_tracks()

end

--------------------------------------------------------------------------------

--- Delete RenoiseTrack at provided index

function Mlrx:delete_track_at(idx)
  TRACE("Mlrx:insert_track_at(idx)",idx)

  self._track_observable_enabled = false
  rns:delete_track_at(idx)
  self.display.scheduler:add_task(
    self,self._enable_track_observable,0.1)

end

--------------------------------------------------------------------------------

--- Insert RenoiseTrack at provided index

function Mlrx:insert_track_at(idx)
  TRACE("Mlrx:insert_track_at(idx)",idx)

  local group_track_index,num_members = self:retrieve_group_track_index()
  --print("*** insert_track_at - group_track_index",group_track_index,"num_members",num_members)

  self._track_observable_enabled = false

  local insert_idx = idx+1
  if (insert_idx == group_track_index+1) then
    insert_idx = idx-1
  end

  --print("*** insert_track_at - insert_idx",insert_idx)
  local rns_trk = rns:insert_track_at(insert_idx) 
  rns:swap_tracks_at(insert_idx,idx)
  self.display.scheduler:add_task(
    self,self._enable_track_observable,0.1)

  return rns_trk

end


--------------------------------------------------------------------------------

--- Cancel notes in all groups, reset state
-- invoked when we exit edit mode / stop playing / stop application

function Mlrx:panic()
  TRACE("Mlrx:panic()")

  for _,g in ipairs(self.groups) do
    g:cancel_notes()
    --g.automation:stop_automation()
    g.grp_latch_velocity = false
    g.grp_latch_panning = false
    g.active_track_index = nil
  end

  for _,t in ipairs(self.tracks) do
    t._held_triggers = table.create()
    t.trk_latch_velocity = false
    t.trk_latch_panning = false
    t.trk_latch_shuffle = false
    t.phrase_record_armed = false
    t.phrase_recording = false
    t._last_pressed = nil
    t._last_playpos = nil
  end

  self:update_sound_source()

  self.midi_held_keys = table.create()
  

end

--------------------------------------------------------------------------------

--- Method for discovering this group's index

function Mlrx:get_group_index(grp)
  TRACE("Mlrx:get_group_index()")

  for k,v in ipairs(self.groups) do
    if (grp == v) then
      return k
    end
  end

end

--------------------------------------------------------------------------------

--- Look for an existing session in the song, 
-- or (if not found) initialize a new session

function Mlrx:import_or_create()
  TRACE("Mlrx:import_or_create()")

  -- recycle existing master group
  local group_track_index = self:retrieve_group_track_index()
  --print("Mlrx:import_or_create() - group_track_index",group_track_index)

  if not group_track_index then

    -- group is not present, create it 

    self._track_observable_enabled = false

    rns:insert_group_at(1)
    rns.tracks[1].color = self.palette.master_group.color
    rns.tracks[1].name = Mlrx.MASTER_GROUP_NAME
    for trk_idx,trk in ipairs(self.tracks) do
      rns:insert_track_at(1)
      rns:add_track_to_group(1,trk_idx+1)
      --print("added track #",1,trk_idx+1)
    end
    group_track_index = self:retrieve_group_track_index()

    self.display.scheduler:add_task(
      self,self._enable_track_observable,0.1)


  end

  -- TODO ensure that the master-group and mlrx has 
  -- at least equal size 

  -- configure our tracks with settings that _aren't_
  -- stored in the song comments section (instr. properties)

  local group_offset = group_track_index - #self.tracks - 1
  for trk_idx,trk in ipairs(self.tracks) do
    trk.rns_track_idx = trk_idx + group_offset
    --print("*** import_or_create - trk_idx,rns_track_idx",trk_idx,trk.rns_track_idx)
    trk:attach_to_track()
    trk.group = (trk_idx > Mlrx.NUM_GROUPS) and self.groups[Mlrx.VOID_GROUP] or self.groups[trk_idx]
    trk.group.tracks:insert(trk)
    trk:determine_writeahead()
  end 


end

--------------------------------------------------------------------------------

--- Retrieve the mlrx group-track index 
-- @return int (1 - number of sequencer tracks), #number of members 

function Mlrx:retrieve_group_track_index()
  TRACE("Mlrx:retrieve_group_track_index()")

  for k,v in ipairs(rns.tracks) do
    if (v.type == renoise.Track.TRACK_TYPE_GROUP) and
      (v.name == Mlrx.MASTER_GROUP_NAME) 
    then
      return k,#v.members
    end

  end

end

--------------------------------------------------------------------------------

--- This method is called each time one of the local settings change

function Mlrx:initiate_settings_task()
  TRACE("Mlrx:initiate_settings_task()")

  self:clear_settings_task()
  self._local_settings_task = self.display.scheduler:add_task(
    self,Mlrx_settings.store_local_settings, 2.0)

end

--------------------------------------------------------------------------------

--- This method is called each time one of the local settings change

function Mlrx:clear_settings_task()
  TRACE("Mlrx:clear_settings_task()")

  self.display.scheduler:remove_task(self._local_settings_task)

end

--------------------------------------------------------------------------------

--- Select provided logical track, update Renoise focus?

function Mlrx:select_track(idx)
  TRACE("Mlrx:select_track()",idx)

  if (idx > #self.tracks) then
    -- likely, when settings specify a track which does not exist in
    -- the song (could be the case when switching between ORIENTATION.HORIZONTAL
    -- and ORIENTATION.VERTICAL orientation for the trigger grid)
    --print("*** select_track - cannot select this logical track",idx)
    return
  end

  if (self.selected_track == idx) then
    return
  end

  self.selected_track = idx
  --print("*** select_track - self.selected_track",self.selected_track)

  self:update_track()
  self:update_track_selector()

  if (self.options.set_focus.value ~= Mlrx.FOCUS_DISABLED) then

    local trk = self.tracks[self.selected_track]
    local focus_track = false
    local focus_instr = false

    if (self.options.set_focus.value == Mlrx.FOCUS_TRACKS) then
      focus_track = true
    elseif (self.options.set_focus.value == Mlrx.FOCUS_INSTR) then
      focus_instr = true
    elseif (self.options.set_focus.value == Mlrx.FOCUS_TRACKS_INSTR) then
      focus_track = true
      focus_instr = true
    end

    if focus_track then
      local rns_trk = rns.tracks[trk.rns_track_idx]
      if rns_trk then
        rns.selected_track_index = trk.rns_track_idx
        if trk.note_col_idx and
          (rns_trk.visible_note_columns >= trk.note_col_idx)
        then
          rns.selected_note_column_index = trk.note_col_idx
        end
      end
    end

    if focus_instr then
      local rns_instr = rns.instruments[trk.rns_instr_idx]
      if rns_instr then
        rns.selected_instrument_index = trk.rns_instr_idx
      end
    end

  end

  if (self.options.collapse_tracks.value == Mlrx.COLLAPSE_TRACKS_AUTO) then
    self:decorate_tracks()
  end

  self.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

--- Assign the provided track to this group 
-- @param group_idx (int) - the Mlrx-group index
-- @param track_idx (int) - the Mlrx-track index
-- @param programmatic (bool), when function is invoked by the app itself

function Mlrx:assign_track(group_idx,track_idx,programmatic)
  TRACE("Mlrx:assign_track()",group_idx,track_idx)

  local grp = self.groups[group_idx]
  local track = self.tracks[track_idx]
  --print("grp",grp,"track.group",track.group,"==",(grp == track.group))
  if not programmatic and (grp == track.group) then

    -- toggle off: assign to special 'void' group

    for trk_idx, t in ipairs(self.tracks) do
      if (trk_idx == track_idx) then
        t.group = nil
      end  
    end
    grp = self.groups[Mlrx.VOID_GROUP]

  else

    -- assign to group

    local track = nil
    for idx, t in ipairs(self.tracks) do
      if (idx == track_idx) then
        t.group = nil
        track = t
      end  
    end

  end

  track.group = grp

  -- make sure group tracks are current
  for grp_idx,g in ipairs(self.groups) do
    g:collect_group_tracks(grp_idx)
  end

  -- apply mixer settings to track
  -- ??? right now this is applied as "set only", but  
  -- could it affect automation recording ??? 
  local rns_trk = rns.tracks[track.rns_track_idx]
  if rns_trk then
    local param = rns_trk.prefx_volume
    local param_val = track.group.velocity
    param.value = cLib.scale_value(param_val,0,Mlrx.INT_8BIT,0,RENOISE_DECIBEL)
    track.group:set_grp_velocity(track.group.velocity)

    local param = rns_trk.prefx_panning
    local param_val = track.group.panning/Mlrx.INT_8BIT
    param.value = param_val
    track.group:set_grp_panning(track.group.panning)

  end

  self.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

--- Erase the current pattern

function Mlrx:erase_pattern()
  TRACE("Mlrx:erase_pattern()")

  local playpos = Mlrx_pos()
  local patt_idx = rns.sequencer.pattern_sequence[playpos.sequence]
  rns:pattern(patt_idx):clear()

end

--------------------------------------------------------------------------------

--- Clone the pattern, while moving the playhead to the new pattern

function Mlrx:clone_pattern(seq_idx,migrate_playpos)
  TRACE("Mlrx:clone_pattern()",seq_idx,migrate_playpos)

  rns.sequencer:clone_range(seq_idx, seq_idx)

  if migrate_playpos then
    if rns.transport.playing then
      local pos = rns.transport.playback_pos
      pos.sequence = seq_idx+1
      rns.transport.playback_pos = pos
    else
      local pos = rns.transport.edit_pos
      pos.sequence = seq_idx+1
      rns.transport.edit_pos = pos
    end
  end


end

--------------------------------------------------------------------------------

--- Update visual display of groups assignments

function Mlrx:update_matrix()
  TRACE("Mlrx:update_matrix()")

  local ctrl_idx = 1
  for trk_idx = 1, #self.tracks do
    for grp_idx = 1, Mlrx.NUM_GROUPS do
    
      local trk = self.tracks[trk_idx]

      local grp,color,color_dimmed = nil
      if (trk.group.void_mutes) then
        grp = self.groups[Mlrx.VOID_GROUP]
        color = grp.color_dimmed
        color_dimmed = grp.color_dimmed
      else
        grp = self.groups[grp_idx]
        color = grp.color
        color_dimmed = grp.color_dimmed
      end

      local ctrl = self._controls.matrix[ctrl_idx]
  
      -- alfabetic name A1/B2/C3 etc.
      local bt_title = string.char(64+grp_idx)..trk_idx

      if (trk and trk.group == grp) then   
        ctrl:set({val=not trk.group.void_mutes,color=color,text=bt_title})
        --print("active: trk_idx",trk_idx, "grp_idx",grp_idx,", ctrl_idx:",ctrl_idx)
        trk:decorate_track_task()
      else
        ctrl:set({val=false,color=color_dimmed,text=bt_title})
      end

      ctrl_idx = ctrl_idx+1

    end
  end
  
end

--------------------------------------------------------------------------------

--- Update display of arpeggiator controls

function Mlrx:update_arp_mode()
  TRACE("Mlrx:update_arp_mode()")

  local enabled = self.palette.enabled
  local disabled = self.palette.disabled
  local trk = self.tracks[self.selected_track]

  local ctrl = self._controls.arp_mode
  if ctrl then
    ctrl:set((trk.arp_enabled) and enabled or disabled)
    if (trk.arp_mode == Mlrx_track.ARP_RANDOMIZE) then
      ctrl:set({text="RND"})
    elseif (trk.arp_mode == Mlrx_track.ARP_KEYS) then
      ctrl:set({text="KEY"})
    elseif (trk.arp_mode == Mlrx_track.ARP_ALL) then
      ctrl:set({text="HLD"})
    elseif (trk.arp_mode == Mlrx_track.ARP_FORWARD) then
      ctrl:set({text="ORD"})
    elseif (trk.arp_mode == Mlrx_track.ARP_FOURSTEP) then
      ctrl:set({text="4TH"})
    elseif (trk.arp_mode == Mlrx_track.ARP_TWOSTEP) then
      ctrl:set({text="2ND"})
    end
  end

  local ctrl = self._controls.toggle_arp
  if ctrl then
    ctrl:set((trk.arp_enabled) and enabled or disabled)
  end

end

--------------------------------------------------------------------------------

--- Update display of loop toggle control

function Mlrx:update_toggle_loop(trk)
  TRACE("Mlrx:update_toggle_loop(trk)",trk)

  if not trk then
    trk = self.tracks[self.selected_track]
  end

  local ctrl = self._controls.toggle_loop
  if ctrl then

    local enabled = self.palette.enabled
    local disabled = self.palette.disabled

    --print("trk.sample",trk.sample)

    if not trk.sample then

      ctrl:set(disabled)
      ctrl:set({text="N/A"})

    else

      local loop_mode = nil 
      if (trk.sample.loop_mode == renoise.Sample.LOOP_MODE_OFF) then
        ctrl:set(disabled)
        loop_mode = trk._cached_loop_mode or renoise.Sample.LOOP_MODE_FORWARD
      else
        ctrl:set(enabled)
        loop_mode = trk.sample.loop_mode
      end

      --print("trk.sample.loop_mode",trk.sample.loop_mode)
      if (loop_mode == renoise.Sample.LOOP_MODE_FORWARD) then
        ctrl:set({text="→"})
      elseif (loop_mode == renoise.Sample.LOOP_MODE_REVERSE) then
        ctrl:set({text="←"})
      elseif (loop_mode == renoise.Sample.LOOP_MODE_PING_PONG) then
        ctrl:set({text="↔"})
      end

    end

  end


end

--------------------------------------------------------------------------------

--- Update display of group toggle controls

function Mlrx:update_group_toggles()
  TRACE("Mlrx:update_group_toggles()")

  local ctrl = nil
  local enabled = table.rcopy(self.palette.enabled)
  local disabled = self.palette.disabled

  for grp_idx = 1, Mlrx.NUM_GROUPS do
    --local palette = self:retrieve_group_palette(grp_idx)
    local grp = self.groups[grp_idx]
    enabled.color = grp.color
    -- determine if there's active notes or automation
    -- recording happening anywhere in the group
    local grp_active = false
    local grp_muted = false
    if grp.grp_latch_velocity or
      grp.grp_latch_panning 
    then
      grp_active = true
      --print("grp_active A")
    end
    for _,trk in ipairs(grp.tracks) do
      if trk.note or 
        -- continous output, even with no note
        (trk._clear_without_note and trk._last_pressed) or 
        -- active automation recording
        trk.trk_latch_velocity or
        trk.trk_latch_panning or
        trk.trk_latch_shuffle 
      then
        grp_active = true
        --print("grp_active B")
      end
      local rns_trk = rns.tracks[trk.rns_track_idx] 
      if rns_trk and (rns_trk.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE) then
        grp_muted = true
      end
    end
    ctrl = self._controls.group_toggles[grp_idx]
    if grp_active then
      ctrl:set((self._metronome_blink) and enabled or disabled)
    elseif grp_muted then
      ctrl:set(disabled)
    else
      ctrl:set(enabled)
    end
  end

end


--------------------------------------------------------------------------------

--- Update display of track level controls

function Mlrx:update_track_levels(match_trk)
  TRACE("Mlrx:update_track_levels(match_trk)",match_trk)

  local ctrl = nil
  local skip_event = true
  for k,v in ipairs(self.tracks) do
    local matched = match_trk and (match_trk == v) or true
    if matched then
      ctrl = self._controls.track_levels[k]
      if ctrl then
        --print("*** setting track level to",self.tracks[idx].velocity)
        local val = math.min(Mlrx.INT_7BIT,self.tracks[k].velocity+self.tracks[k].pressure)
        ctrl:set_value(val,skip_event)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Update display of track panning controls

function Mlrx:update_track_panning(match_trk)
  TRACE("Mlrx:update_track_panning(match_trk)",match_trk)

  local ctrl = nil
  local skip_event = true
  for k,v in ipairs(self.tracks) do
    local matched = match_trk and (match_trk == v) or true
    if matched then
      ctrl = self._controls.track_panning[k]
      if ctrl then
        ctrl:set_value(self.tracks[k].panning,skip_event)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Update display of shuffle controls

function Mlrx:update_track_shuffle(trk)
  TRACE("Mlrx:update_track_shuffle(trk)",trk)

  if not trk then
    trk = self.tracks[self.selected_track]
  end

  local ctrl = self._controls.shuffle_amount
  local skip_event = true
  if ctrl then
    ctrl:set_value(trk.shuffle_amount,skip_event)
  end

  local ctrl = self._controls.toggle_shuffle_cut
  local skip_event = true
  if ctrl then
    local enabled = self.palette.enabled
    local disabled = self.palette.disabled
    ctrl:set((trk.shuffle_cut) and enabled or disabled)
  end

  local ctrl = self._controls.shuffle_label
  if ctrl then
    local txt = (trk.shuffle_amount == 0) and "OFF" or tostring(trk.shuffle_amount)
    txt = ("shuffle\n%s"):format(txt)
    ctrl:set_text(txt)
  end

end

--------------------------------------------------------------------------------

--- Update display of drift controls

function Mlrx:update_track_drift(trk)
  TRACE("Mlrx:update_track_drift(trk)",trk)

  if not trk then
    trk = self.tracks[self.selected_track]
  end

  local skip_event = true
  local ctrl = self._controls.drift_amount
  if ctrl then
    ctrl:set_value((trk.drift_amount+128),skip_event)
  end

  local ctrl = self._controls.drift_enable
  if ctrl then
    local enabled = self.palette.enabled
    local disabled = self.palette.disabled
    local txt = nil
    if (trk.drift_mode == Mlrx_track.DRIFT_OFF) then
      txt = "OFF"
    elseif (trk.drift_mode == Mlrx_track.DRIFT_ALL) then
      txt = "*"
    elseif (trk.drift_mode == Mlrx_track.DRIFT_CYCLE) then
      txt = "/"
    end
    ctrl:set((trk.drift_mode == Mlrx_track.DRIFT_OFF) and disabled or enabled, skip_event)
    ctrl:set({text = txt}, skip_event)
  end

  local ctrl = self._controls.drift_label
  if ctrl then
    ctrl:set_text(("drifting\n%d"):format(trk.drift_amount))
  end

  --print("*** trk.drift_mode",trk.drift_mode)

end

--------------------------------------------------------------------------------

--- Update display of group level controls
-- @param match_grp (Mlrx_group), update only a specific group 

function Mlrx:update_group_levels(match_grp)
  TRACE("Mlrx:update_group_levels()",match_grp)

  for grp_idx = 1, Mlrx.NUM_GROUPS do
    local grp = self.groups[grp_idx]
    local matched = match_grp and (match_grp == grp) or true
    if matched then
      local ctrl = self._controls.group_levels[grp_idx]
      if ctrl then
        --print("*** update_group_levels - set_value",grp.velocity)
        ctrl:set_value(grp.velocity,true)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Update display of group panning controls
-- @param match_grp (Mlrx_group), update only a specific group 

function Mlrx:update_group_panning(match_grp)
  TRACE("Mlrx:update_group_panning()",match_grp)

  for grp_idx = 1, Mlrx.NUM_GROUPS do
    local grp = self.groups[grp_idx]
    local matched = match_grp and (match_grp == grp) or true 
    if matched then
      local ctrl = self._controls.group_panning[grp_idx]
      if ctrl then
        ctrl:set_value(grp.panning,true)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Update display of automation-mode control

function Mlrx:update_automation_mode()
  TRACE("Mlrx:update_automation_mode()")
  
  local ctrl = self._controls.automation
  if ctrl then

    --print("*** update_automation_mode - self.options.automation.value",self.options.automation.value)
    
    local str_txt = nil
    if (self.options.automation.value == Mlrx.AUTOMATION_READ) then
      str_txt = "READ"
    elseif (self.options.automation.value == Mlrx.AUTOMATION_WRITE) then
      str_txt = "WRITE"
    elseif (self.options.automation.value == Mlrx.AUTOMATION_READ_WRITE) then
      str_txt = "R+W"
    end
    ctrl:set({text=str_txt})

    local enabled = self.palette.enabled
    local disabled = self.palette.disabled
    if rns.transport.edit_mode and
      (self.options.automation.value == Mlrx.AUTOMATION_WRITE) 
    then

      -- blinking button when writing automation
      local automation_active = false
      for _,g in ipairs(self.groups) do
        if (g.grp_latch_velocity or 
          g.grp_latch_panning) 
        then
          automation_active = true
          break
        end
      end
      for _,t in ipairs(self.tracks) do
        if (t.trk_latch_velocity or 
          t.trk_latch_panning or
          t.trk_latch_shuffle) 
        then
          automation_active = true
          break
        end
      end
      --print("*** update_automation_mode - automation_active",automation_active)
      if automation_active then
        ctrl:set((self._metronome_blink) and enabled or disabled)
      end

    else
      --print("*** update_automation_mode - disabled",disabled)
      ctrl:set(disabled)
    end


  end

end

--------------------------------------------------------------------------------

--- Update display of track-select control

function Mlrx:update_track_selector()
  TRACE("Mlrx:update_track_selector()")

  --print(" self.selected_track",self.selected_track)

  for idx,ctrl in ipairs(self._controls.select_track) do
    if (idx == self.selected_track) then
      ctrl:set({color = self.tracks[idx].group.color, val=true})
    else
      ctrl:set({color = self.tracks[idx].group.color_dimmed, val=false})
    end
  end

end

--------------------------------------------------------------------------------

--- Update sync button (light up if sample is synced)

function Mlrx:update_linesync(trk)
  TRACE("Mlrx:update_linesync(trk)",trk)

  local ctrl = self._controls.toggle_sync
  if not ctrl then
    return
  end 

  if not trk then
    trk = self.tracks[self.selected_track]
  end

  local linesynced = false
  if trk.phrase then
    linesynced = true
  elseif trk.sample then
    linesynced = trk.sample.beat_sync_enabled 
  end
  --print("*** linesynced",linesynced)

  local enabled = self.palette.enabled
  local disabled = self.palette.disabled


  if trk.phrase then
    ctrl:set(enabled)
    ctrl:set({text=("LPB\n%d"):format(trk.phrase.lpb)})
  else
    ctrl:set((linesynced) and enabled or disabled)
    ctrl:set({text="BEAT\nSYNC"})
  end

end

--------------------------------------------------------------------------------

--- Update display of trigger mode buttons

function Mlrx:update_trigger_mode()
  TRACE("Mlrx:update_trigger_mode()")

  local trk = self.tracks[self.selected_track]

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.set_mode_hold
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_HOLD) and enabled or disabled)
  end

  ctrl = self._controls.set_mode_toggle
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_TOGGLE) and enabled or disabled)
  end

  ctrl = self._controls.set_mode_write
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_WRITE) and enabled or disabled)
  end

  ctrl = self._controls.set_mode_touch
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_TOUCH) and enabled or disabled)
  end


end

--------------------------------------------------------------------------------

--- Update display of trigger mode buttons

function Mlrx:update_output_filter()
  TRACE("Mlrx:update_output_filter()")

  local trk = self.tracks[self.selected_track]

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.toggle_note_output
  if ctrl then
    ctrl:set((trk.do_note_output) and enabled or disabled)
  end

  ctrl = self._controls.toggle_sxx_output
  if ctrl then
    ctrl:set((trk.do_sxx_output) and enabled or disabled)
  end

  ctrl = self._controls.toggle_exx_output
  if ctrl then
    ctrl:set((trk.do_exx_output) and enabled or disabled)
  end

end

--------------------------------------------------------------------------------

--- Update display of cycle-length buttons

function Mlrx:update_cycle_length()
  TRACE("Mlrx:update_cycle_length()")

  local trk = self.tracks[self.selected_track]

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.set_cycle_1
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.FULL) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_2
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.HALF) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_4
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.FOURTH) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_8
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.EIGHTH) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_16
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.SIXTEENTH) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_es
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.EDITSTEP) 
      and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_custom
  if ctrl then
    ctrl:set((trk.cycle_length == Mlrx_track.CYCLE.CUSTOM) 
      and enabled or disabled)
    ctrl:set({text = tostring(trk.cycle_lines)})
  end


end

--------------------------------------------------------------------------------

--- Update color & name of all tracks within the mlrx-group

function Mlrx:decorate_tracks()

  for _,trk in ipairs(self.tracks) do
    trk:decorate_track_task()
  end

end


--------------------------------------------------------------------------------

--- Momentarily flash the automation button

function Mlrx:flash_automation_button()
  TRACE("Mlrx:flash_automation_button()")

  local ctrl = self._controls.automation
  if ctrl then
    ctrl:flash(0.2,self.palette.enabled,self.palette.disabled)
  end

end

--------------------------------------------------------------------------------

--- Cycle through the available automation modes

function Mlrx:cycle_automation_mode()
  TRACE("Mlrx:cycle_automation_mode()")

  local val = nil
  if (self.options.automation.value == Mlrx.AUTOMATION_READ) then
    val = Mlrx.AUTOMATION_WRITE
  elseif (self.options.automation.value == Mlrx.AUTOMATION_READ_WRITE) then
    val = Mlrx.AUTOMATION_READ
  elseif (self.options.automation.value == Mlrx.AUTOMATION_WRITE) then
    val = Mlrx.AUTOMATION_READ_WRITE
  end

  --print("*** self.options.automation.value",val)

  self:_set_option("automation",val,self._process)

  -- apply changes to ongoing recordings
  for _,t in ipairs(self.tracks) do
    t.trk_latch_velocity = false
    t.trk_latch_panning = false
    t.trk_latch_shuffle = false
  end
  for _,g in ipairs(self.groups) do
    g.grp_latch_velocity = false
    g.grp_latch_panning = false
  end
  

end

--------------------------------------------------------------------------------

--- Update display of the source-select controls 

function Mlrx:update_sound_source()
  TRACE("Mlrx:update_sound_source()")

  local enabled = table.rcopy(self.palette.enabled)
  local disabled = table.rcopy(self.palette.disabled)

  local trk = self.tracks[self.selected_track]

  local ctrl = self._controls.set_source_slice
  if ctrl then
    if not trk.phrase then
      ctrl:set((trk.is_sliced) and enabled or disabled)
    else
      ctrl:set(disabled)
    end
  end

  local ctrl = self._controls.set_source_phrase
  if ctrl then
    if trk.phrase_recording then
      ctrl:set((self._metronome_blink) and enabled or disabled)
    elseif trk.phrase_record_armed then
      ctrl:set((self._rapid_blink) and enabled or disabled)
    else
      ctrl:set((trk.phrase) and enabled or disabled)
    end
  end

end

--------------------------------------------------------------------------------

--- Provided with track and trigger index, retrieve the control 
-- @return UIButton

function Mlrx:get_trigger_ctrl(trk,trigger_idx)
  TRACE("Mlrx:get_trigger_ctrl(trk_idx,trigger_idx)")

  return self._controls.triggers[trigger_idx+(trk._num_triggers*(trk.self_idx-1))]

end

--------------------------------------------------------------------------------

--- Update the lit position on the controller, called from the track itself
-- @param trk_idx (int) the index of the Mlrx_track instance
-- @param trigger_idx (int) optional, the position to light up (omit to clear)

function Mlrx:update_trigger_pos(trk_idx,trigger_idx)
  TRACE("Mlrx:update_trigger_pos(trk_idx,trigger_idx)",trk_idx,trigger_idx)

  local trk = self.tracks[trk_idx]

  -- turn off previous position
  if trk._lit_position then
    local ctrl = self:get_trigger_ctrl(trk,trk._lit_position)
    if ctrl then
      --print(" update_trigger_pos - disable this index:",trk._lit_position)
      ctrl:set(self.palette.disabled)
    end
    trk._lit_position = nil
  end

  -- light the new one
  if trigger_idx then
    local ctrl = self:get_trigger_ctrl(trk,trigger_idx)
    if ctrl then
      --print(" update_trigger_pos - enable this index:",trigger_idx)
      --local enabled = self:retrieve_group_palette(trk.group_index)
      local enabled = table.rcopy(self.palette.enabled)
      enabled.color = trk.group.color
      ctrl:set(enabled)
    end
    trk._lit_position = trigger_idx
  end


end

--------------------------------------------------------------------------------

--- Provide some quick feedback on the controller (flashing buttons)

function Mlrx:trigger_feedback(trk_idx,trigger_idx,duration)
  TRACE("Mlrx:trigger_feedback(trk_idx,trigger_idx)",trk_idx,trigger_idx)

  local trk = self.tracks[trk_idx]

  if not duration then
    duration = 0.1
  end

  if (trigger_idx == trk._lit_position) then
    --print(" trigger_feedback - position is already lit")
    return
  end

  local ctrl = self:get_trigger_ctrl(trk,trigger_idx)
  if ctrl then
    local enabled = table.rcopy(self.palette.enabled)
    enabled.color = trk.group.color
    ctrl:flash(duration,enabled,self.palette.disabled)
  else
    --LOG("trigger_feedback - trigger ctrl not defined @ idx",trigger_idx)
  end

end

--------------------------------------------------------------------------------

--- After having swapped, loaded or removed instruments we call this function
-- this will re-attach all instruments 

function Mlrx:purge_instruments(first_run)
  TRACE("Mlrx:purge_instruments(first_run)",first_run)

  for _,trk in ipairs(self.tracks) do
    trk:attach_to_instr(first_run)
  end

  self:update_track()
  self:update_summary()
  self:decorate_tracks()
  self.initiate_settings_requested = true

end

--------------------------------------------------------------------------------

--- Update label displaying summary of track(s)
-- @param trk_idx (int), limit update to this track

function Mlrx:update_summary(trk_idx)
  TRACE("Mlrx:update_summary()",trk_idx)

  local ctrl = nil
  for i,trk in ipairs(self.tracks) do

    --print("*** update_summary...",i,trk)

    local update_trk = true
    if trk_idx and (trk_idx ~= i) then
      update_trk = false
    end
    
    if update_trk then
      ctrl = self._controls.track_labels[i]
      if ctrl then
        local str_name = "N/A"
        local str_trig = ""
        local str_cycle = rns.transport.edit_step
        local str_transpose = ""

        local str_symbol = "--"
        if (trk.phrase) then
          str_symbol = "≡" 
        elseif (trk.is_sliced) then
          str_symbol = "||" 
        elseif (trk.sample) then
          str_symbol = "/\\/"
        end

        if trk.instr then
          if (trk.instr.name == "") then
            if trk.sample and not (trk.sample.sample_buffer.has_sample_data) then
              str_name = "(empty)"
            else
              str_name = "(untitled)"
            end
          else
            str_name = string.format("%.15s",trk.instr.name)
          end
          str_trig = 
            (trk.trig_mode == Mlrx_track.TRIG_HOLD) and "HOLD" or 
            (trk.trig_mode == Mlrx_track.TRIG_TOGGLE) and "TOGGLE" or 
            (trk.trig_mode == Mlrx_track.TRIG_WRITE) and "WRITE" or
            (trk.trig_mode == Mlrx_track.TRIG_TOUCH) and "TOUCH"
          local linesynced = trk.sample and trk.sample.beat_sync_enabled 
          local note_val = note_pitch_to_value(trk.note_pitch)
          if linesynced or trk.sync_to_lines then
            str_transpose = string.format("%s - %d/%d lines",note_val,trk.sync_to_lines,trk.cycle_lines)
          else
            str_transpose = string.format("%s",note_val)
          end
        end
        local instr_idx = trk.rns_instr_idx-1
        local str_summary = string.format("%02d:%s\n%s %s %s",instr_idx,str_name,str_trig,str_symbol,str_transpose)
        ctrl:set_text(str_summary)

      end
    end
  end

end


--------------------------------------------------------------------------------
--- Obtain the difference in lines between two song-positions
-- note: when the pattern is the same, we ignore the sequence and assume 
-- that pos1 comes before pos2 (so, a 64-line pattern containing two
-- positions: 63 and 1 would result in 2 lines)
-- TODO replace with xSongPos

function Mlrx:get_pos_diff(pos1,pos2)
  TRACE("Mlrx:get_pos_diff()",pos1,pos2)

  local patt_idx = rns.sequencer.pattern_sequence[pos1.sequence]
  local patt = rns:pattern(patt_idx)
  local num_lines = patt.number_of_lines

  if (pos1.sequence == pos2.sequence) then
    if (pos1.line > pos2.line) then   
      return num_lines-pos1.line+pos2.line
    else
      return pos2.line-pos1.line
    end
  else
    return num_lines-pos1.line+pos2.line
  end

end

--------------------------------------------------------------------------------

--- Set the current quantize amount from renoise

function Mlrx:get_quantize()
  TRACE("Mlrx:get_quantize()")

  if rns.transport.record_quantize_enabled then
    self._quantize = rns.transport.record_quantize_lines
  else
    self._quantize = 1
  end
end

--------------------------------------------------------------------------------

--- Count number of lines in a pattern
-- @return int (the number of pattern lines), or nil if not found

function Mlrx:count_lines(seq_idx)
  TRACE("Mlrx:count_lines()",seq_idx)

  local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
  if patt_idx then
    return rns:pattern(patt_idx).number_of_lines
  end

end

--------------------------------------------------------------------------------

--- Stop any active recordings

function Mlrx:on_edit_mode_change()
  TRACE("Mlrx:on_edit_mode_change()")

  if not self.active then return false end

  if not rns.transport.edit_mode then
    self:panic()
  end

  self:update_automation_mode()


end


--------------------------------------------------------------------------------

--- This function will update the duration of phrases and unsynced samples,
-- and compute a new 'writeahead' time. Note that if BPM is changed constantly 
-- change (via automation or otherwise), the task will never execute...

function Mlrx:on_host_tempo_change()
  TRACE("Mlrx:on_host_tempo_change()")

  for _,v in ipairs(self.tracks) do
    if v.sample and not v.sample.beat_sync_enabled then
      v:set_transpose_task(0)
    elseif v.phrase and xInstrument.get_phrase_playback_enabled(v.instr) then
      v:set_transpose_task(0)
    end
    v:determine_writeahead()
  end

  self.initiate_settings_requested = true

end


--------------------------------------------------------------------------------

--- Provide timing for certain events (i.e. blinking lights)

function Mlrx:determine_metronome()
  TRACE("Mlrx:determine_metronome()")

  local count = rns.transport.metronome_lines_per_beat
  if (count == 0) then
    count = rns.transport.lpb
  end

  self.metronome_count = count

end


--------------------------------------------------------------------------------

--- Initialize MIDI input

function Mlrx:select_midi_port(port_idx)
  TRACE("Mlrx.select_midi_port()",port_idx)

  -- always close it first
  if (self.midi_in and self.midi_in.is_open) then
    self.midi_in:close()
  end
  -- when 'none' is selected
  if port_idx<1 then
    return
  end
  local input_devices = renoise.Midi.available_input_devices()
  local port_name = input_devices[port_idx]
  if port_name then
    self.midi_in = renoise.Midi.create_input_device(port_name,
      {self, Mlrx.midi_callback}
    )
  end

end


--------------------------------------------------------------------------------

--- Receive MIDI from device
-- TODO use xMidiInput

function Mlrx:midi_callback(message)
  TRACE("Mlrx:midi_callback",message[1], message[2], message[3])

  if not self.active then return false end

  local trk = self.tracks[self.selected_track]

  -- determine the type of signal : note/cc/etc
  if (message[1]>=128) and (message[1]<=159) then

    local msg_is_note_off = false
    if (message[1]>143) then
      if (message[3]==0) then
        msg_is_note_off = true      
      end
    else
      msg_is_note_off = true
    end

    -- apply the note velocity?
    -------------------------------------------------------

    if not msg_is_note_off then
    
      if (self.options.group_velocity.value == Mlrx.GRP_VELOCITY_MIDI_VEL) then
        local val = cLib.scale_value(message[3],0,Mlrx.INT_7BIT,0,Mlrx.INT_8BIT)
        trk.group:set_grp_velocity(val)
        self:update_group_levels(trk.group)
      end
      if (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_MIDI_VEL) or
        (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_MIDI_VEL_PRESS)      
      then
        trk:set_trk_velocity(message[3])
        self:update_track_levels(trk)
      end

    end

    -- handle note on/off (triggering)
    -------------------------------------------------------

    if msg_is_note_off then

      -- process tracks 

      for _,v in ipairs(self.tracks) do
        for k2,v2 in pairs(v._held_keys) do
          if (v2 == message[2]) then
            -- only allow removing keys from selected track
            if (v == trk) then
              -- found the relevant track 
              -- revert to the most recent one...
              v._held_keys:remove(k2)
              local new_transp = v._held_keys[#v._held_keys]
              if new_transp and (new_transp ~= v.note_pitch) then
                v:set_transpose(new_transp-v.note_pitch)
                self:update_track_task()
              end
            else
              -- mark this track as having 'hanging' notes
              v._hanging_notes = true
              --print("mark this track",k)
            end
          end
        end
      end


      if (#self.midi_held_keys == 1) then 
      
        -- all keys released

        --print("*** midi_callback - all keys released")
        self.midi_held_keys = table.create()

        if (trk.trig_mode == Mlrx_track.TRIG_WRITE) or 
          (trk.trig_mode == Mlrx_track.TRIG_TOUCH) 
        then
          --print("*** midi_callback - trigger_release",trk._last_pressed)
          trk:trigger_release(trk._last_pressed)
        end

      else 

        -- key released, other key(s) still pressed

        for k,v in pairs(self.midi_held_keys) do
          if (v == message[2]) then
            self.midi_held_keys:remove(k)
          end
        end
        --print("*** midi_callback - midi_held_keys...")
        --rprint(self.midi_held_keys)
      end


    else 
    
      -- note-on
      trk._held_keys:insert(message[2])

      --print("*** midi_callback - note-on, trk._last_pressed",trk._last_pressed)
      trk:set_transpose(message[2]-trk.note_pitch)

      if (trk.trig_mode == Mlrx_track.TRIG_TOGGLE) and 
        (self.midi_last_key == message[2]) 
      then
        --print("equal to last held key, trigger release")
        local toggle_off = true
        trk:trigger_release(trk._last_pressed,toggle_off)

        self.midi_last_key = nil
      else
        local trigger_idx = trk._last_pressed or 1
        local skip_toggling = (trk.trig_mode == Mlrx_track.TRIG_TOGGLE)
        trk:trigger_press(trigger_idx,skip_toggling)
        self.midi_last_key = message[2]
      end

      self.midi_held_keys:insert(message[2])

    end


  elseif (message[1]>=208) and (message[1]<=223) then
    --print("MIDI_CHANNEL_PRESSURE")
    if (self.options.group_velocity.value == Mlrx.GRP_VELOCITY_MIDI_PRESS) then
      local val = cLib.scale_value(message[2],0,Mlrx.INT_7BIT,0,Mlrx.INT_8BIT)
      trk.group:set_grp_velocity(val)
      self:update_group_levels(trk.group)
    end
    if (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_MIDI_PRESS) then
      trk:set_trk_velocity(message[2])
      self:update_track_levels(trk)
    elseif (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_MIDI_VEL_PRESS) then
      trk.pressure = message[2]
      --print("*** midi_callback - trk.pressure",trk.pressure)
      trk:set_trk_velocity(trk.velocity)
      self:update_track_levels(trk)
    end

  elseif (message[1]>=176) and (message[1]<=191) then
    --print("MIDI_CC_MESSAGE")
  elseif (message[1]>=224) and (message[1]<=239) then
    --print("MIDI_PITCH_BEND_MESSAGE")
  else
    -- unsupported message...
  end

end

--------------------------------------------------------------------------------

--- Generic routing of XY-Pad signal (e.g. tilt sensor on monome)

function Mlrx:input_xy(val)
  TRACE("Mlrx:input_xy(val)",val)

  local value = nil
  local track = self.tracks[self.selected_track]
  local group = track.group

  -- group velocity

  local set_grp_velocity = false
  if (self.options.group_velocity.value == Mlrx.GRP_VELOCITY_PAD_Y) then
    set_grp_velocity = true
    value = cLib.clamp_value(val[2],0,1)
  elseif (self.options.group_velocity.value == Mlrx.GRP_VELOCITY_PAD_X) then
    set_grp_velocity = true
    value = cLib.clamp_value(val[1],0,1)
  end
  if set_grp_velocity then
    group:set_grp_velocity(value * Mlrx.INT_8BIT)
    self.group_level_update_requested = true
  end

  -- track velocity

  local set_trk_velocity = false
  if (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_PAD_Y) then
    set_trk_velocity = true
    value = cLib.clamp_value(val[2],0,1)
  elseif (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_PAD_X) then
    set_trk_velocity = true
    value = cLib.clamp_value(val[1],0,1)
  end
  if set_trk_velocity then
    track:set_trk_velocity(value * Mlrx.INT_7BIT)
    self:update_track_levels(track)
  end

  -- group panning 

  local set_grp_panning = false
  if (self.options.group_panning.value == Mlrx.GRP_PANNING_PAD_Y) then
    set_grp_panning = true
    value = cLib.clamp_value(val[2],0,1) 
  elseif (self.options.group_panning.value == Mlrx.GRP_PANNING_PAD_X) then
    set_grp_panning = true
    value = cLib.clamp_value(val[1],0,1)
  end
  if set_grp_panning then
    group:set_grp_panning(value * Mlrx.INT_8BIT)
    --self:update_group_panning(group)
    self.group_panning_update_requested = true
  end

  -- track panning 

  local set_trk_panning = false
  if (self.options.track_panning.value == Mlrx.TRK_PANNING_PAD_Y) then
    set_trk_panning = true
    value = cLib.clamp_value(val[2],0,1) 
  elseif (self.options.track_panning.value == Mlrx.TRK_PANNING_PAD_X) then
    set_trk_panning = true
    value = cLib.clamp_value(val[1],0,1)
  end
  if set_trk_panning then
    track:set_trk_panning(value * Mlrx.INT_7BIT)
    self:update_track_panning(track)
  end

end

--------------------------------------------------------------------------------

--- Called when keyboard velocity is changed in Renoise

function Mlrx:input_key_velocity()
  TRACE("Mlrx:input_key_velocity()")

  local value = nil

  if (self.options.group_velocity.value == Mlrx.GRP_VELOCITY_KEY_VEL) then
    local set_grp_velocity = false
    set_grp_velocity = true
    if rns.transport.keyboard_velocity_enabled then
      value = rns.transport.keyboard_velocity * 2
    else
      value = Mlrx.INT_8BIT
    end
    if set_grp_velocity then
      local group = self.tracks[self.selected_track].group
      group:set_grp_velocity(value)
      self:update_group_levels(group)
    end
  end

  if (self.options.track_velocity.value == Mlrx.TRK_VELOCITY_KEY_VEL) then
    local set_trk_velocity = false
    set_trk_velocity = true
    if rns.transport.keyboard_velocity_enabled then
      value = rns.transport.keyboard_velocity
    else
      value = Mlrx.INT_7BIT
    end
    if set_trk_velocity then
      local trk = self.tracks[self.selected_track]
      trk:set_trk_velocity(value)
      self:update_track_levels(trk)
    end
  end

end

