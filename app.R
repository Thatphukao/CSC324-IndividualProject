# Load required libraries
library(shiny)
library(shinythemes)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(memoise)

billboardData <<- list("Country" = "countryLyrics.txt",
                       "R'n'B" = "r&bLyrics.txt",
                       "Rap" = "rapLyrics.txt",
                       "Pop" = "popLyrics.txt",
                       "Rock" = "rockLyrics.txt")

# UI
ui <- fluidPage(
    tags$head(tags$script(HTML("
    function reloadGIF() {
        var img = document.getElementById('genreGIF');
        var src = img.src;
        img.src = '';
        img.src = src;
    }
  "))),
    theme = shinytheme("superhero"),
    titlePanel("Music Trends Analysis"),
    tabsetPanel(
      id = "tabs",  # Added id to the tabsetPanel for observing
      tabPanel("Genre Trends",
               tags$img(src = "music_genre_animation.gif", id = "genreGIF", width = "100%", height = "auto"),  # Added id to the img tag
               tags$br()
      ),
    tabPanel("Word Cloud",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selection", "Choose a genre:", choices = names(billboardData)),
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
  )
)

# server
# Server
# Server
server <- function(input, output, session) {
  
  # A reactive value to hold the trigger for the GIF reload
  gifTrigger <- reactiveVal(0)
  
  observeEvent(input$tabs, {
    if (input$tabs == "Genre Trends") {
      gifTrigger(gifTrigger() + 1)
    }
  })
  
  observeEvent(input$play, {
    gifTrigger(gifTrigger() + 1)
  })
  
  output$animatedGenre <- renderUI({
    gifTrigger()  # This makes the UI element reactive to changes in gifTrigger
    tags$img(src = paste0("music_genre_animation.gif?trigger=", gifTrigger()), 
             width = "100%", height = "auto")
  })

  getTermMatrix <- memoise(function(genre) {
    print(paste("Genre:", genre, "Available Genres:", paste(names(billboardData), collapse = ', ')))
    
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
  
  
  terms <- reactive({
    input$update
    isolate({
      withProgress({
        setProgress(message = "Processing corpus...")
        getTermMatrix(input$selection)
      })
    })
  })
  
  wordcloud_rep <- repeatable(wordcloud)
  
  output$plot <- renderPlot({
    v <- terms()
    wordcloud_rep(names(v), v, scale = c(3, 0.5),  # Adjusted scale to fit words within the plot area
                  min.freq = input$freq, max.words = input$max,
                  colors = brewer.pal(8, "Dark2"))
  }, height = 550)  # Adjusted plot height
}

# Run the application 
shinyApp(ui = ui, server = server)

