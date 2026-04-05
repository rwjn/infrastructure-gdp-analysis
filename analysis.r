#### Load libraries #####

# Tidyverse - for '%>%' operator and ggplot2.
library(tidyverse)
# Read Excel.
library(readxl)
# Janitor - for clean_names().
library(janitor)
# Stargazer - for outputting tables.
library(stargazer)
# AER - for IVReg diagnostics
library(AER)

# Set working directory to current folder
setwd("/Users/robertnoble/Library/CloudStorage/OneDrive-UniversityofBristol/EWDS/dev_econ/coursework/data")

#### Load Data ####

# (1) Infrastructure Data

infrastructure_data <- read_xlsx("infrastructure_lpi_2018.xlsx", skip = 1)  %>% 
    clean_names  %>% 
    select(country, infrastructure_score) 

# (2) GDP Data

# Dependent Variable - Real GDP Per Capita
gdp_data <- read.csv("gdp_data.csv", check.names = FALSE, skip = 4)  %>% # Read GDP CSV, skip blank rows at the top.
    select("country" = "Country Name", # Rename for merging later
           "country_code" = "Country Code",
           "gdp" = "2018")  %>% # Keep GDP if in LPI data
    filter(gdp != "Invalid Number")  %>% 
    mutate(log_gdp = log(gdp)) # Log GDP for chart

# (3) Population Data
# For (i) Chart and (ii) Second Stage Control

population_size <- read.csv("population.csv", check.names = FALSE, skip = 4)  %>% 
    select("country_code" = "Country Code",
            "pop" = "2018")  

# (4) Control Variables
# (i) Years of education
education <- read.csv("average-years-of-schooling.csv")  %>% 
    clean_names()  %>% 
    filter(year == 2018)  %>% 
    select("country_code" = "code",
           "educ_level" = "mean_years_of_schooling")

# (ii) Rule of Law
law <- read.csv("rule-of-law-index.csv")  %>% 
    clean_names()  %>% 
    filter(year == 2018)  %>% 
    select("country_code" = "code",
           "law_quality" = "rule_of_law_vdem_owid")

# (iii) Life Expectancy
health <- read.csv("life-expectancy.csv")  %>% 
    clean_names()  %>% 
    filter(year == 2018)  %>% 
    select("country_code" = "code",
           "life_exp" = "period_life_expectancy_at_birth_sex_all_age_0")

# (5) Continent Data
# For (i) Chart and (ii) Second Stage Control
continents <- read.csv("continents.csv")  %>% 
    clean_names()  %>% 
    select("country_code" = "code",
    "continent")

# (6) Geographic Instruments 
# (i) Load coastline data
coastline_length <- read.csv("countries-by-coastline-2024.csv")  %>% 
    clean_names()  %>% 
    select(-c("country"))

# (ii) Load country size
country_area <- read.csv("country_area.csv", skip = 4)  %>%
    clean_names()  %>%
    select("country_code", "size" = "x2018")  %>% 
    filter(`size` != "Invalid Number")

# (iii) Terrain Ruggedness
# Not actually used
terrain_ruggedness <- read.csv("terrain-ruggedness-index.csv")  %>% # Load CSV
    clean_names()  %>% # Change column names to lower case and remove spaces
    select("country_code" = "code",
           "ruggedness" = "terrain_ruggedness_index_100m_nunn_and_puga_2012")

# (iv) Rainfall - for desert and rainforest
rainfall_data <- read.csv("world_bank_rainfall.csv", check.names = FALSE, skip = 4)  %>% 
    select("country_code" = "Country Code", 
           "rainfall" = "2018")  %>%
    filter(!is.na(rainfall))  %>% 
    mutate(desert_dummy = if_else(rainfall <= 250, 1, 0),
           rainforest_dummy = if_else(rainfall >= 2000, 1, 0))   %>% 
    select(country_code, rainfall, desert_dummy, rainforest_dummy)

# (6) Join all datasets together

joined_df <- infrastructure_data  %>% 
    merge(gdp_data, by = "country")  %>% 
    select("country",
           "country_code",
           "infrastructure_score",
           "gdp",
           "log_gdp")  %>% 
    merge(continents, by = "country_code")  %>% 
    merge(population_size, by = "country_code")  %>% 
    mutate(pop_m = pop / 1000000)  %>% 
    merge(coastline_length, by = "country_code")  %>% 
    mutate(coastline_dummy = if_else(coastline == 0, coastline, 1))  %>% 
    rename("island_dummy"  = "island")  %>% 
    merge(country_area, by = "country_code")  %>% 
    # merge(terrain_ruggedness, by = "country_code")  %>% 
    mutate(coastline_ratio = coastline / size)  %>% 
    merge(rainfall_data, by = "country_code")  %>% 
    mutate(population_density = pop / size)  %>% 
    mutate(desert_landlocked = desert_dummy * (1 - coastline_dummy))   %>% 
    merge(education, by = "country_code")  %>% 
    merge(law, by = "country_code")  %>% 
    merge(health, by = "country_code")  %>% 
    mutate(africa_dummy = if_else(continent == "Africa", 1, 0),
           asia_dummy = if_else(continent == "Asia", 1, 0),
           other_continent_dummy = if_else(asia_dummy + africa_dummy == 0, 1, 0))

