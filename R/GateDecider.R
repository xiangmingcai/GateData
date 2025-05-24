
#' Create gate column with Polygon Gate
#'
#' use Polygon Gate to decide if each data point (in parent gate) belongs to the new gate
#'
#' @param df the same data dataframe used in PolygonGating function..
#' @param gate gate object. returned from PolygonGating function.
#' @return dataframe with a new column for the new gate.
#' @details
#' This function will use the parameter stored in gate to check each points in parent gate if they belong to the new gate. If so, the value in the new column will be True, otherwise be False.
#' @examples
#' \dontrun{
#' # Generate example data
#' set.seed(123)
#' n <- 10000
#' df <- data.frame(
#'   x1 = runif(n),
#'   y1 = runif(n),
#'   value1 = sample(0:99, n, replace = TRUE)
#' )
#' df$gate1 <- TRUE
#'
#' # Perform interactive polygon gating
#' gate1 <- PolygonGating(
#'   df = df,
#'   x_col = "x1",
#'   y_col = "y1",
#'   feature_col = "value1",
#'   parentgate_col = "gate1",
#'   newgate_col = "gate2"
#' )
#'
#' # Apply the gate to the data
#' df <- GateDecider(gate = gate1, df = df)
#' }
#' @import sp
#' @export
GateDecider <-function(df,gate){
  #extract poly_coords
  poly_coords <- do.call(rbind, lapply(gate$coords, function(pt) c(pt$x, pt$y)))
  #create polygon and sp_polygon
  polygon <- Polygon(poly_coords)
  polygons <- Polygons(list(polygon), ID = "1")
  sp_polygon <- SpatialPolygons(list(polygons))

  #extract col info
  newgate_col = gate$newgate_col
  parentgate_col = gate$parentgate_col
  x_col = gate$x_col
  y_col = gate$y_col

  #add empty new gate col
  df[,newgate_col] <- FALSE
  #create SpatialPoints
  points <- SpatialPoints(df[df[,parentgate_col],c(x_col, y_col)])
  #decide if each row is in polygon
  inside <- !is.na(over(points, sp_polygon))
  df[df[,parentgate_col],newgate_col] <- inside

  return(df)
}
