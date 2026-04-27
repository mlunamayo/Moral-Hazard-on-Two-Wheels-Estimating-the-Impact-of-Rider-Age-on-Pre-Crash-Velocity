# ==============================================================================
# DATA SCIENCE FINAL PROJECT: Motorcycle Fatality Demographics & Geospatial Analysis
# Dataset: NHTSA FARS 2022
# ==============================================================================

# 1. LOAD REQUIRED LIBRARIES
# ------------------------------------------------------------------------------

install.packages("tidyverse")
install.packages("maps")
install.packages("mapproj")
install.packages("viridis")

library(tidyverse)
library(maps)
library(mapproj)
library(viridis)

# 2. IMPORT DATA
# ------------------------------------------------------------------------------
vehicles  = read_csv("FARS2022NationalCSV/vehicle.csv", show_col_types = FALSE)
people    = read_csv("FARS2022NationalCSV/person.csv", show_col_types = FALSE)
accidents = read_csv("FARS2022NationalCSV/accident.csv", show_col_types = FALSE)

# Standardize column names
vehicles  = vehicles  |> rename_all(toupper)
people    = people    |> rename_all(toupper)
accidents = accidents |> rename_all(toupper)

# 3. FILTERING 
# ------------------------------------------------------------------------------
motorcycles <- vehicles |>
  # Filter strictly for Motorcycle body types (80-89)
  filter(BODY_TYP >= 80 & BODY_TYP <= 89) %>%
  # Creating a variable for the type of bike
  mutate(BIKE_CATEGORY = case_when(
    BODY_TYP == 80 ~ "Standard/Cruiser (Two-Wheel)",
    BODY_TYP == 82 | BODY_TYP == 85 | BODY_TYP == 87 ~ "Three-Wheel / Autocycle",
    BODY_TYP == 83 ~ "Off-Road / Dirt Bike",
    BODY_TYP == 84 ~ "Motor Scooter",
    TRUE ~ "Other/Unknown"
  )) |>
  select(ST_CASE, VEH_NO, BODY_TYP, BIKE_CATEGORY, SPEED = TRAV_SP)

# Join the tables using Primary Keys (ST_CASE) and Foreign Keys (VEH_NO)
ds_master_data = motorcycles |>
  inner_join(people, by = c("ST_CASE", "VEH_NO")) |>
  inner_join(accidents, by = "ST_CASE")

# 4. DATA CLEANING & OUTLIER REMOVAL
# ------------------------------------------------------------------------------
# NHTSA Data Dictionary specific codes:
# AGE: 998, 999 are unknown
# SPEED: 998 is Not Reported, 999 is Unknown. 0 is stopped.
# LAT/LONG: 77, 88, 99 prefixes often mean unknown/unreported.
ds_clean <- ds_master_data %>%
  filter(
    AGE < 98,                      # This remove unknown ages
    SPEED > 0 & SPEED < 150,       # This removes stopped vehicles and unknown speeds (998/999)
    LATITUDE > 24 & LATITUDE < 50, # This restricts to Borders inside US latitudes
    LONGITUD > -125 & LONGITUD < -66 # This restricts to borders inside US longitudes
  ) |>
  # Create Age Tiers for categorical visualizations
  mutate(AGE_TIER = cut(AGE, 
                        breaks = c(0, 25, 40, 55, 100), 
                        labels = c("16-25 (Young)", "26-40 (Adult)", "41-55 (Middle)", "56+ (Senior)")))

print(paste("Total Clean Observations for Data Science Modeling:", nrow(ds_clean)))


# ==============================================================================
# VISUALIZATION 1: Geospatial Density Map of the Contiguous US
# ==============================================================================
# Load US state coordinates
us_states <- map_data("state")

