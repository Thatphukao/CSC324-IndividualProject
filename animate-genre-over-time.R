# Load required packages
library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)
library(lubridate)

# Load and clean your dataset (replace 'billboardlyrics.csv' with your file)
billboardGenre <- read.csv("billboardlyrics.csv")

# Perform any data cleaning and transformation steps here
billboardGenre <- billboardGenre[c("date", "year", "broad_genre", "loudness", "duration_ms", "lyrics")]
billboardGenre$year <- ifelse(is.na(billboardGenre$year), 2018, billboardGenre$year)
billboardGenre$day <- day(mdy(billboardGenre$date))
billboardGenre$month <- month(mdy(billboardGenre$date))

# Group data by year and month, and count genres for each group
genre_count_data <- billboardGenre %>%
  group_by(year, month, broad_genre) %>%
  summarize(genre_count = n()) %>%
  ungroup()

static_plot <- ggplot(data = genre_count_data, aes(x = month, y = genre_count, fill = broad_genre)) +
  geom_bar(stat = "identity") +
  labs(title = "Music Genre Popularity Over Time",
       x = "Month",
       y = "Genre Count") +
  theme_minimal()

animated_plot <- static_plot +
  transition_states(
    states = paste(year, month),
    transition_length = 2,
    state_length = 1
  ) +
  enter_fade() +
  exit_fade()
library(gifski)
# For GIF
animate(
  animated_plot,
  nframes = 200,  # Number of frames
  fps = 20,       # Frames per second
  width = 800,    # Width of the animation in pixels
  height = 600,   # Height of the animation in pixels
  renderer = gifski_renderer("music_genre_animation.gif")
)

# For GIF
anim_save("music_genre_animation.gif", animated_plot)



