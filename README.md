# GateData
Gate data by drawing polygon gate with shinyapp


devtools::install_github("Xiangmingcai/GateData")


set.seed(123)
n <- 10000
df <- data.frame(
  ax1 = runif(n),
  ay1 = runif(n),
  avalue1 = sample(0:99, n, replace = TRUE)
)
df$gate1 = TRUE

gate1<-PolygonGating(df=df, x_col= "ax1", y_col= "ay1", feature_col= "avalue1",
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
