TCO and Sensitivity Analysis — Hydrogen Fuel Cell Heavy-Duty Trucks
MATLAB code accompanying the paper:

N. Espi, M. Tanco, M. de las N. Camacho, and D. Jurburg, "Break-Even Analysis for Hydrogen Fuel Cell Heavy-Duty Trucks: A Comparative Study of Europe and South America."

The script implements the 10-year Total Cost of Ownership (TCO) model comparing hydrogen fuel cell (HFCT), battery electric (BET) and diesel (ICET) Class 8 trucks across Uruguay, Chile, Spain and Germany, together with the local and global sensitivity analyses reported in Sections 4 and 5.

Contents:

File	Description
tco_sensitivity_analysis.m	Complete analysis: TCO model, local one-at-a-time sensitivity (Part 1) and variance-based Sobol decomposition (Part 2)

Requirements
MATLAB R2021a or later (uses boxchart, exportgraphics)
Statistics and Machine Learning Toolbox — for quasi-random Sobol sampling (sobolset). The script falls back to pseudo-random sampling via rand if the toolbox is unavailable; results remain valid but converge more slowly.

Outputs:
Part 1 — local sensitivity
Nine figures covering the discount-rate sweep (6–13%), HFCT maintenance at diesel parity, fuel-cell stack replacement in year 8, the flat acquisition- cost scenario, and two insurance scenarios
Monte Carlo cumulative distributions and per-km saving distributions against ICET and BET
tabla_maestra_sensibilidad.csv — break-even years under every scenario
Part 2 — global sensitivity
Three Sobol figures (total-order indices for the HFCT TCO, the ICET–HFCT margin and the BET–HFCT margin)
One convergence figure (nested sampling, 512 → 8,192)
tabla_sobol_indices.csv — first- and total-order indices with bootstrap standard errors
sobol_resultados.mat — full results for re-analysis without recomputation

Verification
The script prints the twelve 2026 baseline TCO values before sampling and compares them against a stored target array. A mismatch raises a warning rather than an error, so the analysis always runs to completion.

Licence
See LICENSE.

Citation
If you use this code, please cite the paper above.
