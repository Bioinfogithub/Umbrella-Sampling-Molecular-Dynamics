# Umbrella Sampling and Molecular Dynamics

A GROMACS-based workflow for umbrella sampling, potential of mean force (PMF) calculation, and free-energy analysis along a one-dimensional reaction coordinate.

## Overview

Umbrella sampling uses a series of biased simulations centered at different positions along a reaction coordinate. The resulting configurational distributions are combined to reconstruct an unbiased free-energy profile.

This repository is organized as a reproducible workflow:

```text
System preparation
        ↓
Equilibration
        ↓
Pulling / reaction-coordinate sampling
        ↓
Frame extraction
        ↓
Reaction-coordinate analysis
        ↓
Selection of umbrella windows
        ↓
Window equilibration / preparation
        ↓
Umbrella production simulations
        ↓
Trajectory and sampling analysis
        ↓
WHAM
        ↓
PMF / free-energy profile
```

The workflow follows the general strategy described in the umbrella-sampling tutorial by Justin A. Lemkul, while the scripts and repository organization here are provided as a reusable project template. The tutorial emphasizes generating configurations along a reaction coordinate, selecting configurations at suitable spacings, running restrained simulations, and using WHAM to obtain the PMF. citeturn1search0turn2search0

## Repository Structure

```text
Umbrella-Sampling-Molecular-Dynamics/
│
├── README.md
├── .gitignore
│
├── input/
│   └── README.md
│
├── mdp/
│   ├── pull.mdp
│   └── umbrella_template.mdp
│
├── scripts/
│   ├── extract_frames.sh
│   ├── calculate_distances.sh
│   ├── generate_windows.py
│   ├── create_windows.sh
│   └── run_umbrella.sh
│
├── windows/
│   └── README.md
│
├── analysis/
│   ├── tpr-files.dat.example
│   ├── pullf-files.dat.example
│   ├── run_wham.sh
│   └── plot_pmf.py
│
└── results/
    └── README.md
```

## 1. Input Preparation

Place the system-specific files in `input/`.

Typical files include:

```text
input/
├── starting_structure.pdb
├── topol.top
├── *.itp
├── index.ndx
├── pull.tpr
└── pull.xtc
```

The exact files depend on the molecular system, force field, and simulation protocol.

This repository does not include system-specific coordinates, topology files, or trajectories by default. These should be added only when they are appropriate for redistribution.

## 2. Pulling Simulation

A pulling simulation can be used to generate configurations spanning the desired reaction coordinate.

The corresponding parameter template is:

```text
mdp/pull.mdp
```

The pull groups define the two molecular groups between which the reaction coordinate is measured.

Important parameters include:

```text
pull = yes
pull-ngroups = 2
pull-ncoords = 1
pull-coord1-groups = 1 2
pull-coord1-geometry = distance
pull-coord1-type = umbrella
```

The actual pull groups, force constant, pulling rate, simulation time, and reaction-coordinate range must be adapted to the system.

## 3. Extract Configurations

After the pulling simulation, individual configurations can be extracted from the trajectory:

```bash
cd scripts
bash extract_frames.sh
```

The script uses `gmx trjconv` to separate trajectory frames into individual coordinate files.

The resulting structures are stored under:

```text
windows/frames/
```

## 4. Calculate the Reaction Coordinate

The reaction-coordinate value of each extracted frame can then be calculated:

```bash
bash calculate_distances.sh
```

The script produces:

```text
windows/summary_distances.dat
```

The table contains the frame identifier and corresponding reaction-coordinate value.

Example:

```text
frame0001    0.500
frame0002    0.520
frame0003    0.541
...
```

## 5. Select Umbrella Windows

Neighboring umbrella windows should provide sufficient overlap in their sampled reaction-coordinate distributions.

The tutorial emphasizes that insufficient overlap can produce defects in the reconstructed PMF and may require additional intermediate windows. citeturn2search0turn1search3

For approximate window selection:

```bash
python generate_windows.py ../windows/summary_distances.dat 0.2
```

Here `0.2` is an example spacing in nm. The appropriate spacing must be determined from the system and sampling behavior.

The selected windows are written to:

```text
windows/selected_windows.dat
```

## 6. Create Umbrella Windows

The selected configurations can be organized into independent umbrella-window directories:

```bash
bash create_windows.sh
```

The resulting structure is:

```text
windows/
├── window-001/
│   ├── conf.gro
│   ├── umbrella.mdp
│   ├── topol.top
│   └── index.ndx
│
├── window-002/
│   ├── conf.gro
│   ├── umbrella.mdp
│   ├── topol.top
│   └── index.ndx
│
└── ...
```

Each window has its own harmonic bias centered at the selected reaction-coordinate value.

## 7. Umbrella Sampling

The umbrella potential is defined in:

