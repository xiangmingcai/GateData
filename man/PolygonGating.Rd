% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PolygonGating.R
\name{PolygonGating}
\alias{PolygonGating}
\title{Draw Polygon Gate}
\usage{
PolygonGating(
  df,
  x_col,
  y_col,
  feature_col,
  parentgate_col,
  newgate_col,
  canvas_width = 800,
  canvas_height = 400
)
}
\arguments{
\item{df}{data dataframe, should include following cols: x_col, y_col, feature_col, parentgate_col. The df should not have newgate_col or the following preserved col names: "x_scaled", "y_scaled" or, "f_value".}

\item{x_col}{col name of x coordinate. This col should be continuous vlaues.}

\item{y_col}{col name of y coordinate. This col should be continuous vlaues.}

\item{feature_col}{col name of features, which is used to color data points. This col should be continuous vlaues.}

\item{parentgate_col}{col name of parent gate. This col should be boolean values (True/False).Only data points with true value will be ploted.}

\item{newgate_col}{a new string name, which is used to name the new gate}

\item{canvas_width}{numeric value, set the width of canvas. Default is 800.}

\item{canvas_height}{numeric value, set the height of canvas. Default is 400.}
}
\value{
gate object, incuding used parameters and vertex coordinates of polygon gate.
}
\description{
use shinyapp to draw a polygon gate on data (plot on background)
}
\details{
This function is suitable for scenarios such as imaging analysis, spatial transcriptome, single cell sequencing analysis, or flow cytometry analysis where manual gating is required.
Users can draw a polygon interactively on a 2D plot (spatial coordinates, umap, tsne, pca ...).
Both concave and convex polygons are supported. It is recommended that the polygon edges do not intersect each other.
If they do, please carefully verify whether the gating results meet your expectations.
}
\examples{
\dontrun{
# Generate example data
set.seed(123)
n <- 10000
df <- data.frame(
  x1 = runif(n),
  y1 = runif(n),
  value1 = sample(0:99, n, replace = TRUE)
)
df$gate1 <- TRUE

# Perform interactive polygon gating
gate1 <- PolygonGating(
  df = df,
  x_col = "x1",
  y_col = "y1",
  feature_col = "value1",
  parentgate_col = "gate1",
  newgate_col = "gate2"
)

# Apply the gate to the data
df <- GateDecider(gate = gate1, df = df)
}
}
