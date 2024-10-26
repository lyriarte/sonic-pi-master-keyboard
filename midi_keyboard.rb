#  ---- ----  ----  ---- midi keyboard input




# ---- midi event capture

live_loop :midi_note_on do
  use_real_time
  # sync keydown event
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_on"
  play nt
end

live_loop :midi_note_off do
  use_real_time
  # sync keyup event
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_off"
end
