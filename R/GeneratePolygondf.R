
#' Generate Polygon dataframe for visualization
#'
#' use one or multiple gate objects to generate a dataframe, which could be used in ggplot to visualize gates.
#'
#' @param gatelist list of gates. list(gate1,gate2, ...)
#' @param gatenames names of gates. c("gate1","gate2", ...)
#' @param x_col col name of x coordinate. This will be used in ggplot together with data df. So, it should be the same as the col name of x coordinate in the data df.
#' @param y_col col name of y coordinate. This will be used in ggplot together with data df. So, it should be the same as the col name of y coordinate in the data df.
#' @return dataframe with gate vertex coordinates and gate names.
#' @details
#' This function will transfrom the gates objects into a dataframe, which could be used by ggplot for gates visualization.
#' @examples
#' \dontrun{
#' # Generate example data
#'
#' x_col= "x1"
#' y_col= "y1"
#' feature_col= "value1"
#'
#' polygon_df = GeneratePolygondf(gatelist = list(gate1,gate2),
#'                                gatenames = c("gate1","gate2"),
#'                                x_col,y_col)
#'
#' ggplot() +
#'   geom_point(data = df, aes(x = .data[[x_col]],
#'                             y = .data[[y_col]],
#'                             color = .data[[feature_col]]),  size = 1) +
#'   geom_polygon(data = polygon_df,
#'                aes(x = .data[[x_col]], y = .data[[y_col]],
#'                    group = gate, fill = gate,), alpha = 0.6) +
#'   scale_color_gradient(low = "#d6ecf0", high = "#75878a", na.value = NA) +
#'   scale_fill_brewer(palette = "Pastel1")+
#'   labs(title = "Scatter Plot with Multiple Polygon Gates", x = "X", y = "Y") +
#'   theme_minimal()
#' }
#' @export
GeneratePolygondf <- function (gatelist,gatenames,x_col,y_col) {
  # extract polygon coordinates, and add gate names info as group
  polygon_df <- do.call(rbind, lapply(seq_along(gatelist), function(i) {
    gate <- gatelist[[i]]
    coords <- do.call(rbind, lapply(gate$coords, function(pt) {
      data.frame(x = pt$x, y = pt$y)
    }))
    coords <- rbind(coords, coords[1, ])  # add the first vertex as the last vertex to close the polygon
    coords$gate <- i
    return(coords)
  }))
  colnames(polygon_df)[1:2] = c(x_col,y_col)
  polygon_df$gate = gatenames[polygon_df$gate]
  return(polygon_df)
}
