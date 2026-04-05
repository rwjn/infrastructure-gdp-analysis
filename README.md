# Infrastructure Quality and GDP Growth

This project was completed as part of coursework for the Economics with Data Science MSc. The project received a distinction.

### [Read the essay (PDF)](Noble%202024%20-%20Infrastructure%20and%20GDP%20Growth.pdf)

---

The paper investigates how infrastructure quality affects GDP per capita across 142 countries in 2018. It addresses endogeneity through OLS with controls and a two-stage least squares (2SLS) approach using geographic instrumental variables.

## Methodology

**OLS (Baseline)** — regresses log GDP per capita on the World Bank Logistics Performance Index (LPI) infrastructure score, first in a simple specification and then controlling for education (mean years of schooling), rule of law, and life expectancy.

**Instrumental Variables (2SLS)** — uses three geographic instruments to predict infrastructure score in the first stage, then regresses log GDP on fitted values:
- Coastline length (km) — proxy for trade access
- Rainforest dummy (rainfall ≥ 2,000mm/yr) — captures construction difficulty
- Coastline dummy — access to global markets

Africa and Asia continent dummies are included in the second stage to control for continent-level confounders. Instrument validity is assessed via the Sargan overidentification test (p = 0.0508).

## Key Findings

| Model | Infrastructure Coefficient | R² |
|-------|--------------------------|-----|
| OLS — simple | 1.344\*\*\* | 0.589 |
| OLS — with controls | 0.329\*\*\* | 0.861 |
| 2SLS | 1.116\*\*\* | 0.532 |

- A one-unit increase in infrastructure score is associated with a **134% increase in GDP per capita** (simple OLS), falling to **33%** after controlling for education, health, and rule of law
- The 2SLS estimate implies a **112% increase**, though the exclusion restriction cannot be fully assumed
- All infrastructure coefficients are significant at the 1% level across specifications
- The Wu-Hausman test (p = 0.207) suggests infrastructure may in fact be exogenous

## Repository Contents

```
├── Noble 2024 - Infrastructure and GDP Growth.pdf   # Essay
├── essay.tex                                        # LaTeX source
├── analysis.r                                       # Full R analysis
├── Rplotshapes.png                                  # Figure 1: scatter plot
├── data/                                            # All source datasets
│   ├── infrastructure_lpi_2018.xlsx                 # World Bank LPI
│   ├── gdp_data.csv                                 # World Bank GDP
│   ├── average-years-of-schooling.csv               # UNDP education data
│   ├── rule-of-law-index.csv                        # V-Dem rule of law
│   ├── life-expectancy.csv                          # UN life expectancy
│   ├── countries-by-coastline-2024.csv              # CIA World Factbook
│   ├── world_bank_rainfall.csv                      # World Bank rainfall
│   └── ...                                          # Additional geographic data
```

## Dependencies

R libraries: `tidyverse`, `readxl`, `janitor`, `stargazer`, `AER`
