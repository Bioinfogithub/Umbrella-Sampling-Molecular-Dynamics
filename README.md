# Umbrella Sampling and Molecular Dynamics

A GROMACS-based computational workflow for molecular dynamics simulations, umbrella sampling, potential of mean force (PMF) calculation, and free-energy analysis.

## Overview

This repository contains a workflow for performing umbrella sampling molecular dynamics simulations to characterize the free-energy landscape along a predefined reaction coordinate.

The workflow includes system preparation, energy minimization, equilibration, reaction-coordinate definition, generation and equilibration of umbrella windows, production simulations, trajectory analysis, and PMF calculation using WHAM.

## Workflow

```text
System preparation
        ↓
Energy minimization
        ↓
Equilibration
        ↓
Definition of reaction coordinate
        ↓
Generation of umbrella windows
        ↓
Window equilibration
        ↓
Production simulations
        ↓
Trajectory analysis
        ↓
WHAM / PMF calculation
        ↓
Free-energy profile
```

## 1. System Preparation

The molecular system is prepared for molecular dynamics simulations using standard GROMACS procedures.

### Protein topology generation

```bash
gmx pdb2gmx \
    -f protein.pdb \
    -o processed.gro \
    -p topol.top \
    -ff <force_field>
```

### Define the simulation box

```bash
gmx editconf \
    -f processed.gro \
    -o boxed.gro \
    -c \
    -d 1.0 \
    -bt cubic
```

### Solvate the system

```bash
gmx solvate \
    -cp boxed.gro \
    -cs spc216.gro \
    -o solvated.gro \
    -p topol.top
```

### Add ions

First generate the input file for ion addition:

```bash
gmx grompp \
    -f ions.mdp \
    -c solvated.gro \
    -p topol.top \
    -o ions.tpr
```

Then add ions to neutralize the system:

```bash
gmx genion \
    -s ions.tpr \
    -o solvated_ions.gro \
    -p topol.top \
    -pname NA \
    -nname CL \
    -neutral
```

> **Note:** The force field, water model, ion names, and simulation parameters should be adjusted according to the system being studied.

## 2. Energy Minimization

Energy minimization is performed to remove unfavorable steric contacts and obtain a physically reasonable starting configuration.

```bash
gmx grompp \
    -f minim.mdp \
    -c solvated_ions.gro \
    -p topol.top \
    -o em.tpr
```

Run energy minimization:

```bash
gmx mdrun \
    -deffnm em
```

The minimized structure can then be inspected using the potential energy and maximum force.

```bash
gmx energy \
    -f em.edr \
    -o potential.xvg
```

## 3. Equilibration

The system is gradually equilibrated before umbrella sampling.

### NVT equilibration

```bash
gmx grompp \
    -f nvt.mdp \
    -c em.gro \
    -r em.gro \
    -p topol.top \
    -o nvt.tpr
```

```bash
gmx mdrun \
    -deffnm nvt
```

### NPT equilibration

```bash
gmx grompp \
    -f npt.mdp \
    -c nvt.gro \
    -r nvt.gro \
    -p topol.top \
    -o npt.tpr
```

```bash
gmx mdrun \
    -deffnm npt
```

The temperature, pressure, density, and other relevant properties are monitored during equilibration.

## 4. Definition of the Reaction Coordinate

A suitable reaction coordinate is selected to describe the molecular process of interest.

Depending on the system, the reaction coordinate may represent:

- Distance between molecular groups
- Center-of-mass distance
- Protein–ligand separation
- Intermolecular distance
- Dihedral angle
- Another physically meaningful collective variable

For distance-based umbrella sampling, the reaction coordinate can be defined using GROMACS pull groups.

Example:

```text
pull                    = yes
pull-ngroups            = 2
pull-ncoords            = 1
pull-coord1-type        = umbrella
pull-coord1-geometry    = distance
pull-coord1-groups      = 1 2
pull-coord1-k           = 1000
```

The exact parameters should be modified according to the molecular system and selected reaction coordinate.

## 5. Generation of Umbrella Windows

A series of configurations is generated along the reaction coordinate.

Each configuration represents an umbrella window centered at a specific value of the reaction coordinate.

For example:

```text
Window 01 → 0.20 nm
Window 02 → 0.25 nm
Window 03 → 0.30 nm
Window 04 → 0.35 nm
Window 05 → 0.40 nm
...
Window N  → final reaction-coordinate value
```

The windows should provide sufficient overlap between neighboring distributions to allow reliable reconstruction of the free-energy profile.

## 6. Window Equilibration

Each umbrella window is independently equilibrated while applying a harmonic bias potential around its target reaction-coordinate value.

Example:

```bash
gmx grompp \
    -f umbrella_equilibration.mdp \
    -c window01.gro \
    -r window01.gro \
    -p topol.top \
    -o window01_equil.tpr
```

Run the equilibration:

```bash
gmx mdrun \
    -deffnm window01_equil
```

The same procedure is repeated for all umbrella windows.

## 7. Production Umbrella Sampling

After equilibration, production simulations are performed for each umbrella window.

Example:

```bash
gmx grompp \
    -f umbrella_production.mdp \
    -c window01_equil.gro \
    -r window01_equil.gro \
    -p topol.top \
    -o window01.tpr
```

