
# NEW CAIRO BUILDING-MORPHOLOGY MAPS

# Two separate maps:
# 1. Shape index with histogram legend using legendry
# 2. Building area with bargraph as legend

# load the packages
library(sf)
library(dplyr)
library(ggplot2)
library(legendry)
library(maptiles)
library(tidyterra)
library(ggspatial)
library(nngeo)
library(scales)
library(grid)
library(patchwork)
library(rnaturalearth)
library(terra)

# load and read the files
setwd("S:/EAGLE_Academic/Scientific_Graphics")
structured <- st_read("NewCairo_structured.gpkg")
unstructured<- st_read("NewCairo_unstructured.gpkg")

# add a column of urban type before binding
structured$urban_type <- "structured"
unstructured$urban_type <- "unstructured"

# combining both layers
buildings <- rbind(structured, unstructured)

# reprojecting into a projected CRS (WGS 84 / UTM Zone 36N; EPSG: 32636)
buildings <- st_transform(buildings, crs = 32636)

# fix category order
buildings$urban_type <- factor(  buildings$urban_type,
    levels = c("structured","unstructured"))

# calculate building area
buildings$area_m2 <- as.numeric(st_area(buildings))

# calculate perimeter and shape index
buildings$perimeter_m <- as.numeric(st_length(st_boundary(buildings)))
buildings$shape_index <- buildings$perimeter_m /(2 * sqrt(pi * buildings$area_m2))

range(buildings$shape_index)
summary(buildings$shape_index)

## create an inset map
# get Egypt boundary and ESRI basemap
egypt <- rnaturalearth::ne_countries(country = "Egypt",scale = "small",returnclass = "sf")
egypt_basemap <- get_tiles(egypt, provider = "Esri.WorldImagery", crop = TRUE, zoom = 5)

# mask the basemap to Egypt's boundary
egypt_mask_polygon <- st_transform(egypt, crs(egypt_basemap))
egypt_basemap_masked <- mask(egypt_basemap, vect(egypt_mask_polygon))

# create a point representing Cairo
aoi_location <- buildings %>%
  st_union() %>%
  st_centroid()

# create the inset map
inset_map <- ggplot() +
  layer_spatial(egypt_basemap_masked, alpha = 0.85)+
  geom_sf(data = egypt, fill = NA, colour = "black", linewidth = 0.6) +
  geom_sf(
    data = aoi_location,
    shape = 21,
    size = 2,
    fill = "red",
    colour = "red",
    stroke = 0.2
  ) +
  annotation_scale(
    location = "br",
    width_hint = 0.20,
    unit_category = "metric",
    style = "bar",
    pad_x = unit(0.08, "cm"),
    pad_y = unit(0.08, "cm"),
    text_cex = 0.45,
    line_width = 0.4,
    height = unit(0.08, "cm")
  ) +
    annotation_north_arrow(
    location = "tr",
    which_north = "true",
    pad_x = unit(0.12, "cm"),
    pad_y = unit(0.12, "cm"),
    height = unit(0.65, "cm"),
    width = unit(0.65, "cm"),
    style = north_arrow_orienteering( text_size = 5, line_width = 0.5)
  ) +
  labs(title = "Egypt Boundary",
       caption = paste("Source: Esri World Imagery"))+
  theme_void() +
  theme(
    plot.title = element_text(size = 8,face = "bold", hjust = 0.5),
    panel.border = element_rect(colour = "black",linewidth = 0.5,fill = NA),
    panel.background = element_blank(),
    plot.background = element_blank(),
    plot.margin = margin(2, 2, 2, 2)
  )

# prepare the common basemap within the bounding box
bbox <- st_bbox(buildings) %>% st_as_sfc() %>% st_buffer(300) %>% st_bbox()
basemap <- get_tiles(bbox, provider = "CartoDB.Positron", crop = TRUE, zoom = 15)

# create a shape_index chloropleth map with legend as a histogram from legendry
# create a separate variable to place the values above 1.8
buildings$shape_index_plot <- ifelse(
  buildings$shape_index > 1.8,
  1.9,
  buildings$shape_index
)

# define the breaks appropriate for the shape index for the legend
shape_breaks <- c(seq(1.0, 1.8, by = 0.1), 1.9)
shape_labels <- c(sprintf("%.1f", seq(1.0, 1.8, by = 0.1)), ">1.8")

# create a histogram guide
histogram_guide <- compose_sandwich(
  middle = gizmo_histogram(
    just = 0,
    direction = "horizontal",
    hist.args = list(breaks = seq(1.0, 1.9, by = 0.1)),
    theme = theme_guide(
      key.width = unit(8, "cm"),
      key.height = unit(4, "cm"),
    )
  ),
  text = "axis_base",
  title = "Building shape index",
  theme = theme_guide(
    title = element_text(face = "bold", size = 9, hjust = 0.5),
    title.position = "bottom",
    line = element_blank(),
    ticks = element_blank(),
    margin = margin(4, 4, 4, 4),
    background = element_rect(fill = alpha("white", 0.9), color = NA)
  )
)

