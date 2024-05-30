
## Libraries ---------------------------------------------------------------
library(tidycensus)
library(tigris)
library(sf)
library(janitor)
library(tidyverse)
library(here)
library(RColorBrewer)
library(readxl)



## cache census downloads --------------------------------------------------

options(tigris_use_cache = TRUE)
rappdirs::user_cache_dir("tigris")



## Create string import for years of interest ------------------------------

## File
pums_2000 <- "ipums_puma_2000.shp"
pums_2010 <- "ipums_puma_2010_tl20.shp"

## Path
pums_2000_path <- here("recs_pums_master", "climate_regions", "raw_data", "ipums_puma_2000", pums_2000)
pums_2010_path <- here("recs_pums_master", "climate_regions", "raw_data", "puma_2010_shapefiles", pums_2010)




## Import data -------------------------------------------------------------
clim_zones <- read_csv(here("recs_pums_master", "climate_regions", "raw_data", 
                            "climate_zones.csv")) %>% clean_names()

## Pick vintage depending on needs 
puma <- read_sf(pums_2010_path)

puma_crosswalk <- read_excel(here("recs_pums_master", "climate_regions", 
                                  "raw_data",  "PUMA2000_PUMA2010_crosswalk.xlsx"))



## Tidy census call - Make sure year lines up with imported pums shapefile
counties <- counties(year = 2010, cb = TRUE)



## Combine climate zones to match recs data --------------------------------


clim_zones <- clim_zones %>% mutate(climate_reg_recs = 
                                    case_when(
                                              ba_climate_zone %in% c("Cold", "Very Cold") ~
                                                                     "Cold & Very Cold",
                                              ba_climate_zone %in% c("Hot-Dry", "Mixed-Dry") ~
                                                                      "Hot-Dry & Mixed Dry",
                                              TRUE ~ ba_climate_zone)
)


# ## Split climate zone data into unique and overlap states ------------------
# 
# wide_counts_clim <- tabyl(clim_zones, state_fips, ba_climate_zone)
# long_counts_clim <- wide_counts_clim %>% pivot_longer(cols=c(2:9),
#                                                       names_to = "climate_zone",
#                                                       values_to = "counts") %>% filter(counts != 0)
# 
# ## 23 states have only one climate region.
# one_clim_reg_st <- long_counts_clim %>% group_by(state_fips) %>% summarise(n=n()) %>% filter(n == 1)
# unique_st <- unique(one_clim_reg_st$state_fips)
# 
# ## 34 straddle climate regions apparently?
# 
# overlap_pumas <- puma %>% filter(!STATEFIP %in% unique_st)
# overlap_st <- unique(overlap_pumas$STATEFIP)



## Let's calculate some intersections -------------------------------------

## SF object have different cartographic boundaries
st_crs(puma)
st_crs(counties)

## Transform county object to same crs as pumas object.
co_transformed <- st_transform(counties, crs = st_crs(puma))


## Calculate areas
overlap_areas <- st_intersection(puma, co_transformed) %>% 
                 mutate(area = as.numeric(st_area(.)))

## Filter overlapping data to observation with largest area associated w/ PUMA
puma_co_areas <- overlap_areas %>% 
                 group_by(STATEFIP, PUMA) %>% 
                 filter(area == max(area)) %>%
                 ungroup() %>% 
                 select(STATEFIP, COUNTYFP, PUMA, area) %>% 
                 dplyr::rename(state_fips = STATEFIP,
                               county_fips = COUNTYFP)

## Fill out puma shape-file w/ information needed to create area based climate regions

## Narrow climate zone data to merge keys and climate zone
clim_narrowed <- select(clim_zones, state_fips, 
                        county_fips, climate_reg_recs)


## Join puma / county area estimates w/ narrowed climate data
puma_clim_area <- puma_co_areas %>% left_join(clim_narrowed, 
                                              by=c("state_fips", "county_fips"))

puma_clim_area <- as.data.frame(puma_clim_area) %>% select(-geometry)


## Join puma climate area estimates w/ shape file ----> coerce back to shapefile
puma_sf <- puma %>%
           dplyr::rename(state_fips = STATEFIP) %>% 
           left_join(puma_clim_area, 
                     by=c("state_fips", "PUMA")) %>% 
  
           mutate(climate_reg_recs = 
                  case_when(
                             state_fips %in% c("09", "16", "19", "25",
                                               "30", "31", "33", "44",
                                               "46", "50") ~ "Cold & Very Cold",
                             state_fips %in% c("10", "11", "21", "47",
                                               "51") ~ "Mixed-Humid",
                             state_fips %in% c("12", "15", "60", "66", 
                                               "69", "72", "74", "78") ~ "Hot-Humid",
                  TRUE ~ climate_reg_recs)
  )






## Visuals non-contiguous US ------------------------------

counties <- counties %>% dplyr::rename(county_fips = COUNTYFP,
                                                 state_fips = STATEFP) 

clim_zone_sf <- counties %>%  
                left_join(clim_narrowed, 
                          by=c("state_fips", "county_fips"))

clim_zone_sf <- st_as_sf(clim_zone_sf)



## Original County Boundaries
non_contig_county <- shift_geometry(clim_zone_sf)
gg_county_clim <- ggplot(non_contig_county, aes(fill = climate_reg_recs)) +
  geom_sf() +
  theme_minimal()  +
  theme(plot.title = element_text(hjust = 0.5),
        plot.caption = element_text(hjust = 0)) +
  ggtitle("Climate Regions, Non-Contiguous United States, 2010 County Boundaries") +
  labs(caption = "1. Boundaries derived using DOE Methodological document") +
  scale_fill_brewer(palette = "Set2") +
  guides(fill=guide_legend(title = "Climate Region"))


## PUMA Boundaries
non_contig_puma <- shift_geometry(puma_sf)
gg_puma_clim <- ggplot(non_contig_puma, aes(fill = climate_reg_recs)) +
  geom_sf() +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5),
        plot.caption = element_text(hjust = 0)) +
  ggtitle("Climate Regions, Non-Contiguous United States, 2010 PUMA Boundaries") +
  labs(caption = "1. Boundaries derived using DOE Methodological document\n2. Climate Region assigned using largest county area in PUMA.") +
  scale_fill_brewer(palette = "Set2") +
  guides(fill=guide_legend(title = "Climate Region"))



## Export graphs -----------------------------------------------------------

# ggsave("climate_region_counties.pdf", plot = gg_county_clim, device = "pdf", 
#        path = here("recs_pums_master", "climate_regions"), width = 20, height = 20)
# 
# ggsave("climate_region_pumas.pdf", plot = gg_puma_clim, device = "pdf", 
#        path = here("recs_pums_master", "climate_regions"), width = 20, height = 20)




## Join county / climate data with pums crosswalk --------------------------

## File used to enrich pums data w/ climate region information. 

puma_clim_to_join <- as.data.frame(puma_sf) %>% select(state_fips, county_fips, PUMA, 
                                                       area, climate_reg_recs)

joined_clim_crosswalk <- puma_crosswalk %>% left_join(puma_clim_to_join, 
                                                      by = c("State10" = "state_fips",
                                                             "PUMA10" = "PUMA"))

# write_csv(joined_clim_crosswalk, here("recs_pums_master", 
#                                       "climate_regions", "output_data",  "PUMA_10_20_clim_crosswalk.csv"))
# 






