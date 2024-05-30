library(here)
library(tidyverse)
library(sf)
library(patchwork)
library(mapview)


puma_2010 <- read_sf(here("recs_pums_master", "climate_regions", "puma_2010_shapefiles",
                     "ipums_puma_2010_tl20.shp"))



ggplot(ahhh) +
  geom_sf() +      
  coord_sf(xlim = c(-130, -65), 
  ylim = c(24, 50), expand = FALSE)



hmm <- st_difference(ahhh, dawg)

ahhh

dawg <- st_set_crs(co, 'USA_Contiguous_Albers_Equal_Area_Conic')

st_crs(co)
st_crs(why)


fas <- st_difference(ss, dd)


pumas <- filter(ahhh, STATEFIP == "01")
counties <- filter(co, STATEFP == "01")


# Reproject dd to the same CRS as ss
co_transformed <- st_transform(counties, crs = st_crs(pumas))

# Now, you can use st_difference with ss and dd_transformed
overlap_test <- st_intersection(pumas, co_transformed)


overlap <- ggplot() +
  geom_sf(data = fas) +
  theme_minimal()

co_al <- ggplot() +
  geom_sf(data = dd) +
  theme_minimal()

pu_al <- ggplot() +
  geom_sf(data = ss) +
  theme_minimal()

wrap_plots(co_al, pu_al, overlap)

fas$geometry
ss$geometry

test <- overlap_test %>% mutate(area = as.numeric(st_area(.)))
st_crs(ss)
st_crs(dd)
glimpse(ahhh)




grrr <- filter(test, PUMA == "01700") %>% arrange(desc(area)) %>% view()

tabyl(, NAMELSAD10)

smh <- filter(ss, PUMA == "01700")
mapview(test)