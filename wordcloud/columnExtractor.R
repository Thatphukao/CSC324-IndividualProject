billboard = read.csv("wordcloud/billboardlyrics.csv")
print(colnames(billboard))
print(head(billboard$lyrics))
print(head(billboard$genre))

getwd()

# Load necessary libraries
library(dplyr)
library(stringr)
library(purrr)

# Define a vector with the genres of interest
genres_of_interest <- c('rock')

# Define a function to check if any of the genres_of_interest are in the genre column for each row
is_genre_of_interest <- function(genre_str, genres_of_interest) {
  # Extract the genres from the genre_str
  genres <- str_extract_all(genre_str, "[a-z&]+")[[1]]
  
  # Check if any of the extracted genres are in the genres_of_interest vector
  any(genres %in% genres_of_interest)
}

# Filter the dataframe to only include rows with the genres of interest
filtered_df <- billboard %>% filter(map_lgl(genre, is_genre_of_interest, genres_of_interest = genres_of_interest))
# After filtering your dataframe
filtered_df$lyrics <- str_replace_all(filtered_df$lyrics, "[^[:graph:]]", " ")

# Write the lyrics to a txt file
write.table(filtered_df$lyrics, "wordcloud/rockLyrics.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
