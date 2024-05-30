library(tidycensus)
library(tigris)
library(sf)
library(janitor)
library(tidyverse)
library(here)
library(RColorBrewer)
library(readxl)

## Need to get check w/ Steve re: area calculations
## Need to come up with best paradigm to merge back with pums and categorize... 

## cache census downloads --------------------------------------------------

options(tigris_use_cache = TRUE)
rappdirs::user_cache_dir("tigris")


## Import data -------------------------------------------------------------
clim_zones <- read_csv(here("recs_pums_master", "climate_regions", "raw_data", 
                            "climate_zones.csv")) %>%  
              clean_names()

puma_2010 <- read_sf(here("recs_pums_master", "climate_regions", "raw_data", 
                          "puma_2010_shapefiles","ipums_puma_2010_tl20.shp"))

puma_crosswalk <- read_excel(here("recs_pums_master", "climate_regions", 
                                  "raw_data",  "PUMA2000_PUMA2010_crosswalk.xlsx"))



## Tidy census call 
counties_2010 <- counties(year = 2010, cb = TRUE)



## Combine climate zones to match recs data --------------------------------


clim_zones <- clim_zones %>% mutate(climate_reg_recs = 
                                    case_when(
                                               ba_climate_zone %in% c("Cold", "Very Cold") ~
                                                                      "Cold & Very Cold",
                                               ba_climate_zone %in% c("Hot-Dry", "Mixed-Dry") ~
                                                                      "Hot-Dry & Mixed Dry",
                                               TRUE ~ ba_climate_zone)
)


## Split climate zone data into unique and overlap states ------------------

wide_counts_clim <- tabyl(clim_zones, state_fips, ba_climate_zone)
long_counts_clim <- wide_counts_clim %>% pivot_longer(cols=c(2:9),
                                                      names_to = "climate_zone",
                                                      values_to = "counts") %>% filter(counts != 0)

## 23 states have only one climate region.
one_clim_reg_st <- long_counts_clim %>% group_by(state_fips) %>% summarise(n=n()) %>% filter(n == 1)
unique_st <- unique(one_clim_reg_st$state_fips)

## 34 straddle climate regions apparently?

overlap_pumas <- puma_2010 %>% filter(!STATEFIP %in% unique_st)
overlap_st <- unique(overlap_pumas$STATEFIP)



## Let's calculate some intersections -------------------------------------

## SF object have different cartographic boundaries
st_crs(overlap_pumas)
st_crs(counties_2010)

## Transform county object to same crs as pumas object.
co_transformed <- st_transform(counties_2010, crs = st_crs(overlap_pumas))


## Calculate areas
overlap_areas <- st_intersection(overlap_pumas, co_transformed) %>% 
                 mutate(area = as.numeric(st_area(.)))


## Filter overlapping data to observation with largest area associated w/ PUMA
puma_co_areas <- overlap_areas %>% 
                 group_by(STATEFIP, PUMA) %>% 
                 filter(area == max(area)) %>%
                 ungroup() %>% 
                 select(STATEFIP, COUNTYFP, PUMA, area) %>% 
            
                 rename(state_fips = STATEFIP,
                        county_fips = COUNTYFP)

## Fill out puma shape-file w/ information needed to create area based climate regions

## Narrow climate zone data to merge keys and climate zone
clim_narrowed <- select(clim_zones, state_fips, county_fips, climate_reg_recs)

## Join puma / county area estimates w/ narrowed climate data
puma_clim_area <- puma_co_areas %>% left_join(clim_narrowed, 
                                              by=c("state_fips", "county_fips"))
puma_clim_area <- as.data.frame(puma_clim_area) %>% select(-geometry)

## Join puma climate area estimates w/ shape file ----> coerce back to shapefile
puma_sf <- puma_2010 %>%
           rename(state_fips = STATEFIP) %>% 
          left_join(puma_clim_area, 
                     by=c("state_fips", "PUMA")) %>% 
  
          mutate(climate_reg_recs = case_when(
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

counties_2010 <- counties_2010 %>% rename(county_fips = COUNTYFP,
                                          state_fips = STATEFP) 

clim_zone_sf <- counties_2010 %>%  
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

ggsave("climate_region_counties.jpeg", plot = gg_county_clim, device = "jpg", 
       path = here("recs_pums_master", "climate_regions"), width = 10, height = 10)

ggsave("climate_region_pumas.jpeg", plot = gg_puma_clim, device = "jpg", 
       path = here("recs_pums_master", "climate_regions"), width = 10, height = 10)




## Join county / climate data with pums crosswalk --------------------------

## File used to enrich pums data w/ climate region information. 

puma_clim_to_join <- as.data.frame(puma_sf) %>% select(state_fips, county_fips, PUMA, area, climate_reg_recs)
joined_clim_crosswalk <- puma_crosswalk %>% left_join(puma_clim_to_join, 
                                                      by = c("State10" = "state_fips",
                                                             "PUMA10" = "PUMA")) 

write_csv(joined_clim_crosswalk, here("recs_pums_master", 
                                      "climate_regions",  "PUMA_10_20_clim_crosswalk.csv"))












## Scraps to center / zoom in on US. (Specifically coord_sf..)
# gg_county_clim <- ggplot(non_contig_county, aes(fill = climate_reg_recs)) +
#   geom_sf() +
#   #scale_fill_manual(values = viridis::viridis(n = 8, option = "inferno")) +
#   scale_fill_brewer(palette = "Set2") +
#   theme_minimal()  #+ 
# # coord_sf(xlim = c(-130, -65), 
# #          ylim = c(24, 50), expand = FALSE)
