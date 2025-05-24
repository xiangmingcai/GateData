
#' Scale data for canvas plot
#'
#' @param df The same as that in PolygonGating function.
#' @param x_col The same as that in PolygonGating function.
#' @param y_col The same as that in PolygonGating function.
#' @param canvas_width The same as that in PolygonGating function.
#' @param canvas_height The same as that in PolygonGating function.
#' @return scaled dataframe with additional x_scaled and y_scaled columns.
#' @details
#' This function will scale coordinates to fit the canvas plot. if all data points have the same x/y coordinates, it will be scaled to be in the center of canvas.
#' @keywords internal

scale_data_to_canvas <- function(df, x_col, y_col, canvas_width, canvas_height) {
  x_min <- min(df[,x_col], na.rm = TRUE)
  x_max <- max(df[,x_col], na.rm = TRUE)
  y_min <- min(df[,y_col], na.rm = TRUE)
  y_max <- max(df[,y_col], na.rm = TRUE)

  # scale x
  if (x_max == x_min) {
    df$x_scaled <- canvas_width / 2
  } else {
    df$x_scaled <- (df[,x_col] - x_min) / (x_max - x_min) * canvas_width
  }

  # scale y
  if (y_max == y_min) {
    df$y_scaled <- canvas_height / 2
  } else {
    df$y_scaled <- (df[,y_col] - y_min) / (y_max - y_min) * canvas_height
  }

  return(df)
}
