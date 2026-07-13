-- title:   Trumpet Practice & Trainer
-- author:  Antigravity
-- desc:    TIC-80 port of the PICO-8 Trumpet Trainer
-- script:  lua

-- PICO-8 Compatibility Layer

local _cls = cls
local _rect = rect
local _rectb = rectb
local _circ = circ
local _circb = circb
local _line = line
local _print = print
local _sfx = sfx
local _btn = btn
local _btnp = btnp

-- Sweetie-16 palette color mapper
local function c(p8_col)
  local map = {
    [0] = 15, -- Black -> Dark Slate
    [1] = 8,  -- Dark Blue -> Dark Blue
    [2] = 1,  -- Dark Purple -> Purple
    [3] = 7,  -- Dark Green -> Dark Teal
    [4] = 14, -- Brown -> Slate Gray
    [5] = 15, -- Dark Gray -> Dark Slate
    [6] = 13, -- Light Gray -> Medium Gray
    [7] = 12, -- White -> White
    [8] = 2,  -- Red -> Crimson Red
    [9] = 3,  -- Orange -> Orange-Red
    [10] = 4, -- Yellow -> Yellow-Gold
    [11] = 6, -- Green -> Grass Green
    [12] = 10, -- Light Blue -> Sky Blue
    [13] = 13, -- Lavender -> Medium Gray
    [14] = 2,  -- Pink -> Crimson Red (cheek blush, front ear inner)
    [15] = 3,  -- Peach -> Orange-Red (selection bar highlight)
  }
  return map[p8_col] or p8_col
end

local function cls(col)
  _cls(c(col))
end

local function rectfill(x0, y0, x1, y1, col)
  if x0 > x1 then x0, x1 = x1, x0 end
  if y0 > y1 then y0, y1 = y1, y0 end
  _rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1, c(col))
end

local function rect(x0, y0, x1, y1, col)
  if x0 > x1 then x0, x1 = x1, x0 end
  if y0 > y1 then y0, y1 = y1, y0 end
  _rectb(x0, y0, x1 - x0 + 1, y1 - y0 + 1, c(col))
end

local function line(x0, y0, x1, y1, col)
  _line(x0, y0, x1, y1, c(col))
end

local function circfill(x, y, r, col)
  _circ(x, y, r, c(col))
end

local function circ(x, y, r, col)
  _circb(x, y, r, c(col))
end

local function pset(x, y, col)
  pix(x, y, c(col))
end

local function print(str, x, y, col)
  if type(str) ~= "string" then
    str = tostring(str)
  end
  str = str:gsub("\139", "L")
  str = str:gsub("\145", "R")
  str = str:gsub("\148", "U")
  str = str:gsub("\153", "D")
  str = str:gsub("\151", "A")
  str = str:gsub("\142", "B")
  
  _print(str, x, y, c(col), false, 1, false)
end

-- Button mapping
local BTN_MAP = {
  [0] = 2, -- Left -> Left (2)
  [1] = 3, -- Right -> Right (3)
  [2] = 0, -- Up -> Up (0)
  [3] = 1, -- Down -> Down (1)
  [4] = 5, -- Button O -> Button B (5) (Going Back)
  [5] = 4, -- Button X -> Button A (4) (Confirming/Selecting)
}

local function btn(i)
  return _btn(BTN_MAP[i] or i)
end

local function btnp(i)
  return _btnp(BTN_MAP[i] or i)
end

-- Table helpers
local function add(t, v)
  table.insert(t, v)
end

local function all(t)
  local i = 0
  local n = #t
  return function()
    i = i + 1
    if i <= n then return t[i] end
  end
end

-- Math helpers
local function flr(x)
  return math.floor(x)
end

local function max(a, b)
  return math.max(a, b)
end

local function min(a, b)
  return math.min(a, b)
end

