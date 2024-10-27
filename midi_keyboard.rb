#  ---- ----  ----  ---- midi keyboard input


# ---- midi synth defaults

# use beep synth if no modulation
set :midi_synth, :beep
# use mod beep synth if modulation phase is non zero
set :midi_mod_synth, :mod_beep

# amp volume on ctrl 7, default 1, range 0 to 2
ct_amp = 7
range_amp = [0,2]
midi_amp = 1

# ADSR envelope attack on ctrl 74, default 0, range 0 to 2
ct_attack = 74
range_attack = [0,2]
midi_attack = range_attack[0]

# ADSR envelope decay on ctrl 71, default 0, range 0 to 4
ct_decay = 71
range_decay = [0,4]
midi_decay = range_decay[0]

# ADSR envelope sustain on ctrl 73, default 0, range 0 to 16
ct_sustain = 73
range_sustain = [0,16]
midi_sustain = range_sustain[0]

# ADSR envelope release on ctrl 72, default 0.2, range 0.2 to 8
ct_release = 72
range_release = [0.2,8]
midi_release = range_release[0]

# modulation phase on ctrl 1, default 0 (no modulation), range 1-0 to 1-0.95
ct_mod_phase = 1
range_mod_phase = [0,0.95]
midi_mod_phase = 0
# modulation range on pitch bend, default 0, range -12 to 12 (2 octaves)
mod_range_factor = 24 / Float(16384)
midi_mod_range = 0


# ---- midi chord

synth_nodes = []
kill_nodes = []

define :play_midi_note do | nt |
  # use mod synth if nonzero phase
  if midi_mod_phase > 0
    use_synth (get :midi_mod_synth)
  else
    use_synth (get :midi_synth)
  end
  # play note using ADSR envelope
  synth_nodes[nt] = play nt, amp: midi_amp, 
    attack: midi_attack, 
    decay: midi_decay, 
    sustain: midi_sustain, 
    release: midi_release,
  # modulation parameters are ignored on non mod synth
    mod_phase: 1 - midi_mod_phase,
    mod_range: midi_mod_range
end

define :stop_midi_note do | nt |
  # silence note with release duration
  control synth_nodes[nt], amp: 0, amp_slide: midi_release
  kill_nodes.append(synth_nodes[nt])
  synth_nodes[nt] = nil
  cue :synth_nodes_cleanup
end

# ---- synth nodes garbage collection

live_loop :kill_synth_nodes do
  sync :synth_nodes_cleanup
  sleep midi_release
  for node in kill_nodes do
    node.kill if node
  end
  kill_nodes = []
end


# ---- midi event capture

live_loop :midi_note_on do
  use_real_time
  # sync keydown event
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_on"
  # play the note now and store the synth node
  play_midi_note nt
end

live_loop :midi_note_off do
  use_real_time
  # sync keyup event
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_off"
  # get the synth node and stop playing the note
  stop_midi_note nt
end


# map 7 bit midi control value va on range rg
define :control_ponderation do | rg, va |
  return rg[0] + (va / Float(127)) * (rg[1] - rg[0])
end

live_loop :midi_control_change do
  use_real_time
  # sync ctrl event
  ct, va = sync "/midi:midi_through_port-0:0:1/control_change"
  case ct
  when ct_amp
    midi_amp = (control_ponderation range_amp, va)
  when ct_attack
    midi_attack = (control_ponderation range_attack, va)
  when ct_decay
    midi_decay = (control_ponderation range_decay, va)
  when ct_sustain
    midi_sustain = (control_ponderation range_sustain, va)
  when ct_release
    midi_release = (control_ponderation range_release, va)
  when ct_mod_phase
    midi_mod_phase = (control_ponderation range_mod_phase, va)
  end
end


live_loop :midi_pich_change do
  use_real_time
  # sync pitch bend event
  va = sync "/midi:midi_through_port-0:0:1/pitch_bend"
  # default pitch bend 8K, range 0..16K maps on octaves range
  midi_mod_range = (va[0] - 8192) * mod_range_factor
end