#shape index chloropleth map
map_shape <- ggplot(buildings)+
  layer_spatial(basemap, alpha = 0.4) +
  geom_sf(aes(fill = shape_index_plot), color = NA, linewidth = 0)+
  scale_fill_gradientn(
    colours = scales::brewer_pal(
      palette = "YlGnBu"
    )(9),
    limits = c(1, 1.9),
    breaks = shape_breaks,
    labels = shape_labels,
    oob = scales::squish,
    guide = histogram_guide
  )+
  annotation_scale(location ='br',
                   width_hint = 0.2,
                   style = "bar",
                   text_cex = 1.0,
                   line_width = 1.2,
                   height = unit(0.25, "cm")
  )+
  annotation_north_arrow(location ="tl",
                         which_north = "true",
                         style = north_arrow_orienteering()
  )+
  theme_minimal()+
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.83,0.85),
    legend.direction = "horizontal",
    legend.justification = c(0.5, 0.5),
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b=6)),
    panel.grid.major = element_line(colour = "grey60", linewidth = 0.25),
    axis.text = element_text(colour = "black", size = 9),
    panel.border = element_rect(color = "black", linewidth = 1.5, fill = NA),
    plot.caption = element_text(size = 9, hjust = 1),
    plot.margin = margin(7,7,7,7)
  )+
  coord_sf(expand = FALSE)+
  labs(
    title = "Building Shape Index in Cairo",
    subtitle = "Higher values indicate less compact and more irregular building footprints",
    caption = paste(
      "Basemap: © OpenStreetMap contributors, © CARTO",
      "CRS: WGS 84 / UTM Zone 36N (EPSG:32636)",
      "Created by: Anita Dandekhya, July 2026",
      sep = "\n"
    )
  )

# fit the inset map in shape index map
map_shape_inset <- map_shape +
  inset_element(
    inset_map,
    left = 0.02,
    bottom = 0.03,
    right = 0.25,
    top = 0.30,
    align_to = "panel"
  )
#save the shape index map as png
ggsave("ShapeIndexMap.png", map_shape_inset, width = 13, height = 10, dpi = 600)

## create building area chloropleth map with barchart as a legend
# create discrete building area classes
buildings <- buildings %>%
  mutate(
    area_class = cut(
      area_m2,
      breaks = c(0, 100, 200, 300, 400, 500, 600, 700, Inf),
      labels = c("0–100", "100–200", "200–300", "300–400", "400–500", "500–600", "600–700", ">700"),
      include.lowest = TRUE,
      right = FALSE,
      ordered_result = TRUE
    )
  )
table(
  buildings$area_class,
  useNA = "ifany"
)

# set the area class colours
area_colours <- c(
  "0–100"   = "#fff7bc",
  "100–200" = "#fee391",
  "200–300" = "#fec44f",
  "300–400" = "#fe9929",
  "400–500" = "#ec7014",
  "500–600" = "#cc4c02",
  "600–700" = "#993404",
  ">700"    = "#662506"
)

# create a building area chloropleth map
map_area <- ggplot(buildings)+
  layer_spatial(basemap, alpha = 0.4) +
  geom_sf(aes(fill = area_class), alpha = 0.78)+
  annotation_scale(location ='br', width_hint = 0.2, unit_category = "metric", style = "bar")+
  annotation_north_arrow(location ="tl", which_north = "true", style = north_arrow_orienteering())+
  scale_fill_manual(values = area_colours)+
  theme_minimal()+
  theme(
    legend.position = "none",
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b=6)),
    panel.grid.major = element_line(colour = "grey60", linewidth = 0.25),
    axis.text = element_text(colour = "black", size = 9),
    panel.border = element_rect(color = "black", linewidth = 1.5, fill = NA),
    plot.margin = margin(7,7,7,7)
  )+
  labs(
    title = "Area per Building in Cairo",
    subtitle = "Unstructured and structured urban footprints, classified by building area"
  )+
  coord_sf(expand = FALSE)

# discret area bargraph
graph_area <- ggplot(buildings, aes(x = area_class, fill = area_class)) +
  geom_bar() +
  scale_fill_manual(values = area_colours) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(size = 7, face = "plain"),
    axis.text.y = element_text(size = 7, face = "plain"),
    axis.title.x = element_text(size = 8, face = "plain"),
    axis.title.y = element_text(size = 8, face = "plain"),
    plot.background = element_rect(fill = "white"),
    panel.border = element_rect(color = "black", linewidth = 0.5, fill = NA),
    plot.caption = element_text(size = 9, hjust = 1)
  ) +
  labs(
    x = "Building-area class (m²)",
    y = "Number of buildings"
  )

# insert bargraph into the building area map
layout_area <- map_area +
  inset_element(graph_area, left = 0.55, bottom = 0.75, right = 0.98, top = 0.98) +
  plot_annotation(
    caption = paste(
      "Basemap: © OpenStreetMap contributors, © CARTO",
      "CRS: WGS 84 / UTM Zone 36N (EPSG:32636)",
      "Created by: Anita Dandekhya, July 2026",
      sep = "\n"
    )
  )+
  inset_element(
    inset_map,
    left = 0.02,
    bottom = 0.03,
    right = 0.25,
    top = 0.30,
    align_to = "panel"
  )

#save the building area map as png
ggsave("Area_per_building.png", layout_area, width = 13, height = 10, dpi = 600)





