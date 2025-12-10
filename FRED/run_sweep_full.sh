#!/usr/bin/env bash

# Stop the script if any command fails
set -e

# Location of your template .fred file
TEMPLATE="models/baseline/washtenaw_covid_template.fred"

# Where we'll store all the run outputs
OUTDIR="output_lhs_sweep"

# Make an output directory (if it doesn't already exist)
mkdir -p "$OUTDIR"

###############################
# 1. LHS Configuration
###############################
# Number of samples (each sample is a unique parameter combination)
NUM_SAMPLES=100

# Parameter ranges (min max)
# Latent period (days): 3.0 - 10.0 -> @E_MU@
# Asymptomatic transmissibility: 0.00 - 0.75 -> @ASYMP@
# Transmissibility (R0 multiplier): 0.50 - 1.50 -> @R0A@
# Hospitalization probability: 0.00 - 0.20 -> @HOSP_PROB@
# Hospitalization duration (days): 3 - 21 -> @HOSP_LEN@

E_MU_MIN=3.0
E_MU_MAX=10.0

ASYMP_MIN=0.00
ASYMP_MAX=0.75

R0A_MIN=0.50
R0A_MAX=1.50

HOSP_PROB_MIN=0.00
HOSP_PROB_MAX=0.20

HOSP_LEN_MIN=3.0
HOSP_LEN_MAX=21.0

SEED_BASE=3000

###############################
# 2. Generate LHS samples using Python
###############################
echo "Generating $NUM_SAMPLES Latin Hypercube samples..."

# Create a temporary Python script for LHS generation
python3 << EOF
import numpy as np
from scipy.stats import qmc

# Set seed for reproducibility of the LHS design
np.random.seed(42)

# Number of samples and dimensions
n_samples = $NUM_SAMPLES
n_dims = 5  # e_mu, asymp, r0a, hosp_prob, hosp_len

# Generate LHS samples in [0, 1]^d
sampler = qmc.LatinHypercube(d=n_dims)
samples = sampler.random(n=n_samples)

# Define bounds for each parameter
bounds = [
    ($E_MU_MIN, $E_MU_MAX),       # Latent period (e_mu)
    ($ASYMP_MIN, $ASYMP_MAX),     # Asymptomatic transmissibility
    ($R0A_MIN, $R0A_MAX),         # Transmissibility (R0 multiplier)
    ($HOSP_PROB_MIN, $HOSP_PROB_MAX),  # Hospitalization probability
    ($HOSP_LEN_MIN, $HOSP_LEN_MAX)     # Hospitalization duration
]

# Scale samples to actual parameter ranges
scaled_samples = np.zeros_like(samples)
for i, (low, high) in enumerate(bounds):
    scaled_samples[:, i] = samples[:, i] * (high - low) + low

# Save to file
np.savetxt('lhs_samples.csv', scaled_samples, delimiter=',', 
           header='e_mu,asymp,r0a,hosp_prob,hosp_len', comments='',
           fmt='%.6f')

print(f"Generated {n_samples} LHS samples")
EOF

###############################
# 3. Run simulations for each LHS sample
###############################
echo "Starting parameter sweep..."

# Read the CSV file and run simulations
SAMPLE_NUM=1
tail -n +2 lhs_samples.csv | while IFS=',' read -r e_mu asymp r0a hosp_prob hosp_len; do
    
    # Make a unique name for this run
    RUNID="LHS_${SAMPLE_NUM}"
    
    MY_SEED=$(( SEED_BASE + SAMPLE_NUM + $(date +%s) % 10000 ))
    
    echo "Running sample $SAMPLE_NUM/$NUM_SAMPLES: E_MU=$e_mu, ASYMP=$asymp, R0A=$r0a, HOSP_PROB=$hosp_prob, HOSP_LEN=$hosp_len"
    
    # Create a run-specific .fred file by replacing placeholders
    sed "s/@R0A@/${r0a}/g; \
         s/@E_MU@/${e_mu}/g; \
         s/@ASYMP@/${asymp}/g; \
         s/@HOSP_PROB@/${hosp_prob}/g; \
         s/@HOSP_LEN@/${hosp_len}/g; \
         s/@SEED@/${MY_SEED}/g" \
        "$TEMPLATE" > "models/baseline/washtenaw_covid_${RUNID}.fred"
    
    # Run FRED with the generated parameter file
    ./bin/FRED -p "models/baseline/washtenaw_covid_${RUNID}.fred"
    
    # Make a folder for this specific run's outputs
    mkdir -p "${OUTDIR}/${RUNID}"
    
    # Move the run outputs from OUT/ to the new folder
    mv OUT/RUN* "${OUTDIR}/${RUNID}/"
    
    # Save parameter values for this run
    echo "e_mu,asymp,r0a,hosp_prob,hosp_len,seed" > "${OUTDIR}/${RUNID}/parameters.csv"
    echo "${e_mu},${asymp},${r0a},${hosp_prob},${hosp_len},${MY_SEED}" >> "${OUTDIR}/${RUNID}/parameters.csv"
    
    # Remove the run-specific .fred file
    rm "models/baseline/washtenaw_covid_${RUNID}.fred"
    
    SAMPLE_NUM=$((SAMPLE_NUM + 1))
done

# Copy the full LHS design to output directory for reference
cp lhs_samples.csv "${OUTDIR}/lhs_design.csv"

# Clean up
rm lhs_samples.csv

echo "All $NUM_SAMPLES LHS parameter sweeps completed!"
echo "Results saved in: $OUTDIR"
