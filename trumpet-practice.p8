pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- trumpet fingering trainer
-- version 2.0 - full range expansion

function _init()
  -- app states: "menu", "reference", "quiz", "result", "play_along"
  state = "menu"
  menu_opt = 1
  ref_idx = 1
  ref_playing = false
  ref_flavor = "list"
  ref_v = { false, false, false }
  ref_air = 1
  playing_p = nil

  -- practice state variables
  score = 0
  total = 0
  is_correct = false
  user_v = { false, false, false }
  user_air = 2

  -- play-along state variables
  play_along_timer = 0
  failed = false

  -- difficulty ranges
  min_air = 1
  max_air = 2
  is_bb = true
  tempo = 80

  -- database of notes (f#3 to g5)
  -- y: standard treble clef positioning (F5 = 24, E4 = 56)
  -- v: valves, air: partial (1-5), w: srs weight, p: pico-8 pitch index (F#3=18 to G5=43)
  notes = {
    -- 1st partial
    { name = "f#3", y = 80, v = { true, true, true }, air = 1, p = 18 },
    { name = "g3", y = 76, v = { true, false, true }, air = 1, p = 19 },
    { name = "g#3", y = 76, v = { false, true, true }, air = 1, p = 20 },
    { name = "a3", y = 72, v = { true, true, false }, air = 1, p = 21 },
    { name = "bB3", y = 68, v = { true, false, false }, air = 1, p = 22 },
    { name = "b3", y = 68, v = { false, true, false }, air = 1, p = 23 },
    { name = "c4", y = 64, v = { false, false, false }, air = 1, p = 24 },
    -- 2nd partial
    { name = "c#4", y = 64, v = { true, true, true }, air = 2, p = 25 },
    { name = "d4", y = 60, v = { true, false, true }, air = 2, p = 26 },
    { name = "d#4", y = 60, v = { false, true, true }, air = 2, p = 27 },
    { name = "e4", y = 56, v = { true, true, false }, air = 2, p = 28 },
    { name = "f4", y = 52, v = { true, false, false }, air = 2, p = 29 },
    { name = "f#4", y = 52, v = { false, true, false }, air = 2, p = 30 },
    { name = "g4", y = 48, v = { false, false, false }, air = 2, p = 31 },
    -- 3rd partial
    { name = "g#4", y = 48, v = { false, true, true }, air = 3, p = 32 },
    { name = "a4", y = 44, v = { true, true, false }, air = 3, p = 33 },
    { name = "bB4", y = 40, v = { true, false, false }, air = 3, p = 34 },
    { name = "b4", y = 40, v = { false, true, false }, air = 3, p = 35 },
    { name = "c5", y = 36, v = { false, false, false }, air = 3, p = 36 },
    -- 4th partial
    { name = "c#5", y = 36, v = { true, true, false }, air = 4, p = 37 },
    { name = "d5", y = 32, v = { true, false, false }, air = 4, p = 38 },
    { name = "d#5", y = 32, v = { false, true, false }, air = 4, p = 39 },
    { name = "e5", y = 28, v = { false, false, false }, air = 4, p = 40 },
    -- 5th partial
    { name = "f5", y = 24, v = { true, false, false }, air = 5, p = 41 },
    { name = "f#5", y = 24, v = { false, true, false }, air = 5, p = 42 },
    { name = "g5", y = 20, v = { false, false, false }, air = 5, p = 43 }
  }

  -- background stars
  stars = {}
  for i = 1, 25 do
    add(
      stars, {
        x = rnd(128),
        y = rnd(128),
        speed = 0.2 + rnd(0.8),
        col = rnd({ 5, 6, 13 })
      }
    )
  end

  for n in all(notes) do
    n.w = 1
  end

  pick_new_note()
end

function pick_new_note()
  local active_notes = {}
  for n in all(notes) do
    if n.air >= min_air and n.air <= max_air then
      add(active_notes, n)
    end
  end

  local selection_pool = #active_notes > 0 and active_notes or notes

  if state == "quiz" or state == "result" then
    note = pick_weighted_note(selection_pool)
  else
    note = rnd(selection_pool)
  end

  user_v = { false, false, false }
  user_air = min_air
  -- default
end

function _update()
  if state == "menu" then
    for s in all(stars) do
      s.y -= s.speed
      if s.y < 0 then
        s.y = 128
        s.x = rnd(128)
      end
    end
    if btnp(2) then menu_opt = max(1, menu_opt - 1) end
    if btnp(3) then menu_opt = min(7, menu_opt + 1) end

    if menu_opt == 3 then
      if btnp(0) then
        if ref_flavor == "list" then
          ref_flavor = "sticky"
        elseif ref_flavor == "valves" then
          ref_flavor = "list"
        else
          ref_flavor = "valves"
        end
      elseif btnp(1) then
        if ref_flavor == "list" then
          ref_flavor = "valves"
        elseif ref_flavor == "valves" then
          ref_flavor = "sticky"
        else
          ref_flavor = "list"
        end
      end
    elseif menu_opt == 4 then
      if btnp(0) then min_air = max(1, min_air - 1) end
      if btnp(1) or btnp(5) then
        min_air = min_air + 1
        if min_air > 5 then min_air = 1 end
        if max_air < min_air then max_air = min_air end
      end
    elseif menu_opt == 5 then
      if btnp(0) then
        max_air = max(1, max_air - 1)
        if min_air > max_air then min_air = max_air end
      end
      if btnp(1) or btnp(5) then
        max_air = max_air + 1
        if max_air > 5 then max_air = 1 end
        if min_air > max_air then min_air = max_air end
      end
    elseif menu_opt == 6 then
      if btnp(0) or btnp(1) or btnp(5) then is_bb = not is_bb end
    elseif menu_opt == 7 then
      if btnp(0) then tempo = max(40, tempo - 5) end
      if btnp(1) or btnp(5) then
        tempo = tempo + 5
        if tempo > 120 then tempo = 40 end
      end
    end

    if btnp(5) and menu_opt <= 3 then
      if menu_opt == 1 then
        state = "quiz"
        score = 0
        total = 0
        pick_new_note()
      elseif menu_opt == 2 then
        state = "play_along"
        score = 0
        total = 0
        play_along_timer = 0
        failed = false
        pick_new_note()
      elseif menu_opt == 3 then
        state = "reference"
        ref_idx = 1
        ref_v = { false, false, false }
        ref_air = 1
      end
    end
  elseif state == "reference" then
    if ref_flavor == "list" then
      if btnp(0) then
        stop_pitch()
        ref_playing = false
        ref_idx = max(1, ref_idx - 1)
      end
      if btnp(1) then
        stop_pitch()
        ref_playing = false
        ref_idx = min(#notes, ref_idx + 1)
      end
      if btnp(4) then
        stop_pitch()
        ref_playing = false
        state = "menu"
      end

      if btn(5) then
        if not ref_playing then
          local ref_note = notes[ref_idx]
          local p = is_bb and ref_note.p - 2 or ref_note.p
          play_pitch(p)
          ref_playing = true
        end
      else
        if ref_playing then
          stop_pitch()
          ref_playing = false
        end
      end
    else
      -- valves or sticky mode
      if ref_flavor == "sticky" then
        ref_v[1] = btn(0)
        ref_v[3] = btn(1)
        ref_v[2] = btn(3)

        if btnp(2) then
          ref_air = ref_air + 1
          if ref_air > 5 then ref_air = 1 end
        end
      else
        -- toggle valves mode
        if btnp(0) then ref_v[1] = not ref_v[1] end
        if btnp(1) then ref_v[3] = not ref_v[3] end
        if btnp(2) then
          ref_air = ref_air + 1
          if ref_air > 5 then ref_air = 1 end
        end
        if btnp(3) then ref_v[2] = not ref_v[2] end
      end

      if btnp(4) then
        stop_pitch()
        ref_playing = false
        playing_p = nil
        state = "menu"
      end

      -- find note matching ref_v and ref_air
      local p = get_pitch(ref_v, ref_air)
      local found = find_note_by_pitch(p)

      if btn(5) then
        if found then
          if not ref_playing then
            local pitch_val = is_bb and found.p - 2 or found.p
            play_pitch(pitch_val)
            ref_playing = true
            playing_p = p
          elseif playing_p ~= p then
            stop_pitch()
            local pitch_val = is_bb and found.p - 2 or found.p
            play_pitch(pitch_val)
            playing_p = p
          end
        end
      else
        if ref_playing then
          stop_pitch()
          ref_playing = false
          playing_p = nil
        end
      end
    end
  elseif state == "quiz" then
    if btnp(0) then user_v[1] = not user_v[1] end
    if btnp(1) then user_v[3] = not user_v[3] end

    if btnp(2) then
      user_air = user_air + 1
      if user_air > 5 then user_air = 1 end
    end
    if btnp(3) then user_v[2] = not user_v[2] end

    if btnp(4) then
      state = "menu"
    end

    if btnp(5) then
      total += 1
      local valves_correct = user_v[1] == note.v[1]
          and user_v[2] == note.v[2]
          and user_v[3] == note.v[3]
      local air_correct = user_air == note.air

      if valves_correct and air_correct then
        is_correct = true
        score += 1
        sfx(0)
        note.w = max(0.2, note.w * 0.5)
      else
        is_correct = false
        sfx(1)
        note.w = min(5, note.w * 2)
      end
      local p = is_bb and note.p - 2 or note.p
      play_pitch(p)
      state = "result"
    end
  elseif state == "result" then
    if btnp(4) then
      stop_pitch()
      state = "menu"
    end
    if btnp(5) then
      stop_pitch()
      pick_new_note()
      state = "quiz"
    end
  elseif state == "play_along" then
    if btnp(4) then
      stop_pitch()
      state = "menu"
      return
    end

    local beat_len = flr(1800 / tempo)
    local cycle_len = beat_len * 12

    if play_along_timer % beat_len == 0 then
      local beat = flr(play_along_timer / beat_len) + 1
      play_click()

      if beat == 5 then
        local p = is_bb and note.p - 2 or note.p
        play_pitch(p)
      elseif beat == 9 then
        stop_pitch()
      end
    end

    play_along_timer += 1

    if play_along_timer >= cycle_len then
      score += 1
      total += 1

      play_along_timer = 0
      pick_new_note()
    end
  end
end

function _draw()
  cls(1)

  if state == "menu" then
    cls(12) -- sky blue

    -- draw savanna sun
    circfill(116, 16, 6, 10) -- yellow sun

    -- draw grass hills
    rectfill(0, 110, 128, 128, 3) -- dark green savanna ground
    rectfill(0, 110, 128, 112, 11) -- light green top grass line

    rectfill(0, 0, 128, 12, 1) -- dark blue banner for title
    print("pico trumpet trainer", 4, 4, 7)

    rectfill(12, 24, 116, 101, 7) -- white paper/card menu box
    rect(12, 24, 116, 101, 5) -- dark gray menu outline

    print("select mode:", 36, 28, 5) -- dark gray subtitle

    local c1 = menu_opt == 1 and 8 or 1
    local c2 = menu_opt == 2 and 8 or 1
    local c3 = menu_opt == 3 and 8 or 1
    local c4 = menu_opt == 4 and 8 or 1
    local c5 = menu_opt == 5 and 8 or 1
    local c6 = menu_opt == 6 and 8 or 1
    local c7 = menu_opt == 7 and 8 or 1

    local sel_y = 38 + (menu_opt - 1) * 9
    rectfill(24, sel_y - 1, 108, sel_y + 6, 15) -- peach/light orange selection bar

    print("practice", 36, 38, c1)
    print("play-along", 36, 47, c2)
    print("ref: < " .. ref_flavor .. " >", 36, 56, c3)
    print("min air: < " .. min_air .. " >", 36, 65, c4)
    print("max air: < " .. max_air .. " >", 36, 74, c5)
    print("trumpet: < " .. (is_bb and "bB" or "c") .. " >", 36, 83, c6)
    print("tempo: < " .. tempo .. " > bpm", 36, 92, c7)

    local arrow_x = 28 + sin(t() * 2) * 2
    print(">", arrow_x, sel_y, 8) -- red selection arrow

    if menu_opt <= 3 then
      print("press \151 to start", 28, 104, 1) -- dark blue on sky background
    else
      print("adjust: \139/\145 or press \151", 20, 104, 1) -- dark blue on sky background
    end
    draw_elephant(116, 122, true, true, true)
    return
  end

  -- header
  rectfill(0, 0, 128, 12, 0)
  print("pico trumpet trainer", 4, 4, 7)

  if state == "quiz" or state == "result" or state == "play_along" then
    local score_str = score .. "/" .. total
    print(score_str, 124 - #score_str * 4, 4, 10)
  elseif state == "reference" then
    print("reference", 92, 4, 10)
  end

  if state == "quiz" or state == "result" then
    local mastery = flr(100 * (5 - note.w) / 4.8)
    print("srs: " .. mastery .. "%", 4, 16, 6)
  end

  -- treble clef staff
  for i = 0, 4 do
    local line_y = 24 + (i * 8)
    line(20, line_y, 108, line_y, 7)
  end

  local draw_note = nil
  if state == "reference" then
    if ref_flavor == "list" then
      draw_note = notes[ref_idx]
    else
      local p = get_pitch(ref_v, ref_air)
      draw_note = find_note_by_pitch(p)
    end
  else
    draw_note = note
  end

  -- note letter name
  if draw_note then
    local show_name = true
    if state == "quiz" then
      show_name = false
    elseif state == "play_along" then
      local beat_len = flr(1800 / tempo)
      local beat = flr(play_along_timer / beat_len) + 1
      if beat <= 8 then
        show_name = false
      end
    end

    if show_name then
      print(draw_note.name, 4, 38, 10)
    else
      print("?", 4, 38, 5)
    end

    -- dynamic ledger lines
    local l_y = 64
    while l_y <= draw_note.y do
      line(56, l_y, 72, l_y, 7)
      l_y += 8
    end

    -- accidentals (sharp/flat)
    local acc = sub(draw_note.name, 2, 2)
    if acc == "#" or acc == "b" or acc == "B" then
      print(acc, 54, draw_note.y - 2, 7)
    end

    -- note head
    circfill(64, draw_note.y, 4, 10)
  else
    -- draw_note is nil (only possible in reference mode valves flavor)
    print("?", 4, 38, 5)
    print("?", 62, 52, 5)
  end

  draw_valves(34, 100)
  draw_air()

  -- draw elephant mascot
  local happy = false
  local playing = false
  local ex = 18
  local ey = 86
  if state == "result" then
    happy = is_correct
    playing = true
  elseif state == "play_along" then
    local beat_len = flr(1800 / tempo)
    local beat = flr(play_along_timer / beat_len) + 1
    if beat >= 5 and beat <= 8 then
      happy = true
      playing = true
    end
    -- bounce and sway dance to the beat!
    local phase = (play_along_timer % beat_len) / beat_len
    ey = ey - flr(sin(phase * 0.5) * 2)
    ex = ex + (beat % 2 == 1 and 1 or -1) * flr(sin(phase * 0.5) * 2)
  elseif state == "reference" then
    happy = ref_playing
    playing = ref_playing
  end
  draw_elephant(ex, ey, playing, happy, false)

  -- ui contextual instructions
  if state == "quiz" then
    print("\139/\153/\145:valves \148:cycle air", 16, 114, 6)
    print("\151:submit  \142:quit", 32, 122, 7)
  elseif state == "result" then
    if is_correct then
      rectfill(0, 112, 128, 128, 11)
      print("correct!", 48, 113, 0)
      print("\151:next  \142:quit", 36, 121, 0)
    else
      rectfill(0, 112, 128, 128, 8)
      print("wrong! correct shown", 24, 113, 7)
      print("\151:next  \142:quit", 36, 121, 7)
    end
  elseif state == "reference" then
    if ref_flavor == "list" then
      print("\139/\145:navigate  \151:play note", 14, 114, 6)
      print("press \142 for menu", 30, 122, 7)
    elseif ref_flavor == "valves" then
      print("\139/\153/\145:valves \148:cycle air", 16, 114, 6)
      print("\151:play note  \142:quit", 24, 122, 7)
    else
      -- sticky
      print("hold \139/\153/\145:valves \148:cycle air", 6, 114, 6)
      print("\151:play note  \142:quit", 24, 122, 7)
    end
  elseif state == "play_along" then
    print("press \142 to exit", 30, 14, 6)

    local beat_len = flr(1800 / tempo)
    local beat = flr(play_along_timer / beat_len) + 1
    local beat_in_phase = ((beat - 1) % 4) + 1

    local phase_name = "prepare"
    if beat > 8 then
      phase_name = "reveal"
    elseif beat > 4 then
      phase_name = "play"
    end

    local banner_col = 13
    local text = "prepare"
    if phase_name == "play" then
      banner_col = 10
      text = "play!"
    elseif phase_name == "reveal" then
      banner_col = 11
      text = "revealed"
    end

    rectfill(0, 114, 128, 128, banner_col)
    print(text, 64 - #text * 2, 116, 0)

    local dot_start_x = 64 - 15
    for i = 1, 4 do
      local dx = dot_start_x + (i - 1) * 10
      if i == beat_in_phase then
        circfill(dx, 123, 2, 0)
      else
        circ(dx, 123, 2, 0)
      end
    end
  end
end

function draw_valves(start_x, y)
  local draw_note = nil
  if state == "reference" then
    if ref_flavor == "list" then
      draw_note = notes[ref_idx]
    else
      local p = get_pitch(ref_v, ref_air)
      draw_note = find_note_by_pitch(p)
    end
  else
    draw_note = note
  end

  local reveal = true
  if state == "play_along" then
    local beat_len = flr(1800 / tempo)
    local beat = flr(play_along_timer / beat_len) + 1
    if beat <= 8 then
      reveal = false
    end
  end

  local slide_1_out = false
  local slide_3_out = false
  if draw_note then
    local name = draw_note.name
    if name == "f#3" or name == "g3" or name == "c#4" or name == "d4" then
      slide_3_out = true
    elseif name == "a4" or name == "d5" then
      slide_1_out = true
    end
  end

  for i = 1, 3 do
    local vx = start_x + (i - 1) * 24
    local active = user_v[i]
    if state == "reference" then
      if ref_flavor == "list" then
        active = draw_note.v[i]
      else
        active = ref_v[i]
      end
    elseif (state == "result" and not is_correct) or (state == "play_along" and reveal) then
      active = draw_note.v[i]
    end

    -- draw slides
    if i == 1 then
      if slide_1_out then
        rect(vx - 10, y + 1, vx - 2, y + 5, 6)
      else
        rect(vx - 6, y + 1, vx - 2, y + 5, 5)
      end
    elseif i == 3 then
      if slide_3_out then
        rect(vx + 10, y + 1, vx + 18, y + 5, 6)
      else
        rect(vx + 10, y + 1, vx + 14, y + 5, 5)
      end
    end

    rect(vx - 2, y - 8, vx + 10, y + 12, 5)
    if not reveal then
      rectfill(vx, y, vx + 8, y + 8, 5)
      print("?", vx + 3, y + 2, 7)
    else
      if active then
        rectfill(vx, y, vx + 8, y + 8, 12)
        print(i, vx + 3, y + 2, 0)
      else
        rect(vx, y, vx + 8, y + 8, 7)
        print(i, vx + 3, y + 2, 7)
      end
    end
  end
end

function draw_air()
  local draw_note = nil
  if state == "reference" then
    if ref_flavor == "list" then
      draw_note = notes[ref_idx]
    end
  else
    draw_note = note
  end
  local active_air = user_air
  local col = 12

  local reveal = true
  if state == "play_along" then
    local beat_len = flr(1800 / tempo)
    local beat = flr(play_along_timer / beat_len) + 1
    if beat <= 8 then
      reveal = false
    else
      active_air = draw_note.air
      col = 11
    end
  elseif state == "result" then
    active_air = draw_note.air
    col = is_correct and 11 or 8
  elseif state == "reference" then
    if ref_flavor == "list" then
      active_air = draw_note.air
    else
      active_air = ref_air
    end
    col = 11
  end

  for i = 1, 5 do
    local by = 64 - (i * 8)
    local fill_col = 5
    if reveal then
      if active_air == i then
        fill_col = col
      end
    end

    rectfill(116, by, 122, by + 6, fill_col)
    rect(115, by - 1, 123, by + 7, 6)
    print(i, 110, by + 1, 6)
  end
end

function play_pitch(p)
  local addr = 0x3354
  poke(addr, p)
  poke(addr + 1, 40)
  poke(addr + 2, p)
  poke(addr + 3, 40)
  poke(addr + 65, 30)
  poke(addr + 66, 0)
  poke(addr + 67, 1)
  sfx(5, 3)
end

function stop_pitch()
  sfx(-1, 3)
end

function play_click()
  local addr = 0x3310
  poke(addr, 50)
  poke(addr + 1, 51)
  poke(addr + 2, 0)
  poke(addr + 3, 0)
  poke(addr + 65, 2)
  poke(addr + 66, 0)
  poke(addr + 67, 0)
  sfx(4, 2)
end

function draw_elephant(x, y, playing, happy, flip)
  local d = flip and -1 or 1

  -- back legs (dark blue, color 1)
  rectfill(x - 6 * d, y - 3, x - 3 * d, y, 1)
  rectfill(x + 1 * d, y - 3, x + 4 * d, y, 1)

  -- front legs (lavender, color 13)
  rectfill(x - 4 * d, y - 4, x - 1 * d, y, 13)
  rectfill(x + 2 * d, y - 4, x + 5 * d, y, 13)

  -- body
  circfill(x, y - 6, 7, 13)

  -- head
  circfill(x, y - 13, 5, 13)

  -- cheek blush (pink, color 14)
  pset(x + 2 * d, y - 12, 14)

  -- eyes
  if happy then
    -- curved happy eye
    line(x + 1 * d, y - 14, x + 2 * d, y - 15, 0)
    line(x + 2 * d, y - 15, x + 3 * d, y - 14, 0)
  else
    -- normal dot eye
    pset(x + 2 * d, y - 14, 0)
  end

  -- back ear (dark blue, color 1)
  circfill(x - 5 * d, y - 14, 4, 1)

  -- front ear (lavender & pink inner)
  local flap = 0
  if playing then
    flap = flr(sin(t() * 8) * 2)
  end
  circfill(x - 4 * d, y - 13 + flap, 4, 13)
  circfill(x - 4 * d, y - 13 + flap, 2, 14)

  -- trunk
  if playing then
    line(x + 4 * d, y - 12, x + 7 * d, y - 11, 13)
    line(x + 7 * d, y - 11, x + 8 * d, y - 14, 13)
    line(x + 8 * d, y - 14, x + 7 * d, y - 16, 13)

    -- floating music note (yellow, color 10)
    local note_t = (t() * 0.8) % 1
    local nx = x + 7 * d + note_t * 16
    local ny = y - 16 - note_t * 16 + sin(t() * 6) * 2
    circfill(nx, ny, 1, 10)
    line(nx + 1, ny, nx + 1, ny - 3, 10)
    pset(nx + 2, ny - 3, 10)
  else
    line(x + 4 * d, y - 12, x + 6 * d, y - 10, 13)
    line(x + 6 * d, y - 10, x + 6 * d, y - 7, 13)
  end
end

function get_pitch(v, air)
  local natural_pitches = { 24, 31, 36, 40, 43 }
  local base = natural_pitches[air]

  local offset = 0
  if v[1] and v[2] and v[3] then
    offset = -6
  elseif v[1] and v[3] then
    offset = -5
  elseif v[2] and v[3] then
    offset = -4
  elseif (v[1] and v[2]) or v[3] then
    offset = -3
  elseif v[1] then
    offset = -2
  elseif v[2] then
    offset = -1
  end

  return base + offset
end

function find_note_by_pitch(p)
  for n in all(notes) do
    if n.p == p then
      return n
    end
  end
  return nil
end

function pick_weighted_note(note_list)
  local total_w = 0
  for n in all(note_list) do
    total_w += n.w
  end

  local r = rnd(total_w)
  local sum = 0
  for n in all(note_list) do
    sum += n.w
    if r <= sum then
      return n
    end
  end
  return note_list[1]
end

