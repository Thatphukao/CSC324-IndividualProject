# Load required libraries
library(shiny)
library(shinythemes)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(memoise)

# Data for different genres and corresponding file paths
billboardData <- list("Country" = "countryLyrics.txt",
                      "R'n'B" = "r&bLyrics.txt",
                      "Rap" = "rapLyrics.txt",
                      "Pop" = "popLyrics.txt",
                      "Rock" = "rockLyrics.txt")

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
    tabPanel("Word Cloud",
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
    myCorpus <- tm_map(myCorpus, removeWords, c(stopwords("en"), "the", "and", "Error: Could not find lyrics."))
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
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
