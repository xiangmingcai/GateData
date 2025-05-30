
#' Draw Polygon Gate
#'
#' use shinyapp to draw a polygon gate on data (plot on background)
#'
#' @param df data dataframe, should include following cols: x_col, y_col, feature_col, parentgate_col. The df should not have newgate_col or the following preserved col names: "x_scaled", "y_scaled" or, "f_value".
#' @param x_col col name of x coordinate. This col should be continuous vlaues.
#' @param y_col col name of y coordinate. This col should be continuous vlaues.
#' @param feature_col col name of features, which is used to color data points. This col should be continuous vlaues.
#' @param parentgate_col col name of parent gate. This col should be boolean values (True/False).Only data points with true value will be ploted.
#' @param newgate_col a new string name, which is used to name the new gate
#' @param canvas_width numeric value, set the width of canvas. Default is 800.
#' @param canvas_height numeric value, set the height of canvas. Default is 400.
#' @return gate object, incuding used parameters and vertex coordinates of polygon gate.
#' @details
#' This function is suitable for scenarios such as imaging analysis, spatial transcriptome, single cell sequencing analysis, or flow cytometry analysis where manual gating is required.
#' Users can draw a polygon interactively on a 2D plot (spatial coordinates, umap, tsne, pca ...).
#' Both concave and convex polygons are supported. It is recommended that the polygon edges do not intersect each other.
#' If they do, please carefully verify whether the gating results meet your expectations.
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
#' @import shiny
#' @import jsonlite
#' @export
PolygonGating <- function(df, x_col, y_col, feature_col,
                          parentgate_col, newgate_col,
                          canvas_width=800, canvas_height=400){
  #check input
  cols = colnames(df)
  #check required_cols
  required_cols <- c(x_col, y_col, feature_col, parentgate_col)
  missing_cols <- setdiff(required_cols, cols)
  if (length(missing_cols) > 0) {
    stop(paste("The following colnames are not found in df:", paste(missing_cols, collapse = ", ")))
  }

  #check reserved_cols
  reserved_cols <- c("x_scaled", "y_scaled","f_value")
  used_reserved <- intersect(reserved_cols, cols)
  if (length(used_reserved) > 0) {
    stop(paste("The following preserved colnames are found in df:", paste(used_reserved, collapse = ", ")," Please do not use them."))
  }

  # check newgate_col
  if (newgate_col %in% cols) {
    stop(paste("The new gate colname '", newgate_col, "' is already in the df, please use other name.", sep = ""))
  }

  #scale df
  scaled_df <- scale_data_to_canvas(df, x_col, y_col, canvas_width*0.8, canvas_height*0.8)
  scaled_df[,"f_value"]<-scaled_df[,feature_col]
  #subset draw_df
  draw_df = scaled_df[(scaled_df[,parentgate_col]), c("x_scaled", "y_scaled","f_value")]

  #Shiny app for interactive polygon drawing
  #ui
  {
    ui <- fluidPage(
      tags$head(
        tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.0/fabric.min.js"),
        tags$script(HTML("
      let canvas, polygon, points = [];
      let vertexCircles = [];
      let controlCircles = [];
      let data;
      let canvas_width;
      let canvas_height;
      let plotArea;
      let x_max;
      let x_min;
      let y_max;
      let y_min;
      let is_finalized = false;

      Shiny.addCustomMessageHandler('initPoints', function(message) {

        data = message.data;
        canvas_width = message.canvas_width;
        canvas_height = message.canvas_height;
        x_max = message.x_max;
        x_min = message.x_min;
        y_max = message.y_max;
        y_min = message.y_min;

        initFabric(data,canvas_width,canvas_height);

      });

      function recover_coor(input, raw_max, raw_min, new_max, new_min=0, axis = 'x') {
        if (raw_min == raw_max) {
          raw_min = raw_max - 0.5;
          raw_max = raw_min + 1;
        }
        output  = ((raw_max - raw_min) * (input - new_min) / (new_max - new_min)) + raw_min;
        if (axis == 'y') {
          output = raw_max + raw_min - output;
        }
        output = shink_canvas_coor(output,raw_max,raw_min,shink_ratio = 0.8)
        return output
      }

      function shink_canvas_coor(input,raw_max,raw_min,shink_ratio = 0.8) {
        //correct coor due to part of canvas is plot area
        new_mid = (raw_max + raw_min) / 2;
        dif = (new_mid - input) / 0.8;
        output = new_mid - dif
        return output
      }


      function drawPoints(data,canvas_width,canvas_height) {
        const ctx = document.getElementById('bgCanvas').getContext('2d');

        plotArea = {
         x: canvas_width * 0.1, // left edge
         y: canvas_height * 0.1, // top edge
         width: canvas_width * 0.8,
         height: canvas_height * 0.8
        };

        ctx.clearRect(0, 0, canvas_width, canvas_height);


        // draw axes
        ctx.strokeStyle = 'black';
        ctx.lineWidth = 1;

        // X axis line
        ctx.beginPath();
        ctx.moveTo(plotArea.x, plotArea.y + plotArea.height + canvas_height * 0.01);
        ctx.lineTo(plotArea.x + plotArea.width, plotArea.y + plotArea.height + canvas_height * 0.01);
        ctx.stroke();

        // Y axis line
        ctx.beginPath();
        ctx.moveTo(plotArea.x - canvas_width * 0.01, plotArea.y);
        ctx.lineTo(plotArea.x - canvas_width * 0.01, plotArea.y + plotArea.height);
        ctx.stroke();

        // draw label
        ctx.fillStyle = 'black';
        ctx.font = '10px Arial';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';

        for (let i = 0; i <= 10; i++) {
          const x = plotArea.x + i * (plotArea.width * 0.1);
          const label = (i * 0.1).toFixed(1);

          // X tick
          ctx.beginPath();
          ctx.moveTo(x, plotArea.y + plotArea.height + canvas_height * 0.01);
          ctx.lineTo(x, plotArea.y + plotArea.height + canvas_height * 0.02);
          ctx.stroke();

          // X label
          ctx.fillText(label, x, canvas_height * 0.93);
        }

        ctx.textAlign = 'left';
        ctx.textBaseline = 'middle';

        for (let i = 0; i <= 10; i++) {
          const y = plotArea.y + plotArea.height - i * (plotArea.height * 0.1);
          const label = (i * 0.1).toFixed(1);

          // Y tick
          ctx.beginPath();
          ctx.moveTo(plotArea.x - canvas_width * 0.01, y);
          ctx.lineTo(plotArea.x - canvas_width * 0.02, y);
          ctx.stroke();

          // Y label
          ctx.fillText(label, plotArea.x - canvas_width * 0.04, y);
        }

        // draw data points
        const minValue = Math.min(...data.map(pt => pt.f_value));
        const maxValue = Math.max(...data.map(pt => pt.f_value));

        data.forEach(pt => {
          const x = plotArea.x + pt.x_scaled;
          const y = plotArea.y + plotArea.height - pt.y_scaled;

          // Calculate Colors
          const ratio = (pt.f_value - minValue) / (maxValue - minValue);
          const r = Math.round(255 * ratio);       // red
          const g = 0;
          const b = Math.round(255 * (1 - ratio));  // blue
          const alpha = 0.6;

          ctx.fillStyle = `rgba(${r},${g},${b},${alpha})`;
          ctx.beginPath();
          ctx.arc(x, y, 2, 0, 2 * Math.PI);
          ctx.fill();
        });

        // draw legend
        const legendX = plotArea.x + plotArea.width + canvas_width * 0.01;
        const legendY = plotArea.y;
        const legendHeight = plotArea.height * 0.5;

        for (let i = 0; i <= 100; i++) {
         const ratio = i / 100;
         const r = Math.round(255 * ratio);
         const b = Math.round(255 * (1 - ratio));
         ctx.fillStyle = `rgba(${r},0,${b},1)`;
         ctx.fillRect(legendX, legendY + i * (legendHeight / 100), canvas_width * 0.01, (legendHeight / 100));
        }

        ctx.fillStyle = 'black';
        ctx.font = '10px Arial';
        ctx.fillText(maxValue.toFixed(2), legendX + canvas_width * 0.01, legendY);
        ctx.fillText(minValue.toFixed(2), legendX + canvas_width * 0.01, legendY + legendHeight);

      }

      function updateDebugInfo() {
        let output = '';

        if (polygon) {
          if (is_finalized) {
            if (controlCircles.length > 0) {
              output += 'Polygon Vertexes:\\n';
              controlCircles.forEach((c, i) => {
                output += `  [${i}] x: ${recover_coor(input=c.left.toFixed(2), raw_max=x_max, raw_min=x_min, new_max=canvas_width, new_min=0, axis = 'x')}, y: ${recover_coor(input=c.top.toFixed(2), raw_max=y_max, raw_min=y_min, new_max=canvas_height, new_min=0, axis = 'y')}\\n`;
              });
            };
          } else {
            output += 'Polygon Vertexes:\\n';
            polygon.points.forEach((p, i) => {
              output += `  [${i}] x: ${recover_coor(input=p.x.toFixed(2), raw_max=x_max, raw_min=x_min, new_max=canvas_width, new_min=0, axis = 'x')}, y: ${recover_coor(input=p.y.toFixed(2), raw_max=y_max, raw_min=y_min, new_max=canvas_height, new_min=0, axis = 'y')}\\n`;
            });
          };

          //output += ` _lastLeft: ${polygon._lastLeft}, _lastTop: ${polygon._lastTop}\\n` ;
          //output += ` Left: ${polygon.left}, Top: ${polygon.top}\\n` ;
          //output += ` originalLeft: ${polygon.originalLeft}, originalTop: ${polygon.originalTop}\\n` ;
        }

        document.getElementById('debugOutput').textContent = output;
      }

      function initFabric(data,canvas_width,canvas_height) {
        drawPoints(data,canvas_width,canvas_height);
        canvas = new fabric.Canvas('fabricCanvas', {
          selection: false
        });

        canvas.on('mouse:down', function(opt) {
          const pointer = canvas.getPointer(opt.e);

          if (polygon && polygon.edit) return;

          if (points.length > 2) {
            const first = points[0];
            const dx = pointer.x - first[0];
            const dy = pointer.y - first[1];
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 6) {

              finalizePolygon();
              return;
            }
          }

          points.push([pointer.x, pointer.y]);
          drawTempPolygon();
        });

        function drawTempPolygon() {
          if (polygon) canvas.remove(polygon);

          polygon = new fabric.Polygon(points.map(p => ({ x: p[0], y: p[1] })), {
            fill: 'rgba(255,0,0,0.2)',
            stroke: 'red',
            strokeWidth: 2,
            objectCaching: false,
            selectable: false,
            originX: 'left',
            originY: 'top'
          });

          canvas.add(polygon);

          vertexCircles.forEach(c => canvas.remove(c));
          vertexCircles = [];

          points.forEach(p => {
            const circle = new fabric.Circle({
              left: p[0],
              top: p[1],
              radius: 3,
              fill: 'red',
              selectable: false,
              evented: false,
              originX: 'center',
              originY: 'center'
            });
            canvas.add(circle);
            vertexCircles.push(circle);
          });

          canvas.renderAll();
          updateDebugInfo();
        }

        function finalizePolygon() {
          vertexCircles.forEach(c => canvas.remove(c));
          vertexCircles = [];
          is_finalized = true;

          polygon.set({ selectable: true, hasControls: false });
          polygon.edit = true;

          polygon._lastLeft = polygon.left;
          polygon._lastTop = polygon.top;
          polygon.originalLeft = polygon.left
          polygon.originalTop = polygon.top

          polygon.on('moving', function() {

            const dx = polygon.left - polygon._lastLeft;
            const dy = polygon.top - polygon._lastTop;

            polygon.points.forEach((p, i) => {

              if (controlCircles[i]) {
                controlCircles[i].left += dx;
                controlCircles[i].top += dy;
                controlCircles[i].setCoords();
              }
            });

            polygon._lastLeft = polygon.left;
            polygon._lastTop = polygon.top;

            canvas.requestRenderAll();
            updateDebugInfo();
          });

          controlCircles = [];
          polygon.points.forEach((point, index) => {
            const circle = new fabric.Circle({
              left: point.x,
              top: point.y,
              radius: 5,
              fill: 'blue',
              hasBorders: false,
              hasControls: false,
              originX: 'center',
              originY: 'center',
              LastLeft: point.x,
              LastTop: point.y,
              OriginalLeft: point.x,
              OriginalTop: point.y
            });

            circle.index = index;

            circle.on('moving', function() {
              dx = this.left - this.OriginalLeft - (polygon.left - polygon.originalLeft)
              dy = this.top - this.OriginalTop - (polygon.top - polygon.originalTop)
              polygon.points[this.index].x = this.OriginalLeft + dx;
              polygon.points[this.index].y = this.OriginalTop + dy;
              polygon.set({ dirty: true });
              this.LastLeft = this.left
              this.LastTop = this.top
              canvas.requestRenderAll();
              updateDebugInfo();
            });

            canvas.add(circle);
            controlCircles.push(circle);

          });

          canvas.renderAll();
          updateDebugInfo();

          document.getElementById('confirm').onclick = function() {
              if (controlCircles) {
                console.log('confirm2:', controlCircles);
                const coords = controlCircles.map(p => ({
                  x: recover_coor(input=p.left, raw_max=x_max, raw_min=x_min, new_max=canvas_width, new_min=0, axis = 'x'),
                  y: recover_coor(input=p.top, raw_max=y_max, raw_min=y_min, new_max=canvas_height, new_min=0, axis = 'y')
                }));

                console.log('confirm3:', coords);
                Shiny.setInputValue('polygon_coords', coords);
              }
            };
          document.getElementById('close').onclick = function() {
            console.log('close:', 'pressed');
          };
        }

        Shiny.addCustomMessageHandler('finalizePolygon', function(message) {
          if (polygon && !polygon.edit) {
            finalizePolygon();
          }
        });


      }


    "))
      ),
      titlePanel("Draw and edit polygon gate"),
      div(style = paste0("position: relative; width: ",canvas_width,"px; height: ",canvas_height,"px;"),
          tags$canvas(id = "bgCanvas", width = canvas_width, height = canvas_height,
                      style = "position: absolute; left: 0; top: 0; z-index: 0;"),
          tags$canvas(id = "fabricCanvas", width = canvas_width, height = canvas_height,
                      style = "position: absolute; left: 0; top: 0; z-index: 1;")
      ),
      actionButton("finalize", "Finish draw, start fine adjust"),
      actionButton("confirm", "Confirm and send gate to R"),
      actionButton("close", "Close page"),
      tags$h4("Live points of polygon gate: "),
      tags$pre(id = "debugOutput", style = "max-height: 300px; overflow-y: auto; background: #f9f9f9; padding: 10px; border: 1px solid #ccc;"),
      verbatimTextOutput("coords_out")
    )
  }
  #server
  server <- function(input, output, session) {
    observe({
      session$sendCustomMessage("initPoints",
                                list(
                                  data = toJSON(draw_df),
                                  x_max = max(scaled_df[, c(x_col)]),
                                  x_min = min(scaled_df[, c(x_col)]),
                                  y_max = max(scaled_df[, c(y_col)]),
                                  y_min = min(scaled_df[, c(y_col)]),
                                  canvas_width = canvas_width,
                                  canvas_height = canvas_height
                                )
      )
    })

    observeEvent(input$finalize, {
      session$sendCustomMessage("finalizePolygon", list())
    })

    observeEvent(input$polygon_coords, {
      print("polygon Received")
      #print(input$polygon_coords)
    })

    observeEvent(input$confirm, {
      output$coords_out <- renderPrint({
        #input$polygon_coords
        "gating confirmed"
      })
    })

    observeEvent(input$close, {
      stopApp(input$polygon_coords)
    })
  }
  #run app
  result <- runApp(shinyApp(ui, server))
  coords = result2list(result)
  #create polygon gate
  gate <- create_gate(id = newgate_col, label = newgate_col,
                      coords = coords,
                      x_col = x_col, y_col = y_col,
                      parentgate_col = parentgate_col,
                      newgate_col = newgate_col)
  return(gate)

}