```bash
gmx mdrun \
    -deffnm window01
```

This procedure is repeated for all windows.

The resulting trajectories and pull-force data are used for subsequent PMF analysis.

## 8. Trajectory Analysis

The umbrella trajectories are analyzed to assess structural stability and sampling quality.

Typical analyses include:

### Root-mean-square deviation (RMSD)

```bash
gmx rms \
    -s window01.tpr \
    -f window01.xtc \
    -o rmsd.xvg
```

### Radius of gyration

```bash
gmx gyrate \
    -s window01.tpr \
    -f window01.xtc \
    -o gyration.xvg
```

### Reaction-coordinate distribution

The pull-coordinate trajectory can be extracted for each window:

```bash
gmx distance \
    -s window01.tpr \
    -f window01.xtc \
    -o distance.xvg
```

The distributions from neighboring windows should show sufficient overlap before calculating the PMF.

## 9. WHAM / PMF Calculation

The Weighted Histogram Analysis Method (WHAM) is used to combine the biased umbrella-sampling simulations and reconstruct the unbiased potential of mean force.

First, prepare the list of umbrella simulation input files and pull-force files.

Example:

```text
tpr-files.dat
window01.tpr
window02.tpr
window03.tpr
...
windowN.tpr
```

```text
pullf-files.dat
window01_pullf.xvg
window02_pullf.xvg
window03_pullf.xvg
...
windowN_pullf.xvg
```

The PMF can then be calculated using:

```bash
gmx wham \
    -it tpr-files.dat \
    -if pullf-files.dat \
    -o pmf.xvg \
    -hist histo.xvg \
    -b 0
```

The resulting `pmf.xvg` file contains the reconstructed free-energy profile along the reaction coordinate.

## 10. Free-Energy Profile

The calculated PMF is analyzed to identify:

- Free-energy minima
- Free-energy barriers
- Stable and metastable states
- Transition regions
- Relative free-energy differences

The final profile can be plotted using Python, Origin, XMGrace, or another scientific visualization package.

Example Python workflow:

```python
import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("pmf.xvg", comments=["@", "#"])

reaction_coordinate = data[:, 0]
free_energy = data[:, 1]

plt.plot(reaction_coordinate, free_energy)
plt.xlabel("Reaction coordinate")
plt.ylabel("Free energy (kJ/mol)")
plt.tight_layout()
plt.show()
```

## Methods

The workflow incorporates the following computational methods:

- All-atom molecular dynamics (AAMD)
- Umbrella sampling
- Weighted Histogram Analysis Method (WHAM)
- Potential of Mean Force (PMF)
- Free-energy analysis
- Trajectory analysis
- Structural analysis

## Software

- **GROMACS** — molecular dynamics simulations and trajectory analysis
- **Python** — data processing and visualization
- **WHAM** — free-energy reconstruction
- **Linux/Bash** — workflow automation and scripting
- **VMD / PyMOL** — molecular visualization and structural inspection

## Repository Structure

A recommended organization for the repository is:

```text
Umbrella-Sampling-Molecular-Dynamics/
│
├── README.md
│
├── input/
│   ├── structure/
│   ├── topology/
│   └── index/
│
├── mdp/
│   ├── minim.mdp
│   ├── nvt.mdp
│   ├── npt.mdp
│   ├── umbrella_equilibration.mdp
│   └── umbrella_production.mdp
│
├── scripts/
│   ├── prepare_system.sh
│   ├── generate_windows.sh
│   ├── run_windows.sh
│   └── analyze_pmf.py
│
├── windows/
│   ├── window01/
│   ├── window02/
│   ├── window03/
│   └── ...
│
├── analysis/
│   ├── rmsd/
│   ├── rg/
│   ├── distributions/
│   └── pmf/
│
└── results/
    └── pmf.xvg
```

## Reproducibility

The workflow is organized into modular simulation and analysis steps so that individual stages can be reproduced independently.

Simulation parameters, input structures, topology files, analysis scripts, and processing commands should be maintained alongside the corresponding simulation workflow.

For reproducible analyses, the GROMACS version, force field, water model, simulation parameters, and analysis settings should be documented.

## Requirements

Before running the workflow, install:

- GROMACS
- Python 3
- NumPy
- Matplotlib
- Linux or a Linux-compatible environment

Python dependencies can be installed using:

```bash
pip install numpy matplotlib
```

## Usage

Clone the repository:

```bash
git clone https://github.com/Bioinfogithub/Umbrella-Sampling-Molecular-Dynamics.git
```

Move into the repository:

```bash
cd Umbrella-Sampling-Molecular-Dynamics
```

Prepare the system, perform equilibration, generate umbrella windows, run the production simulations, and calculate the PMF following the workflow described above.

## Important Considerations

Umbrella sampling results depend strongly on the choice of reaction coordinate, force constant, spacing between windows, simulation length, and degree of overlap between neighboring windows.

Before interpreting the PMF, the umbrella windows should therefore be checked for adequate sampling and overlap.

## Author

**Amar Jeet Yadav**

PhD Researcher  
School of Biochemical Engineering  
Indian Institute of Technology (BHU), Varanasi, India

## License

This repository is intended for research and academic use. A suitable open-source license can be added if the workflow and associated scripts are released for reuse.
