library(tm)
library(wordcloud)
library(memoise)

# The list of valid genre

billboardData <<- list("Country" = "countryLyrics",
                       "R'n'B" = "r&bLyrics",
                       "Rap" = "rapLyrics",
                       "Pop" = "popLyrics",
                       "Rock" = "rockLyrics")

# Using "memoise" to automatically cache the results
getTermMatrix <- memoise(function(temp_data) {
  # Careful not to let just any name slip in here; a
  # malicious user could manipulate this value.
  if (!(temp_data %in% billboardData))
    stop("Unknown book")
  
  text <- readLines(sprintf("./%s.txt", temp_data),
                    encoding="UTF-8")
  
  myCorpus = Corpus(VectorSource(text))
  myCorpus = tm_map(myCorpus, content_transformer(tolower))
  myCorpus = tm_map(myCorpus, removePunctuation)
  myCorpus = tm_map(myCorpus, removeNumbers)
  myCorpus = tm_map(myCorpus, removeWords,
                    c(stopwords("SMART"), "the", "you", "Error: Could not find lyrics.", "dont", "nigga", "aint", "niggas"))
  
  myDTM = TermDocumentMatrix(myCorpus,
                             control = list(minWordLength = 1))
  
  m = as.matrix(myDTM)
  
  sort(rowSums(m), decreasing = TRUE)
})
