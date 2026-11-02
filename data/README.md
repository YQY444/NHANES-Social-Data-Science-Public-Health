# Data provenance and dictionary

## Original public-use data

The four XPT files in `raw/` are the original study inputs from CDC/NCHS NHANES August 2021–August 2023: DEMO_L (demographics and weights), BPXO_L (oscillometric blood pressure), BMX_L (body measurements) and BPQ_L (blood pressure questionnaire). They are linked by the unique participant identifier SEQN. Raw file checksums are recorded in `results/raw_hashes.csv`.

Documentation: [DEMO_L](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DEMO_L.htm), [BPXO_L](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/BPXO_L.htm), [BMX_L](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/BMX_L.htm), [BPQ_L](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/BPQ_L.htm).

Source citation: Centers for Disease Control and Prevention (CDC), National Center for Health Statistics (NCHS). National Health and Nutrition Examination Survey Data, August 2021–August 2023. Hyattsville, MD: U.S. Department of Health and Human Services, CDC.

The [official citation guidance](https://wwwn.cdc.gov/nchs/NHANES/NhanesCitation.aspx) states that federally produced data and materials are generally in the public domain and may be reproduced without permission. Third-party materials retain their original status. The project's MIT software license does not replace CDC/NCHS attribution or data-use guidance. These are public-use files, not restricted NHANES data.

## Analytical dataset

`processed/nhanes_complete_5019.csv` and the equivalent `.xpt` contain identical 5,019-record, 11-column complete datasets. Selection is documented in `results/sample_flow.csv`: 11,933 linked participants, 8,860 valid examinations, 6,064 adults, 5,857 with at least two valid SBP readings, 5,818 after excluding known pregnancy, 5,068 with PIR, 5,020 with BMI, and 5,019 complete for all model fields.

| Field | Meaning |
|---|---|
| SEQN | Participant identifier; linkage only |
| sbp | Mean of at least two valid systolic blood pressure readings, mmHg |
| pir | Family income-to-poverty ratio; 5 denotes 5 or above |
| age | Age in years; 80 denotes 80 or above |
| sex | 1 male, 2 female; treated as categorical |
| race | 1 Mexican American; 2 other Hispanic; 3 non-Hispanic White; 4 non-Hispanic Black; 6 non-Hispanic Asian; 7 other/multiracial |
| bmi | Published body mass index, kg/m² |
| education | 1 below ninth grade; 2 ninth–eleventh grade; 3 high school/GED; 4 some college/associate degree; 5 college graduate or above |
| weight_mec | Examination weight WTMEC2YR |
| stratum | Variance stratum SDMVSTRA |
| psu | Primary sampling unit SDMVPSU, nested within stratum |

Categorical numeric codes must be converted to factors, as in the supplied R script. Survey weights alone do not encode the full design: strata and PSUs are also required.
