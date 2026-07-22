# Scientific Graphs Summer 2026 (04-GEO-SOS7)
# Building Morphology Mapping in R

The workflow demonstrates two different approaches to map legends for building-level spatial data, highlighting both the flexibility and current limitations of the `legendry` package.

## Overview

Two building morphology maps were generated from vector building footprints:
1. **Building Shape Index Map**
   - The Shape Index is calculated for each building using its area and perimeter.
   - A continuous choropleth map is created to represent the variation in building compactness.
   - The map uses the **`legendry` package** to display a histogram-style legend representing the       continuous distribution of Shape Index values.

2. **Building Area Map**
   - Building footprint area is calculated for each individual building.
   - Areas are grouped into discrete classes.
   - A choropleth map is produced using these area classes.
   - Instead of a conventional legend, a **bar chart showing the frequency of buildings within          each area class** is embedded in the map. This allows the legend to communicate both the           colour classes and their distribution simultaneously.

## Legend Design

Two different legend styles are intentionally used:

### Building Area

- Discrete area classes
- Embedded bar chart showing the frequency of each area class
- Easy interpretation of both the class intervals and data distribution

### Shape Index

- Continuous colour scale
- Histogram legend generated using the **legendry** package
- Suitable for representing continuously varying building morphology metrics

## Note on the `legendry` Package

While the `legendry` package provides an elegant solution for creating histogram-based legends for continuous variables, it currently offers limited flexibility for customizing certain graphical elements. In particular, modifying or adding labels to the histogram **y-axis** is not straightforward.

For this reason, two different legend approaches are demonstrated:

- A custom bar-chart legend for discrete building area classes.
- A `legendry` histogram legend for the continuous Shape Index.


