# NHANES Social Data Science and Public Health

Reproducible R code examining income, education and systolic blood pressure in NHANES August 2021–August 2023. The analysis links four components, constructs a common complete-record adult sample, and compares demographic, BMI and education adjustment using survey-weighted linear regression.

## Run the analysis

Install `haven` and `survey` in R. Obtain the public NHANES components `DEMO_L.xpt`, `BPXO_L.xpt`, `BMX_L.xpt` and `BPQ_L.xpt` from the [CDC data documentation](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DEMO_L.htm). Place these four original files in `data/raw/` below the repository root. Data files and manuscripts are not bundled in this code-only release.

With the repository root as the R working directory, run:

```r
source("R/run_analysis.R", encoding = "UTF-8")
```

The pipeline performs participant-level linkage, measurement checks, complete-record selection, weighted descriptive statistics, three sequential linear models, residual and collinearity diagnostics, age-form comparisons, 45 leave-one-stratum refits, and seven English figures. Model uncertainty incorporates examination weights, strata and primary sampling units. The scripts create `data/final/`, `data/interim/`, `results/` and `figures/` locally. These generated files are ignored by Git.

`R/run_analysis.R` reconstructs the analysis from public XPT inputs; `R/render_figures.R` renders the framework, filtering flow and scientific figures from the generated results. The pipeline was tested locally against the study's saved model estimates before this release. It does not require the author's archived workspace.

## Research and authorship

Author: Qiyong Yang. This project applies statistical inference to social determinants of health. The research manuscript is in preparation. AI assistance was used in code preparation and figure production; the author remains responsible for reviewing the analysis. A reuse license has not yet been selected.
