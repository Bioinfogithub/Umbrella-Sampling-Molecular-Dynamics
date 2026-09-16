# Umbrella Sampling and Potential of Mean Force (PMF)

A reproducible molecular dynamics workflow for performing umbrella sampling simulations and calculating the potential of mean force (PMF) using GROMACS.

## Overview

Umbrella sampling is used to characterize the free-energy profile associated with a molecular process along a defined reaction coordinate.

This repository provides an example workflow covering system preparation, generation of umbrella windows, equilibration, production simulations, trajectory analysis, and PMF reconstruction.

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

## Methods

- Molecular Dynamics (MD)
- Umbrella Sampling
- Potential of Mean Force (PMF)
- GROMACS
- Trajectory analysis
- Free-Energy Analysis

## Software

- GROMACS
- Python
- Linux Bash scripting
- WHAM / GROMACS analysis tools

## Reproducibility

The workflow is organized as modular scripts so that individual simulation and analysis steps can be reproduced independently.

## Author

**Amar Jeet Yadav**  
PhD Researcher, IIT (BHU), Varanasi
