# check that libraries are avaialable, if not install them
if (!requireNamespace("rgdal", quietly = TRUE)){install.packages("rgdal")}
library(rgdal)
if (!requireNamespace("leaflet", quietly = TRUE)){install.packages("leaflet")}
library(leaflet)
if (!requireNamespace("dplyr", quietly = TRUE)){install.packages("dplyr")}
library(dplyr)
if (!requireNamespace("magrittr", quietly = TRUE)){install.packages("magrittr")}
library(magrittr)
if (!requireNamespace("readr", quietly = TRUE)){install.packages("readr")}
library(readr)
if (!requireNamespace("knitr", quietly = TRUE)){install.packages("knitr")}
library(knitr)

# USA level zipcode file with population
tmp2 = tempdir()

#url2 = "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_zcta510_500k.zip"

#file <- basename(url2)

#download.file(url2, file)

#unzip(file, exdir = tmp2)

usa <- readOGR(dsn = "D:\Project_work\ZipCodeMap\gm-jpn-bnd_u_2_1", layer = "polbnda_jpn", encoding = "UTF-8")

dim(usa)
class(usa) # the human data is located at usa@data

# change the column name of the usa@data "ZCTA5CE10" to zipcode

names(usa)[1] = "zipcode"

#this link will not work until you take a survey
file3 = "//siapmgtr/common/ICPOS-2017 Training Materials(Undeletable)/Geospatial/zip_code_database.csv"

# will be located in the project directory folder

file.copy(file3, ".", overwrite=TRUE)

all_usa_zip <- read_csv("zip_code_database.csv")

# filter down to the specific state and select 

specific_state <- all_usa_zip %>% dplyr::filter(state == "NY") %>% 
  select(zip, primary_city, county, irs_estimated_population_2014)

# change the column names for the merge by arguement

colnames(specific_state) <- c("zipcode", "City", "County", "irs_estimated_population_2014")

# change the zipcode to a factor to full join the table

specific_state$zipcode = factor(specific_state$zipcode)

# remove redundant County label in County column

specific_state$County <- gsub("County", "", specific_state$County) 
# there is probably a space after now but not concerned about that

# full join the data set 

state_join <- dplyr::full_join(usa@data, specific_state)

# remove rows with NA's - i.e. remove everything except the choosen state

state_clean = na.omit(state_join)

# Merge a Spatial object having a data.frame (i.e. merging of non-spatial attributes).
# all.x = F removes NA values that are not common to both datasets

STATE_SHP <- sp::merge(x=usa, y=state_clean, all.x = F)

head(STATE_SHP@data)
dim(STATE_SHP)
# color palette
# pal <- colorNumeric(
#   palette = "Blues",
#   domain = STATE_SHP$estimated_population
# )
pal <- colorBin(palette = "BuPu", domain = STATE_SHP$irs_estimated_population_2014, bins = 5)

# pop values
state_popup <- paste0("<strong>County: </strong>", 
                      STATE_SHP$County, 
                      "<br><strong>City: </strong>", 
                      STATE_SHP$City, 
                      "<br><strong>Est. Population: </strong>",
                      STATE_SHP$estimated_population)
# plot the map
leaflet(data = STATE_SHP) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(fillColor = ~pal(irs_estimated_population_2014), 
              fillOpacity = 0.7, 
              color = "#BDBDC3", 
              weight = 1, 
              popup = state_popup) %>%
  addLegend("bottomleft", 
            pal = pal, 
            values = ~irs_estimated_population_2014,
            title = "Est. Population",
            opacity = 1)
save(usa,file="usa.RData")