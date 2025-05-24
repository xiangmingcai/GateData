
#' Create gate object
#'
#' @param id Could be the newgate_col.
#' @param label Could be the newgate_col.
#' @param coords List object, which is the return of result2list function.
#' @param x_col The same as that in the PolygonGating function.
#' @param y_col The same as that in the PolygonGating function.
#' @param parentgate_col The same as that in the PolygonGating function.
#' @param newgate_col The same as that in the PolygonGating function.
#' @return a S3 gate object.
#' @details
#' This function will create a gate object, which is of S3 structure. The gate contains parameters used in interactive polygon drawing and the coordinates of polygon vertexes.
#' @export
create_gate <- function(id, label, coords, x_col, y_col, parentgate_col, newgate_col) {
  structure(
    list(id = id, label = label, coords = coords,
         x_col = x_col, y_col = y_col,
         parentgate_col = parentgate_col,
         newgate_col = newgate_col),
    class = "gate"
  )
}
