# Load required libraries
library(shiny)
library(ggplot2)
library(dplyr)

# Define UI
ui <- fluidPage(
  titlePanel("Music Genre Popularity by Month"),
  
  sidebarLayout(
    sidebarPanel(
      # Add any input elements (e.g., year selector) here
    ),
    
    mainPanel(
      plotOutput("genrePlot")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  output$genrePlot <- renderPlot({
    # Prepare and filter data as needed
    filtered_data <- read.csv("billboardCleaned.csv")
    
    # Ungroup the data
    filtered_data <- filtered_data %>% ungroup()
    
    # Create genre_count by aggregating the data by genre and month
    genre_count_data <- filtered_data %>%
      group_by(month, genre) %>%
      summarize(genre_count = n(), .groups = "drop") %>%
      ungroup()
    
    # Create an animated bar plot
    
    ggplot(data = genre_count_data, aes(x = month, y = genre_count, fill = genre)) +
      geom_bar(stat = "identity") +
      labs(title = "Popularity of Music Genres Over Time",
           x = "Month",
           y = "Count") +
      #transition_states(year, transition_length = 2, state_length = 1) +
      enter_fade() + exit_fade()
  })
  
  
}

# Create Shiny app
shinyApp(ui, server)
