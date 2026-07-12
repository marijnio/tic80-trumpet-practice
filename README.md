# PICO-8 Trumpet Fingering & Partial Trainer

An interactive, game-like educational application for the **PICO-8 fantasy console**, specifically designed and optimized for retro handheld devices (such as the **ANBERNIC RG35XXSP**, Miyoo Mini, and similar devices) as well as desktop emulators and web players.

This tool helps trumpet players practice both **valve fingerings** and **air pressure partials** (representing embouchure and pitch targeting) across a chromatic range of 26 notes (from F#3 to G5) using a randomized practice engine.

---

## 🎺 Key Features

* **Complete Practice Range:** Practicing notes from low **F#3** up to high **G5**, covering the standard beginner-to-intermediate range of the trumpet.
* **Treble Clef Visualization:** Real-time rendering of notes on a musical staff with dynamic ledger lines for notes above/below the staff, plus sharp (`#`) and flat (`b`) accidentals.
* **Valve & Air Representation:**
  * **Valves:** Simulates the three physical trumpet valves.
  * **Air Pressure / Partials:** Simulates embouchure and air speed requirements by dividing notes into 5 air levels (harmonic partial groups).
* **Smart Repetition (Practice Mode):** Utilizes a lightweight Spaced Repetition System (SRS) with a live mastery percentage display (e.g. `srs: 83%`). Incorrectly answered notes double in weight (making them appear more frequently), while correct answers halve in weight to prevent redundant drill.
* **Randomized progression (Play-Along Mode):** Notes are chosen randomly from the selection pool to provide a diverse, hands-free playing session.
* **Three Flexible Modes:** 
  * **Quiz Mode:** Tests your recall of both valve fingerings and air pressure levels using interactive controls on the device.
  * **Play-Along Mode (Hands-Free):** Specifically designed for practicing with your **actual trumpet** in hand. It guides you rhythmically using audio metronome clicks and pitches.
  * **Reference Mode:** Allows you to browse through notes or explore combinations. You can choose between three flavors on the main menu:
    * **List Flavor:** Chronologically browse through all 26 notes from low to high to review correct fingerings and air levels.
    * **Valves Flavor:** Actively configure the valves and air levels to explore sound pitches interactively (taps toggle valves on/off).
    * **Sticky Flavor:** Valves are registered as real-time button holds (spring-return) rather than toggles—simulating a real trumpet's valve action. Pressing buttons changes the note instantly while you hold the play button.

---

## 🎮 Handheld & Emulator Controls

Since the application is designed to be played on handheld retro consoles (like the ANBERNIC RG35XXSP) and desktop computers, the controls are mapped to PICO-8 standard inputs:

| PICO-8 Input | Desktop Key | Handheld Button | Menu / Reference Action | Quiz Mode Action |
|---|---|---|---|---|
| **Left** | `Left Arrow` | **D-Pad Left** | Adjust settings (on menu) / Navigate Reference (Prev) | Toggle **Valve 1** (1st valve) |
| **Right** | `Right Arrow` | **D-Pad Right** | Adjust settings (on menu) / Navigate Reference (Next) | Toggle **Valve 3** (3rd valve) |
| **Up** | `Up Arrow` | **D-Pad Up** | Move Selection Up | Cycle **Air Pressure** (1 to 5) |
| **Down** | `Down Arrow` | **D-Pad Down** | Move Selection Down | Toggle **Valve 2** (2nd valve) |
| **Button 4 (🅾️)** | `Z` / `C` | **A** | Return to Menu | **Quit / Return to Menu** |
| **Button 5 (❎)** | `X` / `V` | **B** | Confirm / Select (on menu) / Hold to play note (in Reference) | **Submit Answer** (in Quiz) / **Continue** (in Result) |

> [!NOTE]
> **Adjusting Air Pressure in Quiz Mode:** To change the air level indicator on the right side of the screen, simply press **D-Pad Up** to cycle through air pressure levels 1–5.

---

## 🥁 Hands-Free Play-Along Mode

The **Play-Along Mode** is designed for practice sessions where you are holding and playing a physical trumpet. Because you cannot easily press valve combinations on the PICO-8 device while playing, this mode runs on a continuous **12-beat loop** (which is 12 seconds total per note at 60 BPM, scaling dynamically based on the configured menu tempo):

1. **Prepare Phase (Beats 1-4):**
   * The staff displays the target note.
   * The note name, fingerings, and air pressure indicators are hidden (marked with `?` or grayed out).
   * A metronome click plays on each beat to give you a count-in.
2. **Play Phase (Beats 5-8):**
   * Play the note on your physical trumpet!
   * The metronome continues clicking.
   * The console plays a sustained **reference pitch tone** corresponding to the note. Use this tone to guide your pitch target and intonation.
   * Note name, fingerings, and air pressure indicators remain hidden.
3. **Reveal Phase (Beats 9-12):**
   * The reference tone stops.
   * The correct valve fingerings and air pressure level are revealed on screen.
   * Verify your fingerings and partial against the diagram.

### Hands-Free Flow:
- **Automatic progression:** At the end of the 12 beats, the system automatically marks the note as completed (adding to your score) and moves to the next note.
- **Exiting:** Press the **🅾️ button (Z/C key)** at any time to immediately stop the pitch drone and return to the main menu.

---

## 🎼 The Note & Air Pressure Database

In trumpet playing, multiple notes share the exact same valve combinations (e.g., open `0-0-0` is used for C4, G4, C5, and E5). To play them, a trumpeter must change their lip tension and air velocity. 

This application represents this mechanic via **Air levels (1–5)**:

* **Level 1 (1st Partial Group):** F#3 to C4 (e.g., Low C is open `0-0-0` on Air 1)
* **Level 2 (2nd Partial Group):** C#4 to G4 (e.g., G4 is open `0-0-0` on Air 2)
* **Level 3 (3rd Partial Group):** G#4 to C5 (e.g., C5 is open `0-0-0` on Air 3)
* **Level 4 (4th Partial Group):** C#5 to E5 (e.g., E5 is open `0-0-0` on Air 4)
* **Level 5 (5th Partial Group):** F5 to G5 (e.g., G5 is open `0-0-0` on Air 5)

## 🐘 Ellie the Elephant Mascot!

To make your practice sessions more encouraging, **Ellie the Elephant** acts as your mascot:
* **Title Menu:** Ellie sits in the bottom-right corner, flapping her ears and blowing happy musical notes.
* **Practice & Play Modes:** Ellie stands in the lower-left corner, keeping you company.
* **Interactive Feedback:** Whenever you submit a correct answer or successfully complete a play-along note, Ellie celebrates by flapping her ears happily and blowing a musical note from her trunk!

---

## 🛠️ Installation on Retro Handhelds (e.g., RG35XXSP)

To install this cart on your ANBERNIC RG35XXSP or other devices running CFW (like Knulli, MuOS, or MinUI):

1. **Locate your ROMs folder:** Connect your SD card to your computer and navigate to the `roms/pico8/` directory.
2. **Copy the file:** Copy the `main.p8` cart (or rename it to `pico-trumpet-practice.p8`) into the directory.
3. **Execute:** 
   * Launch your device, refresh your game list, and select **PICO-8** / **pico-trumpet-practice**.
   * Alternatively, if using the official PICO-8 binary under the hood, place it in your carts folder and load it in the console command line using:
     ```text
     load pico-trumpet-practice.p8
     run
     ```
