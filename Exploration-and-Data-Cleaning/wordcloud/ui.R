library(shiny)
library(shinythemes)

fluidPage(
  # Adding custom CSS
  tags$head(
    tags$style(HTML("
                    body {
                      font-family: 'Comic Sans MS', sans-serif;
                      font-size: 18px; /* You can adjust the size as you prefer */
                    }
                  "))
  ),
  titlePanel("Word Cloud"),
  theme = shinytheme("superhero"),
  sidebarLayout(
    sidebarPanel(
      selectInput("selection", "Choose a genre:", choices = billboardData),
      actionButton("update", "Change"),
      hr(),
      sliderInput("freq", "Minimum Frequency:", min = 1,  max = 50, value = 15),
      sliderInput("max", "Maximum Number of Words:", min = 1,  max = 300,  value = 100)
    ),
    mainPanel(
      plotOutput("plot")
    )
  )
)
