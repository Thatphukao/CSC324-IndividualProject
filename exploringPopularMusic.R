# Load required libraries
library(shiny)
library(shinythemes)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(memoise)
library(ggplot2)

# Data for different genres and corresponding file paths
billboardData <- list("Country" = "countryLyrics.txt",
                      "R'n'B" = "r&bLyrics.txt",
                      "Rap" = "rapLyrics.txt",
                      "Pop" = "popLyrics.txt",
                      "Rock" = "rockLyrics.txt")

billboard <- read.csv("Exploration-and-Data-Cleaning/billboardCleaned.csv")

# UI for the Shiny app
ui <- fluidPage(
  tags$head(tags$style(HTML("
    .btn-primary {
        background-color: lightseagreen !important;
        border-color: lightseagreen !important;
    }
  "))),
  theme = shinytheme("cerulean"),
  titlePanel("Music Trends Analysis"),
  tabsetPanel(
    id = "tabs",
    tabPanel("Genre Trends",
             uiOutput("animatedGenre"),
             tags$br(),
             actionButton("resetGif", "Restart GIF")
    ),
    tabPanel("Lyric Cloud",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selection", "Choose a genre:", choices = names(billboardData)),
                 actionButton("update", "Change"),
                 hr(),
                 sliderInput("freq", "Minimum Frequency:", min = 1, max = 50, value = 15),
                 sliderInput("max", "Maximum Number of Words:", min = 1, max = 300, value = 100)
               ),
               mainPanel(
                 plotOutput("plot")
               )
             )
    ),
    tabPanel("Song Duration",
             selectInput(inputId = "n_breaks",
                         label = "Number of bins in histogram (approximate):",
                         choices = c(10, 20, 35, 50),
                         selected = 20),
             checkboxInput(inputId = "individual_obs",
                           label = strong("Show individual observations"),
                           value = FALSE),
             plotOutput(outputId = "main_plot", height = "300px")
    )
  )
)

# Server logic for the Shiny app
server <- function(input, output, session) {
  # Reactive value to trigger GIF reload
  gifTrigger <- reactiveVal(0)
  
  # Observers to change the trigger value, causing the GIF to reload
  observeEvent(input$tabs, {
    if (input$tabs == "Genre Trends") {
      gifTrigger(gifTrigger() + 1)
    }
  })
  
  observeEvent(input$resetGif, {
    gifTrigger(gifTrigger() + 1)
  })
  
  # UI output for the animated genre GIF, appending a query string to force reload
  output$animatedGenre <- renderUI({
    gifTrigger()
    tags$img(src = paste0("music_genre_animation.gif?trigger=", gifTrigger()), 
             width = "100%", height = "auto")
  })
  
  # Function to read and process text data, using memoisation to avoid re-computation
  getTermMatrix <- memoise(function(genre) {
    if (!(genre %in% names(billboardData)))
      stop("Unknown genre")
    
    text <- readLines(sprintf("www/%s", billboardData[[genre]]), encoding = "UTF-8")
    myCorpus <- Corpus(VectorSource(text))
    myCorpus <- tm_map(myCorpus, content_transformer(tolower))
    myCorpus <- tm_map(myCorpus, removePunctuation)
    myCorpus <- tm_map(myCorpus, removeNumbers)
    myCorpus <- tm_map(myCorpus, removeWords, c(stopwords("en"), "yeah", "the", "and", "Error: Could not find lyrics.", "nigga", "dont", "like", "just"))
    myDTM <- TermDocumentMatrix(myCorpus, control = list(minWordLength = 1))
    m <- as.matrix(myDTM)
    sort(rowSums(m), decreasing = TRUE)
  })
  
  # Reactive term matrix, re-computed when the "update" button is clicked
  terms <- reactive({
    input$update
    isolate(getTermMatrix(input$selection))
  })
  
  # Plot output for the word cloud
  output$plot <- renderPlot({
    v <- terms()
    wordcloud(names(v), v, scale = c(3, 0.5),
              min.freq = input$freq, max.words = input$max,
              colors = brewer.pal(8, "Dark2"))
  }, height = 550)
  
  # New code for Song Duration histogram
  output$main_plot <- renderPlot({
    
    # Clean 'duration_ms' column: convert non-numeric values (including "unknown") to NA
    billboard$duration_ms <- as.numeric(billboard$duration_ms)
    
    # Optional: remove rows with NA in 'duration_ms' (if you want to keep them, skip this line)
    billboard <- billboard[!is.na(billboard$duration_ms), ]
    # Extracting 'duration_ms' column and converting to minutes
    song_lengths <- billboard$duration_ms / 1000 / 60 # convert ms to minutes
    
    # Create histogram
    hist(song_lengths,
         probability = TRUE,
         breaks = as.numeric(input$n_breaks),
         xlab = "",  # Temporarily remove xlab; we’ll add a better one later
         main = "",  # Temporarily remove main title; we’ll add a better one later
         xaxt = "n")  # Disable automatic x-axis labels because we'll add our own
    
    if (input$individual_obs) {
      rug(song_lengths)
    }
    
    # Add improved labels and titles
    title(main = "Distribution of Song Durations",
          xlab = "Song Duration (minutes:seconds)",
          col.main = "blue", col.lab = "black",  # Optional: change color of titles and labels
          font.main = 4, font.lab = 3)  # Optional: change font style of titles and labels
    
    # Customize x-axis labels to show in minutes:seconds format
    max_val <- max(song_lengths, na.rm = TRUE)
    axis(1, at = seq(0, max_val, by = 1), 
         labels = sapply(seq(0, max_val, by = 1), 
                         function(x) {
                           mins <- floor(x)
                           secs <- round((x - mins) * 60)
                           sprintf("%d:%02d", mins, secs)
                         }),
         las = 2,  # Orientation of axis labels
         cex.axis = 0.7)  # Font size for axis labels
    
    # Optional: Add annotations to highlight specific areas or points of interest
    # Here, for example, we can highlight songs that are longer than 5 minutes
    abline(v = 5, col = "red", lty = 2)  # Add a vertical line at x = 5 minutes
    text(x = 5.5, y = max(par("usr")[3:4]) * 0.9, 
         labels = "Songs > 5 mins", 
         col = "red")  # Add text annotation to explain the red line
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
