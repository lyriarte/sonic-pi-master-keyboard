#  ---- ----  ----  ---- midi keyboard input


# ---- midi chord

synth_nodes = []
kill_nodes = []

define :play_midi_note do | nt |
  synth_nodes[nt] = play nt, sustain: 16, release: 1
end

define :stop_midi_note do | nt |
  control synth_nodes[nt], amp: 0
  kill_nodes.append(synth_nodes[nt])
  synth_nodes[nt] = nil
  cue :synth_nodes_cleanup
end

# ---- synth nodes garbage collection

live_loop :kill_synth_nodes do
  sync :synth_nodes_cleanup
  for node in kill_nodes do
    node.kill
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
