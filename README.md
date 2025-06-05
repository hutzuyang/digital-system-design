# digital-system-design

This project implements a **bomberman game** on FPGA using Verilog, VGA sync generation, and input/output control, which:

* **Allows player control** using push buttons and keyboard.
* **Supports two stages** via a switch selector.
* **Displays in-game data** using **seven-segment displays** and **LED indicators**.
* **Implements bomb logic** with countdown timers and damage detection.
* **Includes multiple bomb types and enemies** with type-specific interactions.

The system processes **input from switches and buttons**, handles movement and attack logic, and outputs **visualized game state** through screen rendering and indicators.

## 📄 Input Format

This FPGA project uses the following input files:

* **`Final_project.v`** - Top-level game control logic (movement, bomb placing, rendering)
* **`Final_project_Debounce.v`** - Handles mechanical bounce from push button inputs
* **`Final_project_SyncGeneration.v`** - Generates VGA timing and sync signals
* **`Final_project.xdc`** - Xilinx constraint file (pin assignment for switches, buttons, VGA, etc.)
* **`Final_project.bit`** - Bitstream for programming the FPGA board

## 📄 Output Format

Once programmed on the FPGA board:

* **VGA display** shows an 8x8 tile-based game world
<img src="![image](https://github.com/user-attachments/assets/4e187ba6-9267-40d5-9beb-739cb366a4bb)" width="50%" height="50%">
* **Seven-segment displays** show game stats:

  * Current stage
  * Bomb timer
  * Rescue countdown
  * Remaining targets
  * Selected bomb type
* **LEDs** blink with different animations indicating win/loss

## 🧰 Project Structure

```
📂 Final_Project/
├── 📄Final_project.v 
├── 📄Final_project_Debounce.v
├── 📄Final_project_SyncGeneration.v
├── 📄Final_project.xdc
├── 📄Final_project.bit
└── 📜README.md
```

## 🔹 Game System Flow

### 1. Initialize & Start

* Use **Switch 1** to select stage (OFF: Stage 1, ON: Stage 2)
* Press **P15** (Reset) to begin

### 2. Character Movement (Push Button)

* S4: Move Up
* S3: Move Left
* S2: Move Down
* S0: Move Right
* S1: Place Bomb
* P15: Reset Game

### 3. Bomb Type Selection (Keyboard)

* Press **F/Q/W/E** to change bomb type (1\~4)
* Different types affect specific enemies

### 4. Bomb Explosion Logic

* Bombs explode in 1–4 seconds depending on type
* Affects 4 directions (up/down/left/right)
* Kills enemies or breaks obstacles if type matches

### 5. Indicators

* **LEDs**: flash to indicate success/failure
* **7-segment**:

  * Seg1: Current level
  * Seg3\~4: Countdown timer
  * Seg6: Remaining targets
  * Seg8: Selected bomb type

## ⚡ Example Execution

Upload and run with Vivado:

```bash
# Open Vivado, load project, and generate bitstream
# Program the FPGA board with Final_project.bit
```

## ✅ Game Conditions

### Stage 1:

* Use bomb type 1 only (F)
* At least 1 rescue target
* Countdown 30s, each rescue +3s, hit by bomb = fail
<img src="![image](https://github.com/user-attachments/assets/e92b4f89-53aa-482c-a654-e2c8d4e23c89)" width="50%" height="50%">

### Stage 2:

* Mix of obstacles and enemies
* Must match bomb type to enemy:
<img src="![image](https://github.com/user-attachments/assets/9d4a6563-2ea3-469b-954c-a087477360f4)" width="50%" height="50%">

* Incorrect bomb = no effect
* Rescue all targets within time

## 🖼️ Visual Output

Below is an example of the VGA output map (8x8 grid):

* Stage 1:
<img src="![image](https://github.com/user-attachments/assets/4e187ba6-9267-40d5-9beb-739cb366a4bb)" width="50%" height="50%">
* Stage 2:
<img src="![image](https://github.com/user-attachments/assets/34b364f6-5033-4fc5-9b4a-3f11b65ea167)" width="50%" height="50%">

---

> Developed by 109501513 & 109501524
> Final Project for Digital System Design
