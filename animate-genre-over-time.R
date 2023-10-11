# Load required packages
library(ggplot2)
library(gganimate)
library(dplyr)
library(tidyr)
library(lubridate)

# Load and clean your dataset (replace 'billboardlyrics.csv' with your file)
billboardGenre <- read.csv("billboardlyrics.csv")

billboardGenre <- billboardGenre[c("date", "year", "broad_genre", "loudness", "duration_ms", "lyrics")]
billboardGenre <- billboardGenre %>%
  filter(!broad_genre %in% c("", "unknown"))  # Remove unknown and blank genres

billboardGenre$year <- ifelse(is.na(billboardGenre$year), 2018, billboardGenre$year)
billboardGenre$day <- day(mdy(billboardGenre$date))
billboardGenre$month <- month(mdy(billboardGenre$date))

complete_data <- expand.grid(
  year = unique(billboardGenre$year),
  month = unique(billboardGenre$month),
  broad_genre = unique(billboardGenre$broad_genre)
)

# Group data by year and month, and count genres for each group
genre_count_data <- billboardGenre %>%
  group_by(year, month, broad_genre) %>%
  summarize(genre_count = n(), .groups = 'drop')

# Merge with complete data to fill missing combinations with zero
genre_count_data <- complete_data %>%
  left_join(genre_count_data, by = c("year", "month", "broad_genre")) %>%
  replace_na(list(genre_count = 0))

# Calculate cumulative count for each genre over the months and years
genre_count_data <- genre_count_data %>%
  arrange(year, month, broad_genre) %>%
  group_by(broad_genre) %>%
  mutate(cumulative_count = cumsum(genre_count)) %>%
  ungroup()

# Plotting
static_plot <- ggplot(data = genre_count_data, 
                      aes(x = cumulative_count, 
                          y = reorder(broad_genre, -cumulative_count, order = TRUE), 
                          fill = reorder(broad_genre, cumulative_count))) +
  geom_col() +
  labs(title = "Music Genre Popularity Over Time",
       x = "Cumulative Genre Count",
       y = "Genre",
       fill = "Genre Name") +
  theme_minimal(base_size = 50)

# Animated Plot
animated_plot <- static_plot +
  transition_states(
    states = paste(year, sprintf("%02d", month)),
    transition_length = 2,
    state_length = 1
  ) +
  enter_fade() +
  exit_fade() +
  labs(caption = "Date: {closest_state}")

# For GIF
animate(
  animated_plot,
  nframes = 400,  
  fps = 20,       
  width = 1500,    
  height = 1000,   
  renderer = gifski_renderer("www/music_genre_animation.gif")
)