```text
mdp/umbrella_template.mdp
```

The central parameters are:

```text
pull-coord1-type = umbrella
pull-coord1-k = 1000
pull-coord1-rate = 0
pull-coord1-init = WINDOW_CENTER
```

`WINDOW_CENTER` is replaced with the target reaction-coordinate value for each window.

The force constant and window centers shown here are examples. They should be chosen based on the molecular system and desired sampling overlap.

## 8. Run Umbrella Simulations

For each window, generate the GROMACS run input file:

```bash
gmx grompp     -f umbrella.mdp     -c conf.gro     -p topol.top     -n index.ndx     -o umbrella.tpr
```

Run the simulation:

```bash
gmx mdrun     -deffnm umbrella     -pf umbrella_pullf.xvg     -px umbrella_pullx.xvg
```

The `pullf` and `pullx` files should have unique names for each window because they are required for subsequent WHAM analysis. citeturn2search0

For multiple windows:

```bash
cd scripts
bash run_umbrella.sh
```

## 9. Check Sampling and Window Overlap

Before WHAM analysis, inspect the reaction-coordinate distributions from neighboring windows.

Adequate overlap is important for reliable reconstruction of the PMF. If a region has insufficient sampling, additional umbrella windows may be required. citeturn2search0turn1search3

The histogram generated by WHAM can also be used to assess overlap.

## 10. Prepare WHAM Input

Create:

```text
analysis/tpr-files.dat
```

containing one `.tpr` file per window:

```text
../windows/window-001/umbrella.tpr
../windows/window-002/umbrella.tpr
../windows/window-003/umbrella.tpr
...
```

Create:

```text
analysis/pullf-files.dat
```

containing the corresponding force files in exactly the same order:

```text
../windows/window-001/umbrella_pullf.xvg
../windows/window-002/umbrella_pullf.xvg
../windows/window-003/umbrella_pullf.xvg
...
```

The tutorial specifically notes that the `.tpr` and pull-data lists must correspond and that the pull-data files need unique names. citeturn2search0

Example files are provided as:

```text
analysis/tpr-files.dat.example
analysis/pullf-files.dat.example
```

## 11. WHAM / PMF Calculation

Run WHAM from the `analysis/` directory:

```bash
cd analysis
bash run_wham.sh
```

The underlying GROMACS command is:

```bash
gmx wham     -it tpr-files.dat     -if pullf-files.dat     -o ../results/pmf.xvg     -hist ../results/histo.xvg     -unit kJ
```

GROMACS `gmx wham` combines the biased umbrella simulations to obtain the PMF. The MDTutorials example also uses `tpr-files.dat` and `pullf-files.dat` as the primary WHAM inputs. citeturn2search0

## 12. Free-Energy Profile

The resulting PMF is stored as:

```text
results/pmf.xvg
```

The histogram is stored as:

```text
results/histo.xvg
```

A simple Python plotting script is provided:

```bash
cd analysis
python plot_pmf.py
```

The resulting figure is:

```text
results/pmf.png
```

## Methods

- Molecular dynamics simulations
- Steered/pulling molecular dynamics
- Umbrella sampling
- Reaction-coordinate analysis
- Weighted Histogram Analysis Method (WHAM)
- Potential of Mean Force (PMF)
- Free-energy analysis
- Trajectory analysis

## Software

- GROMACS
- Python
- Bash/Linux
- NumPy
- Matplotlib
- VMD / PyMOL for visualization

## Reproducibility

The repository separates:

- System-specific inputs
- GROMACS parameter files
- Window-generation scripts
- Umbrella simulations
- WHAM analysis
- Final results

Simulation parameters should be documented together with the GROMACS version, force field, water model, reaction coordinate, window spacing, force constant, simulation length, and analysis settings.

## Data and Large Files

Raw trajectories and GROMACS binary/output files can become very large. Therefore, files such as:

```text
*.xtc
*.trr
*.tpr
*.edr
*.cpt
*.log
```

are excluded from the Git repository by `.gitignore`.

For large datasets or complete trajectories, use an appropriate data repository or Git LFS rather than committing large simulation outputs directly to the repository.

## Reference

This workflow was developed with reference to the umbrella-sampling methodology described in the GROMACS tutorial by Justin A. Lemkul:

- Justin A. Lemkul, *Umbrella Sampling*, GROMACS Tutorial.
- Lemkul, J. A. *From Proteins to Perturbed Hamiltonians: A Suite of Tutorials for the GROMACS-2018 Molecular Simulation Package*. Living J. Comput. Mol. Sci. 2018, 1, 5068.

See the original tutorial for the theoretical background and system-specific considerations.

## Author

**Amar Jeet Yadav**

PhD Researcher  
School of Biochemical Engineering  
Indian Institute of Technology (BHU), Varanasi, India
