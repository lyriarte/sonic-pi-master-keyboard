#  ---- ----  ----  ---- midi keyboard input


# ---- midi chord

synth_nodes = []

define :play_midi_note do | nt |
  synth_nodes[nt] = play nt, sustain: 8, release: 1
end

define :stop_midi_note do | nt |
  control synth_nodes[nt], amp: 0
  synth_nodes[nt].kill
  synth_nodes[nt] = nil
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
