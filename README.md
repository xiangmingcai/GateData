
# GateData

<!-- badges: start -->
<!-- badges: end -->

The goal of GateData is to enable users to draw polygon gate with shinyapp


## Installation

You can install the development version of GateData from [GitHub](https://github.com/xiangmingcai) with:

``` r
devtools::install_github("xiangmingcai/GateData")
```

## Example

This is a basic example which shows you how to use GateData:

First, we wil make some demo date. The input data is a dataframe with columns for x and y coordinates, feature, and parent gate.

The feature column ("value" in this case) will be used to color data points.

The x and y coordinates and feature columns needs to be of continuous values.

The parent gate is mandatory and used to tell GateData which subset of data should be used for gating.

You may simply add a new column with all values to be True to start up.

All gate columns used and generated are of boolean value, which indicates whether a data point belongs to the gate or not.

``` r
library(GateData)

set.seed(123)
n <- 10000
df <- data.frame(
  x1 = runif(n),
  y1 = runif(n),
  value1 = sample(0:99, n, replace = TRUE)
)
df$gate1 = TRUE

``` 



``` r
gate1<-PolygonGating(df=df, x_col= "x1", y_col= "y1", feature_col= "value1",
              parentgate_col= "gate1", newgate_col= "gate2")
df <-GateDecider(gate = gate1, df = df)

gate2<-PolygonGating(df=df, x_col= "x1", y_col= "y1", feature_col= "value1",
                    parentgate_col= "gate2", newgate_col= "gate3")
df <-GateDecider(gate = gate2, df = df)



gatelist = list(gate1,gate2)
gatenames = c("gate1","gate2")

x_col= "x1"
y_col= "y1"
feature_col= "value1"

polygon_df = GeneratePolygondf(gatelist = list(gate1,gate2),
              gatenames = c("gate1","gate2"),
              x_col,y_col)

ggplot() +
  geom_point(data = df, aes(x = .data[[x_col]], 
                            y = .data[[y_col]],
                            color = .data[[feature_col]]),  size = 1) +
  geom_polygon(data = polygon_df, 
               aes(x = .data[[x_col]], y = .data[[y_col]], 
                   group = gate, fill = gate,), alpha = 0.6) + 
  scale_color_gradient(low = "#d6ecf0", high = "#75878a", na.value = NA) +
  scale_fill_brewer(palette = "Pastel1")+
  labs(title = "Scatter Plot with Multiple Polygon Gates", x = "X", y = "Y") +
  theme_minimal()
```

