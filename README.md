# NIGHT BELL: OFFICE SHIFT

A from-scratch Godot 4.6 project for a first-person psychological office horror vertical slice.

## Implemented slice

- Main menu with New Game, Continue, Options, Exit, plus pause menu and adjustable fullscreen, mouse sensitivity, and master volume controls.
- First-person WASD/mouse movement, sprint, interaction ray targeting, pause, save/load.
- Three stacked office floors with a denser first-floor layout: reception, security desk, waiting sofas, turnstiles, open space, kitchen props, archive cabinets, server racks, corridor doors, plants/trash details, plus HR/IT/accounting/legal/final-report spaces upstairs.
- Composite office furniture and collision for walls, desks, chairs, partitions, interactables, elevator, NPC standees, and major props.
- 13 named NPC standees with roles, portraits in dialogue UI, collision, prompts, and lore dialogue.
- Quest-safe interactables for work computer, radio with on/off and track modes, printer/copier, CCTV, elevator, archive evidence, IT terminal, final report, and emergency exit. Early interactions provide fallback text instead of softlocking.
- Evidence tracking, explicit guarded quest chain from Kazuo to Aya, computer, radio, printer, CCTV, archive, return objective, final report flow, and bad/neutral/secret-good endings.

## Controls

- WASD: move
- Mouse: look
- Shift: fast walk
- E: interact
- Enter: advance dialogue
- Esc: pause/close interfaces

## Run

Open `project.godot` in Godot 4.6.x and run the main scene.

## Current quest route

1. Start New Game and talk to Kazuo Sato at the security desk.
2. Talk to Aya Morita at reception to activate the temporary pass.
3. Use the work computer in open-space and read the night-shift email.
4. Turn on/tune the radio.
5. Print Form N-13 at the printer/copier.
6. Review CCTV in the security room and save the archive recording.
7. Collect the old archive folder, then return to Kazuo or Aya / continue into the report-ending path.
