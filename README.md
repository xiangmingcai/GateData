
# GateData

<!-- badges: start -->
<!-- badges: end -->

The goal of GateData is to enable users to subset dataset by drawing polygon gate with shinyapp 

## Introduction

Subset dataset is a basic task in almost all kind of analysis. Subset by manual gating could be very useful for study with x and y coordinates information like imaging analysis, single-cell RNA-seq analysis (UMAP, TSNE, and PCA), flow cytometry and so on.

Currently, some useful R functions are available but not ideal. The ***Seurat*** provides a ***CellSelector*** function for users to select points on a scatterplot and get id of them. However, it only allows rectangle selction. The ***flowGate*** supports rectangleGates and polygonGates on flow cytometry data. The ***wjawaid/gatepoints*** could manually gate data, but cannot trace back if you made more than one gate. The ***vikkki/xSelectCells*** is a UMAP based selection method, specificly designed for seurat object.

Still, a very important issue is that these methods can hardly handle large datasets with > 100,000 data points. This is due to the high CPU and GPU cost for updating selected points in real time.

The current ***GateData*** R package allows users to:

1. gate on a large dataset (could easily handle > 100,000 data points);

2. use custom features to plot data points, which makes gating accurate and easier;

3. trace back all gates made and visualize them with ggplot.

## Installation

You can install the development version of GateData from [GitHub](https://github.com/xiangmingcai) with:

``` r
devtools::install_github("xiangmingcai/GateData")
```

## Step 1 data preparation

This is a basic example which shows you how to use GateData

First, load library 
``` r
library(GateData)
library(ggplot2)
```
### Demo date, for requirements in general

``` r
set.seed(123)
n <- 10000
df <- data.frame(
  x1 = runif(n),
  y1 = runif(n),
  value1 = sample(0:99, n, replace = TRUE)
)
df$gate0 = TRUE

``` 
The input data is a dataframe with columns for x and y coordinates, feature, and parent gate.

The feature column ("value1" in this case) will be used to color data points.

The x and y coordinates and feature columns needs to be of **continuous** values.

The **parentgate is mandatory** and used to tell GateData which subset of data should be used for gating.

**You may simply add a new gate0 column with all values set to be True to start up.**

All gate columns used and generated are of **boolean** value, which indicates whether a data point belongs to the gate or not.

This is a simple structure and should be easy for any kind of research with x and y coordinates infomation to be adapted to, e.g. **image analysis after cell segmentation** or flowcytometry. 

### If you are using **Seurat for spatial transcriptome analysis**

you may get the spatial coordinates of cells to apply the GateData with following script
``` r
#pay attention to the row names, which should be the names of cells

#get spatial x and ycoordinates 
df = as.data.frame(sce@images[["fov"]]@boundaries[["centroids"]])
rownames(df) = colnames(sce)

#get potential features from meta.data
df_feature = sce@meta.data
df = cbind(df,df_feature[,c("Cell_Score_1","Cell_Score_2")])

#Or, get potential features from gene expression
df_geneExress = (as.data.frame(t(sce@assays$Xenium@layers$counts)))
colnames(df_geneExress) = rownames(sce)
rownames(df_geneExress) = colnames(sce)
df = cbind(df,df_geneExress[,c("S100A4","CD4")])

# check colnames, and rename it if it does not match your expectation
colnames(df)

df$gate1 = TRUE
``` 


### If you are using **Seurat for single cell RNA-seq analysis**

you may get the coordinates of UMAP, TSNE, or PCA to apply the GateData with following script

``` r
#pay attention to the row names, which should be the names of cells

#get x and y coordinates from UMAP
df = as.data.frame(sce@reductions[["umap"]]@cell.embeddings)

#get potential features from meta.data
df_feature = sce@meta.data
df = cbind(df,df_feature[,c("Cell_Score_1","Cell_Score_2")])

#Or, get potential features from gene expression
df_geneExress = (as.data.frame(t(sce@assays$Xenium@layers$counts)))
colnames(df_geneExress) = rownames(sce)
rownames(df_geneExress) = colnames(sce)
df = cbind(df,df_geneExress[,c("S100A4","CD4")])

# check colnames, and rename it if it does not match your expectation
colnames(df)

df$gate1 = TRUE

``` 
## Step 2 make a gate

``` r
gate1<-PolygonGating(df=df, x_col= "x1", y_col= "y1", feature_col= "value1",
              parentgate_col= "gate0", newgate_col= "gate1")
``` 
You will see a shinyapp window open. You could easily draw a draft polygon gate on it. 

Then, you could press the first "" button for fine adjustment. You may move the whole gate or adjust the vertexes. The coordinates of vertexes will be shown on the window and update in real time


When the gate is realy, press the "" button, so that the R could receive the information of the gate. 

Then, you could close the shinyapp window by click the last "" button.

## Step 3 assign data points (in parent gate) with the new gate

``` r
df <-GateDecider(gate = gate1, df = df)
``` 
With the GateDecider function, a new gate column will be add to the df.

If you want to make a child gate of the gate1, you could repeat step 2 and 3.
``` r
gate2<-PolygonGating(df=df, x_col= "x1", y_col= "y1", feature_col= "value1",
                    parentgate_col= "gate1", newgate_col= "gate2")
df <-GateDecider(gate = gate2, df = df)
``` 
## Step 4 visualize gates

``` r


polygon_df = GeneratePolygondf(gatelist = list(gate1,gate2),
              gatenames = c("gate1","gate2"),
              x_col= "x1",y_col= "y1")

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
The GeneratePolygondf function could transform gates into one dataframe for ggplot use.
Of note, in this case, gate3 is a child gate of gate2. So, only these points that are in both gate3 and gate2 are selected in gate3.

**You could make multiple parallel gates by using the same gate as parentgate when using the PolygonGating function to draw polygon gate.**