# Build the map
US_map <- ggplot() +
  # Draw the base US Map
  geom_polygon(data = us_states, aes(x = long, y = lat, group = group),
               fill = "gray15", color = "gray40", size = 0.2) +
  # Overlay the exact GPS coordinates of the fatal crashes
  geom_point(data = ds_clean, aes(x = LONGITUD, y = LATITUDE, color = SPEED),
             alpha = 0.6, size = 1.2) +
  scale_color_viridis(option = "inferno", name = "Crash Speed (MPH)") +
  coord_map("albers", lat0 = 39, lat1 = 45) +
  labs(title = "Geospatial Distribution of Fatal Motorcycle Accidents (2022)",
       subtitle = "Contiguous United States - Color mapped to Travel Speed",
       caption = "Data Source: NHTSA FARS") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5),
        legend.position = "bottom")

print(US_map)

ggsave("Geospatial Distribution of Fatal Motorcycle Accidents (2022).svg")
# ==============================================================================
# VISUALIZATION 2: Age vs. Speed Hexbin Plot 
# ==============================================================================
viz_hex <- ggplot(ds_clean, aes(x = AGE, y = SPEED)) +
  geom_hex(bins = 40) +
  scale_fill_viridis(option = "mako", name = "Density") +
  geom_smooth(method = "gam", color = "darkorange", size = 1.5, linetype = "dashed") +
  labs(title = "Density Analysis: Rider Age vs. Pre-Crash Speed",
       subtitle = "Dashed line represents a Generalized Additive Model (GAM) trend",
       x = "Rider Age (Years)",
       y = "Travel Speed (MPH)") +
  theme_minimal()

print(viz_hex)

ggsave("Density Analysis: Rider Age vs. Pre-Crash Speed.svg")
# ==============================================================================
# VISUALIZATION 3: Violin Plot of Speed by Motorcycle Category
# ==============================================================================
viz_violin <- ggplot(ds_clean %>% filter(BIKE_CATEGORY != "Other/Unknown"), 
                     aes(x = BIKE_CATEGORY, y = SPEED, fill = BIKE_CATEGORY)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.1, fill = "white", color = "black") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Speed Distribution by Motorcycle Category",
       subtitle = "White boxes represent the Interquartile Range (IQR)",
       x = "Motorcycle Class",
       y = "Crash Speed (MPH)") +
  theme_minimal() +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 15, hjust = 1))

print(viz_violin)

ggsave("Speed Distribution by Motorcycle Category.svg")
# ==============================================================================
# VISUALIZATION 4: Faceted Age Histogram by Speed Tiers
# ==============================================================================
# Speed separated between "Normal" and "Extreme" to see demographic differences
speeddifference_hist <- ds_clean |>
  mutate(SPEED_TIER = ifelse(SPEED >= 80, "Extreme Speed (80+ MPH)", "Normal Speed (< 80 MPH)")) %>%
  ggplot(aes(x = AGE, fill = SPEED_TIER)) +
  geom_histogram(binwidth = 2, color = "black", alpha = 0.8) +
  facet_wrap(~SPEED_TIER, scales = "free_y") +
  scale_fill_manual(values = c("Extreme Speed (80+ MPH)" = "darkred", "Normal Speed (< 80 MPH)" = "steelblue")) +
  labs(title = "Demographic Shift in Extreme Speed Crashes",
       subtitle = "Notice how the age distribution shifts left (younger) for Extreme Speeds",
       x = "Rider Age",
       y = "Frequency of Fatalities") +
  theme_bw() +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = 12))

print(speeddifference_hist)

ggsave("Demographic_Shift_in_Extreme_Speed_Crashes.svg")

# ==============================================================================
# DESCRIPTIVE STATISTICS: Summary Table by Motorcycle Category
# ==============================================================================

# 1. Generate the Summary Table using group_by and summarize_at
summary_table <- ds_clean |>
  # Group by the motorcycle class we engineered earlier
  group_by(BIKE_CATEGORY) |>
  # Select the continuous variables we want to summarize
  summarize_at(
    vars(AGE, SPEED), 
    # Provide the list of mathematical functions
    list(
      Mean   = ~mean(., na.rm = TRUE),
      Median = ~median(., na.rm = TRUE),
      SD     = ~sd(., na.rm = TRUE),
      Min    = ~min(., na.rm = TRUE),
      Max    = ~max(., na.rm = TRUE)
    )
  )

# Export the summary table to a CSV file
write.csv(summary_table, "motorcycle_summary_statistics.csv", row.names = FALSE)

