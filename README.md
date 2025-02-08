# Assigning PUMAs to Climate Regions

**Problem:** We need to assign PUMAs into their respective climate zone in order to create indoor temperature estimates, but Dept. of energy makes these determinations by county. Unfortunately, PUMAs do not nest neatly within a county, so we need to do some approximation and assignment.

**Solution:** Intersect PUMAs (either 2000 or 2010 boundaries) with a county - climate zone csv. Assign each climate zone to the PUMA that shares the largest area of intersection with a given county. 

# Data Sources

1. [Public Use Microdata Area Shapefiles - IPUMS](https://usa.ipums.org/usa/volii/boundaries.shtml): Code will work with 2000 and 2010 boundaries
2. [Department of Energy Climate Zones](https://atlas.eia.gov/datasets/eia::climate-zones-doe-building-america-program/about)
3. [Github with county - climate zone csv](https://gist.github.com/philngo/d3e251040569dba67942)

# Script Flow 

1. [01b_puma_county_clim_all.R](https://github.com/joesimeone/climate_regions/blob/main/code/01b_puma_county_clim_all.R): Performs intersection with sf package and uses tidyverse tools to filter and assign PUMA to county climate zone. Produces a map to check work, as well as a csv that can be exported off for further analysis.

# Packages Used

1. Walker K, Herman M (2023). _tidycensus: Load US Census Boundary and Attribute Data as 'tidyverse' and 'sf'-Ready Data Frames_. R
  package version 1.5, <https://CRAN.R-project.org/package=tidycensus>.
2.  Walker K (2023). _tigris: Load Census TIGER/Line Shapefiles_. R package version 2.0.4, <https://CRAN.R-project.org/package=tigris>.
3.   Pebesma, E., & Bivand, R. (2023). Spatial Data Science: With Applications in R. Chapman and Hall/CRC.
  https://doi.org/10.1201/9780429459016
4. Firke S (2023). _janitor: Simple Tools for Examining and Cleaning Dirty Data_. R package version 2.2.0,
  <https://CRAN.R-project.org/package=janitor>.
5. Wickham H, Averick M, Bryan J, Chang W, McGowan LD, François R, Grolemund G, Hayes A, Henry L, Hester J, Kuhn M, Pedersen TL, Miller
  E, Bache SM, Müller K, Ooms J, Robinson D, Seidel DP, Spinu V, Takahashi K, Vaughan D, Wilke C, Woo K, Yutani H (2019). “Welcome to
  the tidyverse.” _Journal of Open Source Software_, *4*(43), 1686. doi:10.21105/joss.01686 <https://doi.org/10.21105/joss.01686>.
6.  Müller K (2020). _here: A Simpler Way to Find Your Files_. R package version 1.0.1, <https://CRAN.R-project.org/package=here>.
7.    Neuwirth E (2022). _RColorBrewer: ColorBrewer Palettes_. R package version 1.1-3, <https://CRAN.R-project.org/package=RColorBrewer>.
8.  Wickham H, Bryan J (2023). _readxl: Read Excel Files_. R package version 1.4.3, <https://CRAN.R-project.org/package=readxl>.

