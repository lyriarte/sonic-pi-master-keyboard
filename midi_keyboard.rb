#  ---- ----  ----  ---- midi keyboard input

# ---- midi event capture

live_loop :midi_note_on do
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_on"
  play nt
end

live_loop :midi_note_off do
  nt, vl = sync "/midi:midi_through_port-0:0:1/note_off"
end
