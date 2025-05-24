
#' Reform return from shinyapp into list
#'
#' @param coords_result The returned coordinates of polygon vertexes from shiny app.
#' @return list object.
#' @details
#' This function will reform return from shinyapp into a list object.
#' @keywords internal
result2list = function(coords_result){
  coords_matrix <- matrix(coords_result, ncol = 2, byrow = TRUE)

  coords_list <- apply(coords_matrix, 1, function(row) {
    list(x = row[1], y = row[2])
  })

  return(coords_list)
}
