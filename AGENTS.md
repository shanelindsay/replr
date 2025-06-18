Only AGENTS.md - don't search elsewhere.

## Essentials for reliable R package management with micromamba/conda and agents:

Always activate your target environment (e.g. myr) before running R or installing packages.

Install R packages using micromamba after activating the correct environment.

Each environment is isolated; packages in base are not visible to myr, and vice versa.

List all required R packages in your environment.yml so they’re installed every time the environment is rebuilt.

Never rely on interactive install.packages() or pak for reproducibility—use only as a fallback and always update environment.yml after. 

For installing from source, install compilers on micromamba
