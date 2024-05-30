library("tidyverse")
library("here")
library("janitor")
library("readxl")

clim_zones <- read_csv(here("recs_pums_master", "climate_regions", "climate_zones.csv")) %>% clean_names()
puma_crosswalk <- read_xlsx(here("recs_pums_master", "climate_regions", "PUMA2000_PUMA2010_crosswalk.xlsx")) %>% 
  rename(state_fips = State10)

puma_crosswalk <- puma_crosswalk %>% select(State10, State10_Name, PUMA10_Name) %>% rename(state_fips = State10)
glimpse(clim_zones)
glimpse(puma_crosswalk)


puma_clim_join <- puma_crosswalk %>% left_join(clim_zones, by=(c("state_fips")), relationship = "many-to-many")



wide_counts_clim <- tabyl(clim_zones, state_fips, ba_climate_zone)

long_counts_clim <- wide_counts_clim %>% pivot_longer(cols=c(2:9),
                                                      names_to = "climate_zone",
                                                      values_to = "counts") %>% filter(counts != 0)

## 23 states have only one climate region.
one_clim_reg_st <- long_counts_clim %>% group_by(state_fips) %>% summarise(n=n()) %>% filter(n == 1)

unique_st <- unique(one_clim_reg_st$state_fips)

## 34 straddle climate regions apparently?
straddle_clim_reg_st <- clim_zones %>% filter(!state_fips  %in% unique_st)

clim_reg_nest <- straddle_clim_reg_st %>% 
                 group_by(state_fips) %>% 
                 nest() %>% 
                 rename(clim_reg_data = data) %>% 
                 arrange(state_fips)

crosswalk_nest <- puma_crosswalk %>% 
                  filter(!state_fips %in% unique_st) %>% 
                  group_by(state_fips, State10_Name) %>% 
                  nest() %>% 
                  rename(pums_data = data) %>% 
                  arrange(state_fips) %>% mutate(pums_data = map(pums_data, ~
                                                                   select(.x, state_fips, PUMA10_Name)))

join_nests <- crosswalk_nest %>% 
              left_join(clim_reg_nest, by = c("state_fips")) %>% 
  mutate(clim_reg_data = map(clim_reg_data, ~
                      arrange(.x, county_name)
  ),
        pums_data = map(clim_reg_data, ~
                          arrange(.x, county_name)
  )
  ) 

fips_to_loop <- unique(join_nests$state_fips)


clim_zone_comps <- map(fips_to_loop, ~ {
  straddle_clim_reg_st %>%
    filter(state_fips == .x) %>%
    arrange(county_name)
})

pums_names_comps <- map(fips_to_loop, ~ {
  puma_crosswalk %>%
    filter(state_fips == .x) %>% 
    arrange(PUMA10_Name)
})

clim_zone_comps <- list()

for (fips in seq_along(fips_to_loop)){
clim_zone_comps[[fips]] <- join_nests[join_nests$state_fips == fips, ] %>% 
                        unnest(cols = c("clim_reg_data"))

}
al_tst <- join_nests %>% unnest(cols = c("clim_reg_data"))
al_tst2 <- join_nests %>% unnest(cols = c("pums_data")) 
  clim_reg_nest
  crosswalk_nest

 

tst <- puma_crosswalk %>% mutate(puma_names_cl = tolower(PUMA10_Name)) %>% 
                          filter(grepl("counties", puma_names_cl))
  select(-PUMA10_Name)
  
clim_reg_nest
crosswalk_nest
## For the states that don't we'll need to figure something out with pumas and counties. 

filter(puma_crosswalk, State10_Name == "Arizona") %>% view()
