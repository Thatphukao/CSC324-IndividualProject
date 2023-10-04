billboard <- read.csv("billboard.csv")

#trying things out. Pushing this and see if it updates in Git

function(input, output) {
  
  output$main_plot <- renderPlot({
    
    # Extracting 'time' column and converting to minutes
    song_lengths <- strsplit(as.character(billboard$time), ':')
    song_lengths <- sapply(song_lengths, function(x) as.numeric(x[1]) + as.numeric(x[2]) / 60)
    
    hist(song_lengths,
         probability = TRUE,
         breaks = as.numeric(input$n_breaks),
         xlab = "Duration (minutes)",
         main = "Song Lengths Duration")
    
    if (input$individual_obs) {
      rug(song_lengths)
    }
    
    if (input$density) {
      dens <- density(song_lengths,
                      adjust = input$bw_adjust)
      lines(dens, col = "blue")
    }
    
  })
}