local function rnd(x)
  if type(x) == "table" then
    if #x == 0 then return nil end
    return x[math.random(#x)]
  else
    return math.random() * (x or 1)
  end
end

local function sin(x)
  return math.sin(-x * 2 * math.pi)
end

local function cos(x)
  return math.cos(x * 2 * math.pi)
end

local function sub(str, i, j)
  return string.sub(str, i, j)
end

local function t()
  return time() / 1000
end

local function poke(addr, val)
  -- no-op
end

-- Sound effects system
local function sfx(id, channel)
  if id == 0 then
    -- Success chime: E-5
    _sfx(0, 52, 15, channel or 1, 12, 0)
  elseif id == 1 then
    -- Failure chime: C-3
    _sfx(0, 24, 20, channel or 1, 12, 0)
  elseif id == 4 then
    -- Click metronome: C-6
    _sfx(0, 60, 2, channel or 2, 10, 0)
  elseif id == -1 then
    -- Stop sound
    _sfx(-1, 0, 0, channel or 3)
  end
end

-- Play drone note
function play_pitch(p)
  local midi_note = p + 12
  _sfx(1, midi_note, -1, 3, 12, 0)
end

function stop_pitch()
  _sfx(-1, 0, 0, 3)
end

function play_click()
  sfx(4, 2)
end

-- ==========================================
-- PICO-8 Trumpet Trainer game logic (ported)
-- ==========================================

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
  quiz_input_mode = "toggle"
  valve_display_mode = "show"

  -- practice state variables
  score = 0
  total = 0
  is_correct = false
  user_v = { false, false, false }
  user_air = 2
  result_timer = 0
  exit_timer = 0

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
        x = rnd(240),
        y = rnd(136),
        speed = (0.2 + rnd(0.8)) * 0.5,
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
end

function _update()
  if state == "menu" then
    for s in all(stars) do
      s.y = s.y - s.speed
      if s.y < 0 then
        s.y = 136
        s.x = rnd(240)
      end
    end
    if btnp(2) then menu_opt = max(1, menu_opt - 1) end
    if btnp(3) then menu_opt = min(8, menu_opt + 1) end

    if menu_opt == 1 then
      if btnp(0) or btnp(1) then
        if quiz_input_mode == "toggle" then
          quiz_input_mode = "sticky"
        else
          quiz_input_mode = "toggle"
        end
      end
    elseif menu_opt == 3 then
      if btnp(0) then
        if ref_flavor == "list" then
          ref_flavor = "sticky"
        elseif ref_flavor == "valves" then
          ref_flavor = "list"
        elseif ref_flavor == "sticky" then
          ref_flavor = "valves"
        end
      elseif btnp(1) then
        if ref_flavor == "list" then
          ref_flavor = "valves"
        elseif ref_flavor == "valves" then
          ref_flavor = "sticky"
        elseif ref_flavor == "sticky" then
          ref_flavor = "list"
        end
      end
    elseif menu_opt == 4 then
      if btnp(0) then
        if valve_display_mode == "show" then
          valve_display_mode = "reversed"
        elseif valve_display_mode == "hidden" then
          valve_display_mode = "show"
        elseif valve_display_mode == "reversed" then
          valve_display_mode = "hidden"
        end
      elseif btnp(1) or btnp(5) then
        if valve_display_mode == "show" then
          valve_display_mode = "hidden"
        elseif valve_display_mode == "hidden" then
          valve_display_mode = "reversed"
        elseif valve_display_mode == "reversed" then
          valve_display_mode = "show"
        end
      end
    elseif menu_opt == 5 then
      if btnp(0) then min_air = max(1, min_air - 1) end
      if btnp(1) or btnp(5) then
        min_air = min_air + 1
        if min_air > 5 then min_air = 1 end
        if max_air < min_air then max_air = min_air end
      end
    elseif menu_opt == 6 then
      if btnp(0) then
        max_air = max(1, max_air - 1)
        if min_air > max_air then min_air = max_air end
      end
      if btnp(1) or btnp(5) then
        max_air = max_air + 1
        if max_air > 5 then max_air = 1 end
        if min_air > max_air then min_air = max_air end
      end
    elseif menu_opt == 7 then
      if btnp(0) or btnp(1) or btnp(5) then is_bb = not is_bb end
    elseif menu_opt == 8 then
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
        exit_timer = 0
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

      local is_playing_ref = btn(5)

      if is_playing_ref then
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
    if quiz_input_mode == "sticky" then
      user_v[1] = btn(0)
      user_v[3] = btn(1)
      user_v[2] = btn(3)
    else
      if btnp(0) then user_v[1] = not user_v[1] end
      if btnp(1) then user_v[3] = not user_v[3] end
      if btnp(3) then user_v[2] = not user_v[2] end
    end

    if btnp(4) then
      state = "menu"
    end

    if btnp(5) then
      total = total + 1
      local valves_correct = user_v[1] == note.v[1]
          and user_v[2] == note.v[2]
          and user_v[3] == note.v[3]

      if valves_correct then
        is_correct = true
        score = score + 1
        sfx(0)
        note.w = max(0.2, note.w * 0.5)
      else
        is_correct = false
        sfx(1)
        note.w = min(5, note.w * 2)
      end
      local p = is_bb and note.p - 2 or note.p
      play_pitch(p)
      result_timer = 0
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

    if not is_correct and result_timer and result_timer >= 0 then
      result_timer = result_timer + 1
      local half_measure = flr(7200 / tempo)
      if result_timer >= half_measure then
        stop_pitch()
        result_timer = -1
      end
    end
  elseif state == "play_along" then
    if btnp(4) then
      stop_pitch()
      state = "menu"
      return
    end

    -- TIC-80 is 60 FPS, so we use 3600 frames per beat
    local beat_len = flr(3600 / tempo)
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

    play_along_timer = play_along_timer + 1

    if play_along_timer >= cycle_len then
      score = score + 1
      total = total + 1

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
    circfill(228, 16, 6, 10) -- yellow sun

    -- draw grass hills
    rectfill(0, 118, 240, 136, 3) -- dark green savanna ground
    rectfill(0, 118, 240, 120, 11) -- light green top grass line

    rectfill(0, 0, 240, 12, 1) -- dark blue banner for title
    print("tic-80 trumpet trainer", 54, 4, 7)

    rectfill(48, 16, 192, 107, 7) -- white paper/card menu box
    rect(48, 16, 192, 107, 5) -- dark gray menu outline

    print("select mode:", 84, 20, 5) -- dark gray subtitle

    local c1 = menu_opt == 1 and 8 or 1
    local c2 = menu_opt == 2 and 8 or 1
    local c3 = menu_opt == 3 and 8 or 1
    local c4 = menu_opt == 4 and 8 or 1
    local c5 = menu_opt == 5 and 8 or 1
    local c6 = menu_opt == 6 and 8 or 1
    local c7 = menu_opt == 7 and 8 or 1
    local c8 = menu_opt == 8 and 8 or 1

    local sel_y = 28 + (menu_opt - 1) * 9
    rectfill(56, sel_y - 1, 184, sel_y + 6, 15) -- selection highlight

    print("prac: < " .. quiz_input_mode .. " >", 64, 28, c1)
    print("play-along", 64, 37, c2)
    print("ref: < " .. ref_flavor .. " >", 64, 46, c3)
    print("valves: < " .. valve_display_mode .. " >", 64, 55, c4)
    print("min air: < " .. min_air .. " >", 64, 64, c5)
    print("max air: < " .. max_air .. " >", 64, 73, c6)
    print("trumpet: < " .. (is_bb and "bB" or "c") .. " >", 64, 82, c7)
    print("tempo: < " .. tempo .. " > bpm", 64, 91, c8)

    local arrow_x = 56 + sin(t() * 2) * 2
    print(">", arrow_x, sel_y, 8) -- selection arrow

    if menu_opt == 2 then
      print("press A to start", 72, 110, 1)
    else
      print("adjust: L/R or press A", 54, 110, 1)
    end
    draw_elephant(216, 126, true, true, true)
    return
  end

  -- header
  rectfill(0, 0, 240, 12, 0)
  print("tic-80 trumpet trainer", 4, 4, 7)

  if state == "quiz" or state == "result" or state == "play_along" then
    local score_str = score .. "/" .. total
    print(score_str, 236 - #score_str * 6, 4, 10)
  elseif state == "reference" then
    print("reference", 180, 4, 10)
  end

  if state == "quiz" or state == "result" then
    local mastery = flr(100 * (5 - note.w) / 4.8)
    print("srs: " .. mastery .. "%", 4, 16, 6)
  end

  -- treble clef staff (lines centered at x=76 to 164)
  for i = 0, 4 do
    local line_y = 24 + (i * 8)
    line(76, line_y, 164, line_y, 7)
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
      local beat_len = flr(3600 / tempo)
      local beat = flr(play_along_timer / beat_len) + 1
      if beat <= 8 then
        show_name = false
      end
    end

    if show_name then
      print(draw_note.name, 24, 38, 10)
    else
      print("?", 24, 38, 5)
    end

    -- dynamic ledger lines
    local l_y = 64
    while l_y <= draw_note.y do
      line(112, l_y, 128, l_y, 7)
      l_y = l_y + 8
    end

    -- accidentals (sharp/flat)
    local acc = sub(draw_note.name, 2, 2)
    if acc == "#" or acc == "b" or acc == "B" then
      print(acc, 110, draw_note.y - 2, 7)
    end

    -- note head (centered at x=120)
    circfill(120, draw_note.y, 4, 10)
  else
    -- draw_note is nil (only possible in reference mode valves flavor)
    print("?", 24, 38, 5)
    print("?", 118, 52, 5)
  end

  draw_valves(90, 100)
  draw_air()

  -- draw elephant mascot
  local happy = false
  local playing = false
  local ex = 24
  local ey = 94
  if state == "result" then
    happy = is_correct
    playing = true
  elseif state == "play_along" then
    local beat_len = flr(3600 / tempo)
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
    if quiz_input_mode == "sticky" then
      print("hold L/D/R: valves", 66, 118, 6)
    else
      print("L/D/R: valves", 81, 118, 6)
    end
    print("A: submit  B: quit", 66, 126, 7)
  elseif state == "result" then
    if is_correct then
      rectfill(0, 116, 240, 136, 11)
      print("correct!", 96, 118, 0)
      print("A: next  B: quit", 72, 126, 0)
    else
      rectfill(0, 116, 240, 136, 8)
      print("wrong! correct shown", 60, 118, 7)
      print("A: next  B: quit", 72, 126, 7)
    end
  elseif state == "reference" then
    if ref_flavor == "list" then
      print("L/R: navigate  A: play note", 39, 118, 6)
      print("press B for menu", 72, 126, 7)
    elseif ref_flavor == "valves" then
      print("L/D/R: valves  Up: cycle air", 36, 118, 6)
      print("A: play note  B: quit", 57, 126, 7)
    elseif ref_flavor == "sticky" then
      print("hold L/D/R: valves  Up: cycle air", 21, 118, 6)
      print("A: play note  B: quit", 57, 126, 7)
    end
  elseif state == "play_along" then
    print("press B to exit", 75, 14, 6)

    local beat_len = flr(3600 / tempo)
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

    rectfill(0, 116, 240, 136, banner_col)
    print(text, 120 - #text * 3, 118, 0)

    local dot_start_x = 120 - 15
    for i = 1, 4 do
      local dx = dot_start_x + (i - 1) * 10
      if i == beat_in_phase then
        circfill(dx, 128, 2, 0)
      else
        circ(dx, 128, 2, 0)
      end
    end
  end
end

function draw_valves(start_x, y)
  local reveal = true
  if state == "play_along" then
    local beat_len = flr(3600 / tempo)
    local beat = flr(play_along_timer / beat_len) + 1
    if beat <= 8 then
      reveal = false
    end
  end

  local is_exercise = (state == "quiz" or state == "result" or state == "play_along")
  if is_exercise and valve_display_mode == "hidden" then
    if state == "quiz" or (state == "play_along" and not reveal) then
      return
    end
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

  local slide_1_out = false
  local slide_3_out = false
  local show_slides = true
  if state == "quiz" then
    show_slides = false
  elseif state == "play_along" and not reveal then
    show_slides = false
  end

  if show_slides and draw_note then
    local name = draw_note.name
    if name == "f#3" or name == "g3" or name == "c#4" or name == "d4" then
      slide_3_out = true
    elseif name == "a4" or name == "d5" then
      slide_1_out = true
    end
  end

  for step = 1, 3 do
    local vx = start_x + (step - 1) * 24
    local i = (is_exercise and valve_display_mode == "reversed") and (4 - step) or step
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
    if step == 1 then
      local slide_out = (is_exercise and valve_display_mode == "reversed") and slide_3_out or slide_1_out
      if slide_out then
        rectfill(vx - 14, y + 2, vx - 3, y + 9, 6) -- extended slide (light gray)
        rect(vx - 14, y + 2, vx - 3, y + 9, 5) -- dark outline
        rectfill(vx - 12, y + 4, vx - 3, y + 7, 1) -- hollow center (bg)
        rect(vx - 17, y + 4, vx - 15, y + 7, 6) -- thumb saddle
      else
        rectfill(vx - 8, y + 2, vx - 3, y + 9, 5) -- retracted slide (dark gray)
        rect(vx - 8, y + 2, vx - 3, y + 9, 0) -- black outline
        rectfill(vx - 6, y + 4, vx - 3, y + 7, 1) -- hollow center (bg)
      end
    elseif step == 3 then
      local slide_out = (is_exercise and valve_display_mode == "reversed") and slide_1_out or slide_3_out
      if slide_out then
        rectfill(vx + 11, y + 2, vx + 22, y + 9, 6) -- extended slide (light gray)
        rect(vx + 11, y + 2, vx + 22, y + 9, 5) -- dark outline
        rectfill(vx + 11, y + 4, vx + 20, y + 7, 1) -- hollow center (bg)
        rect(vx + 22, y + 4, vx + 24, y + 7, 6) -- finger ring
      else
        rectfill(vx + 11, y + 2, vx + 16, y + 9, 5) -- retracted slide (dark gray)
        rect(vx + 11, y + 2, vx + 16, y + 9, 0) -- black outline
        rectfill(vx + 11, y + 4, vx + 14, y + 7, 1) -- hollow center (bg)
      end
    end

    -- Calculate piston and button positions
    local button_top, stem_top, button_color
    if not reveal then
      button_top = y - 10
      stem_top = y - 7
      button_color = 5 -- dark gray mystery cap
    else
      if active then
        button_top = y - 5
        stem_top = y - 2
        button_color = 12 -- sky blue active cap
      else
        button_top = y - 10
        stem_top = y - 7
        button_color = 7 -- white inactive cap
      end
    end

    -- 1. Draw Piston Stem (rod)
    rectfill(vx + 3, stem_top, vx + 5, y - 2, 6) -- light/medium gray rod
    rect(vx + 3, stem_top, vx + 5, y - 2, 5) -- dark gray outline

    -- 2. Draw Finger Button (cap)
    rectfill(vx - 2, button_top, vx + 10, button_top + 2, button_color) -- cap
    rect(vx - 2, button_top, vx + 10, button_top + 2, 5) -- cap outline

    -- 3. Draw Casing body and caps
    -- Casing Body
    rectfill(vx - 3, y + 1, vx + 11, y + 10, 10) -- gold/brass casing
    rect(vx - 3, y + 1, vx + 11, y + 10, 5) -- dark gray outline
    line(vx - 2, y + 2, vx - 2, y + 9, 7) -- white highlight shine

    -- Casing Top Cap/Collar
    rectfill(vx - 4, y - 2, vx + 12, y, 10)
    rect(vx - 4, y - 2, vx + 12, y, 5)

    -- Casing Bottom Cap
    rectfill(vx - 4, y + 11, vx + 12, y + 12, 10)
    rect(vx - 4, y + 11, vx + 12, y + 12, 5)

    -- 4. Print Valve Number/Status
    if not reveal then
      print("?", vx + 2, y + 3, 7)
    else
      local num_color = active and 0 or 5 -- black if active, dark gray if inactive
      print(i, vx + 2, y + 3, num_color)
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
  if state == "quiz" then
    active_air = draw_note.air
    col = 11
  elseif state == "play_along" then
    local beat_len = flr(3600 / tempo)
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

    rectfill(228, by, 234, by + 6, fill_col)
    rect(227, by - 1, 235, by + 7, 6)
    print(i, 220, by + 1, 6)
  end
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
    total_w = total_w + n.w
  end

  local r = rnd(total_w)
  local sum = 0
  for n in all(note_list) do
    sum = sum + n.w
    if r <= sum then
      return n
    end
  end
  return note_list[1]
end

-- ==========================================
-- TIC-80 Main Loop entry point
-- ==========================================

local initialized = false

function TIC()
  if not initialized then
    _init()
    initialized = true
  end
  _update()
  _draw()
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- 001:020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
