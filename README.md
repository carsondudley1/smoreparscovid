# SMoRe ParS for COVID-19: Region-Specific Policy Evaluation via Simulation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository contains code for the paper **"From Sparse Data to Smart Decisions: Region-Specific Policy Evaluation via Simulation"** by Dudley et al.

## Overview

We present a simulation-based framework that combines agent-based models (ABMs) with surrogate modeling to infer key transmission and severity parameters using only routine case and hospitalization data. This enables local health agencies to evaluate candidate interventions while explicitly accounting for uncertainty, without requiring bespoke data collection.

The method leverages **SMoRe ParS (Surrogate Modeling for Reconstructing Parameter Surfaces)**, which uses simplified differential equation models as calibrated intermediaries between observed data and complex simulations. By fitting the same ODE surrogate model to both real-world surveillance data and synthetic ABM outputs, we identify which ABM configurations produce dynamics consistent with observed case and hospitalization trajectories.

## Repository Structure
```
├── README.md
├── parameter_surface_reconstruction_example.py   # Main SMoRe ParS workflow
├── FRED/                                         # Agent-based model simulations
│   ├── run_sweep_full.sh                         # Run ABM parameter sweep
│   └── ...
└── data/                                         # Data directory (not included)
```

## Method

The SMoRe ParS workflow consists of five main steps:

1. **ABM Parameter Sweep**: Simulate the agent-based model across parameter combinations sampled via Latin Hypercube Sampling (LHS)
2. **Surrogate Fitting to ABM**: Fit an SIRH surrogate model to each ABM output, computing profile likelihood confidence intervals
3. **Parameter Surface Reconstruction**: Build interpolated surfaces mapping ABM parameters → surrogate parameters
4. **Surrogate Fitting to Data**: Fit the same SIRH model directly to observed surveillance data with profile likelihood CIs
5. **ABM Space Filtering**: Retain only ABM parameter combinations whose projected surrogate values fall within the data-derived confidence regions

The resulting data-consistent ABM parameter sets can then be used for uncertainty-aware intervention simulations.

## ABM Parameters

The framework infers the following ABM parameters from surveillance data:

| Parameter | Description | Sampling Range |
|-----------|-------------|----------------|
| Latent Period | Days from infection to infectiousness | 3.0 – 10.0 days |
| Transmissibility | Overall transmission rate | 0.50 – 1.50 |
| Asymptomatic Transmissibility | Relative infectiousness of asymptomatic cases | 0.00 – 0.75 |
| Hospitalization Probability | Probability of hospitalization given infection | 0.00 – 0.20 |
| Hospitalization Duration | Average length of hospital stay | 3 – 21 days |
| Case Reporting Rate | Fraction of cases captured by surveillance | 10% – 100% |
| Hospitalization Reporting Rate | Fraction of hospitalizations captured | 10% – 100% |

## Quick Start

### 1. Run the ABM Parameter Sweep

The FRED folder contains scripts for running the agent-based model simulations. To generate ABM outputs across the parameter space:
```bash
cd FRED
./run_sweep_full.sh
```

This script uses Latin Hypercube Sampling to generate parameter combinations and runs the FRED ABM for each combination with multiple stochastic replicates.

### 2. Reconstruct Parameter Surfaces

After running the ABM sweep, use the main analysis script to recover data-consistent ABM parameters:
```bash
python parameter_surface_reconstruction_example.py
```

**Note:** The example script requires:
- ABM sweep output data (generated in step 1)
- Surveillance data (case counts and hospitalizations)

You will likely need to modify the script based on:
- The structure and column names of your surveillance data
- File paths to your ABM output and data files
- Population size for your region of interest
- Time period alignment between ABM simulations and observed data
- Whatever surrogate model you choose to use (the script shows the simple SIRH model)


## Data Requirements

The framework requires two types of input data:

**Surveillance Data:**
- Daily incident case counts (or cumulative cases to be differenced)
- Daily hospitalization counts (prevalent or incident)

**ABM Output:**
- Time series of simulated cases and hospitalizations for each parameter combination
- Parameter values used for each simulation
- Replicate identifier for stochastic runs

## Outputs

The framework produces:

1. **Data-consistent ABM parameter sets**: Parameter combinations whose dynamics match observed surveillance data
2. **Parameter estimates with confidence intervals**: Profile likelihood CIs for both ABM-derived and data-derived surrogate parameters
3. **Parameter surfaces**: Interpolated mappings from ABM parameters to surrogate model parameters

These outputs support downstream analyses including intervention simulation, policy ranking, and robustness evaluation under uncertainty.

## Citation

If you use this code in research work, please cite:
```bibtex
@article{dudley2025sparse,
  title={From Sparse Data to Smart Decisions: Region-Specific Policy Evaluation via Simulation},
  author={Dudley, Carson and Bergman, Daniel and Jain, Harsh and Norton, Kerri-Ann and Rutter, Erica and Eisenberg, Marisa and Jackson, Trachette},
  journal={medRxiv},
  year={2025},
  doi={10.64898/2025.12.05.25341712},
  note={Preprint}
}
```

## Related Work

This implementation builds on the SMoRe ParS framework:

- Jain, H. et al. (2022). SMoRe ParS: Surrogate Modeling for Reconstructing Parameter Surfaces
- Bergman, D. et al. (2023). Connecting Agent-Based Models with High-Dimensional Parameter Spaces to Multidimensional Data Using SMoRe ParS: A Surrogate Modeling Approach

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions about the code or methodology, please open an issue or contact the authors.