#### Regressions ####

#### Data Visulations ####

# (1) Figure 1

ggplot(joined_df, aes(x = infrastructure_score, y = log_gdp)) +  # Remove shape from here
  geom_point(aes(size = pop, shape = continent), alpha = 0.8) +  # Move shape into geom_point aes
  geom_smooth(method = "lm", se = FALSE, color = "black", show.legend = FALSE) +  # Add a regression line
  geom_text(aes(label = country_code, size = pop), vjust = -0.5, hjust = 0.5, show.legend = FALSE) +  # Scale text size by population
  scale_shape_manual(values = c(16, 17, 18, 19, 15, 6)) +  # Use manual shapes, ensuring they are valid
  scale_size(name = "Population (millions)") +  # Size scale with proper name
  labs(
    x = "Infrastructure Score",
    y = "Log GDP Per Capita (PPP)",
    # title = "FInfrastructure Score vs. Log GDP Per Capita (2018)"
  )

# Initial regression results
lm_initial <- lm(log_gdp ~ infrastructure_score, data = joined_df)
summary(lm_initial)

# Now add extra controls
lm_controls <- lm(log_gdp ~ infrastructure_score + educ_level + law_quality + life_exp, data = joined_df)
summary(lm_controls)

# Perform the regression
first_stage_model <- lm(infrastructure_score ~ coastline + rainforest_dummy + coastline_dummy, data = joined_df)
summary(first_stage_model)

# Extract fitted values from the first stage
infra_instrument <- fitted(first_stage_model)

# Perform the second stage regression
second_stage_model <- lm(log_gdp ~ infra_instrument + africa_dummy + asia_dummy, data = joined_df)
summary(second_stage_model)

# Perform the IV regression using ivreg
iv_model <- ivreg(log_gdp ~ infrastructure_score + africa_dummy + asia_dummy | africa_dummy + asia_dummy + coastline + rainforest_dummy + coastline_dummy, data = joined_df)

# Perform the overidentification test
iv_model
summary(iv_model, diagnostics = TRUE)

stargazer(lm_initial, lm_controls, first_stage_model, second_stage_model,
          type = "html", 
          out = "models_comparison_full.html",
          add.lines = list(c("Model Type", "OLS", "OLS", "IV", "2SLS"),
                           c("Wu-Hausman P-Value", "", "", "", "0.2069"),
                           c("Overid. P-Value", "", "", "", "0.0508")))

# summary_lm <- summary(lm_model)
# # Create a table of coefficients
# coefficients_table <- as.data.frame(summary_lm$coefficients)
# colnames(coefficients_table) <- c("Estimate", "Std. Error", "t value", "Pr(>|t|)")

# # Print the coefficients table
# print(coefficients_table)

# r_squared <- summary_lm$r.squared

# # Print the R-squared value
# print(paste("R-squared:", r_squared))
# # Explains 10% of variation

# # Perform the F-test for the joint significance of ruggedness and rainfall
# linearHypothesis(lm_model, c("coastline = 0", "rainforest_dummy = 0", "coastline_dummy = 0"))

# Removed code


# Load rainfall data; proxy for desert cover and rainforest incidence

# rainfall_data <- read.csv("world_bank_rainfall.csv", skip = 4)  %>% 
#     clean_names()  %>%
#     select("country_name", "country_code", "x2018")  %>%
#     rename("country" = "country_name", "rainfall" = "x2018")  %>% 
#     filter(`rainfall` != "NA")  %>% 
#     mutate(desert_dummy = if_else(rainfall <= 250, 1, 0))

# Loading all years of infrastructure data
# We need to decide if we want this




#### Colour chart ####

# ggplot(infra_gdp, aes(x = infrastructure_score, y = lngdp07, color = continent)) + # Removed size from global aes
#   geom_point(aes(size = pop_07)) +  # Added size inside geom_point
#   geom_smooth(method = "lm", se = FALSE, color = "black", show.legend = FALSE) +  # Add a regression line
#   geom_text(aes(label = country_code, size = pop_07), vjust = -0.5, hjust = 0.5, show.legend = FALSE) +  # Add country code labels and hide from legend
#   scale_color_discrete(name = "Continent") +  
#   scale_size(name = "Population (millions)") +  
#   labs(
#     x = "Infrastructure Score",
#     y = "Log GDP Per Capita (PPP)",
#     title = "Figure 1: Infrastructure Score and Log GDP Per Capita (2007)"
#   )


# Load OECD countries (to be excluded)
oecd <- read.csv("oecd.csv")  %>% 
    clean_names()  %>% 
    select("country_code" = "code")  %>% 
    mutate(oecd = 1)



# Independent Variable - Infrastructure Score 
infrastructure_data_07 <- read_excel("infrastructure_lpi_2007.xlsx", skip = 1)  %>%
    clean_names()
