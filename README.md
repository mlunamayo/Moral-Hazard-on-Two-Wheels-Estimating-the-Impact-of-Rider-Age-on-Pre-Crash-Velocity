# Moral-Hazard-on-Two-Wheels-Estimating-the-Impact-of-Rider-Age-on-Pre-Crash-Velocity

Martin Luna  
ECON 4970 - Data Science for Economics  
April 2026  

---

##  Project Overview
This project explores the economic concept of **Moral Hazard** and **Risk Preference** within transportation economics. By analyzing federal crash data, this study investigates a central thesis: *Do younger motorcycle riders exhibit a higher tolerance for risk (measured by pre-crash travel speed) compared to older demographics?*

Understanding these behavioral trends provides actionable insights for:
* **Insurance Actuaries:** Pricing premiums based on empirical risk tiers and machine classes.
* **Public Policy & Safety:** Designing targeted interventions for high-risk age groups.
* **Urban Planning:** Identifying geospatial "High-Speed Zones" where fatal accidents are concentrated.

---

## The Dataset
This analysis utilizes the **2022 Fatality Analysis Reporting System (FARS)**, maintained by the National Highway Traffic Safety Administration (NHTSA). 

**Relational Architecture:**
* `accident.csv`: Geospatial data (Lat/Long) and environmental conditions.
* `vehicle.csv`: Machine-specific data, including engineered `BIKE_CATEGORY` features and Travel Speed (`TRAV_SP`).
* `person.csv`: Rider demographics (Age, Sex) and safety equipment metrics.

> **Note:** Due to GitHub's file size limits (>100MB), the raw FARS data is not hosted in this repository. The provided R script includes a module to process the local `FARS2022NationalCSV.zip` directly.

---

## Methodology 
Developed entirely in **R**, this project leverages the `tidyverse` ecosystem to execute a full data science pipeline:
1. **Relational Data Joining:** Merged three distinct tables using `ST_CASE` and `VEH_NO` as primary/foreign keys.
2. **Data Cleaning & Standardization:** Standardized headers globally using `toupper` and filtered out missing/unreported values (e.g., Age > 98, Speed = 999).
3. **Feature Engineering:** Categorized raw numerical `BODY_TYP` codes into distinct, human-readable motorcycle classes (Cruiser, Off-Road, Scooter, Autocycle).
4. **Geospatial Mapping:** Utilized `ggplot2` and `maps` to project GPS coordinates onto an Albers-projected map of the contiguous United States.
5. **Statistical Modeling:** Implemented **Linear Regression** and **Generalized Additive Models (GAM)** to test the correlation between rider Age and Speed.

##  Key Findings & Visualizations

### 1. Geospatial Distribution of Extreme Speeds
This map plots the exact GPS coordinates of fatal crashes in the contiguous US, color-coded by travel speed hotspots.

<img src="https://github.com/mclawson99/test/blob/main/APlogo.png" alt="Logo" width="200">

### 2. Density Analysis: Age vs. Speed
Standard scatterplots fail due to overplotting with 5,000+ data points. Using hexagonal binning, we isolate the highest density of crashes. The GAM trendline indicates a statistically significant downward slope: **younger riders consistently crash at higher speeds.**


### 3. Risk by Motorcycle Class
Violin plots reveal that different machines attract different risk profiles. Cruisers show a wide, normal distribution of crash speeds, whereas off-road bikes and sport classes have tighter, more aggressive speed profiles.

### 4. Demographic Shift in Extreme Speed Crashes
To isolate the most aggressive risk-taking behavior, the dataset was split into two tiers: "Normal Speed" (<80 MPH) and "Extreme Speed" (80+ MPH). While normal speed crashes show a wide age distribution, the extreme speed crashes violently shift to the left. This proves that extreme speed is almost exclusively a young rider's game, isolating the exact demographic where the "Need for Speed" overrides safety.


---

## ![Uploading Geospatial Distribution of Fatal Motorcycle Accidents (2022).svg…]()
Summary Statistics
The following table summarizes the demographic and speed differences across engineered motorcycle categories. 



*(Note: Data is a representative sample of N = 5,102 fatal incidents from the 2022 FARS database).*

---

## How to Run This Project
1. Clone this repository to your local machine.
2. Download the `FARS2022NationalCSV.zip` from the [NHTSA FARS FTP Website](https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars).
3. Place the ZIP file in the root directory of the cloned repository.
4. Open and run `motorcycle_analysis.R` in RStudio. The script will automatically prompt you to select the ZIP file, handle the extraction, and generate all visualizations and statistical summaries.
