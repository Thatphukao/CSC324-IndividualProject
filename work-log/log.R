# Load the required libraries
library(ggplot2)
library(tidyverse)
library(lubridate)
library(tidyr)
library(dplyr)


# Read in the data
workHours <- read.csv("work-log/worklog.csv", stringsAsFactors = FALSE)

# Convert Date to Date type and Time to numeric
workHours$Date <- dmy(workHours$Date, format = "%d/%m")
workHours$Time <- as.numeric(workHours$Time)

# Adding a cumulative sum column for the time
workHours <- workHours %>% 
  arrange(Date) %>% 
  group_by(Category) %>% 
  mutate(CumulativeTime = cumsum(Time))

# Create a line plot for the cumulative time
ggplot(workHours, aes(x = Date, y = CumulativeTime, color = Category, group = Category)) +
  geom_line(size = 1) +
  labs(title = "Cumulative Time Spent on Project Work", 
       x = "Date", 
       y = "Cumulative Time Spent (in minutes)",
       color = "Work Category") +
  theme_minimal() +
  scale_color_brewer(palette = "Set1")


# Summarize time spent by category
workSummary <- workHours %>%
  group_by(Category) %>%
  summarise(TotalTime = sum(Time))

# Create a bar graph
ggplot(workSummary, aes(x = Category, y = TotalTime, fill = Category)) +
  geom_bar(stat = "identity") +
  labs(title = "Total Time Spent on Each Type of Work", x = "Category", y = "Total Time (in minutes)") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")


# Print the category with the maximum time spent
catMax <- workSummary[which.max(workSummary$TotalTime), ]$Category
catMin <- workSummary[which.min(workSummary$TotalTime), ]$Category

cat("Category with maximum time spent:", catMax, "\n")
cat("Category with minimum time spent:", catMin, "\n")

# Pivot the data to have categories as columns
workHoursWide <- workHours %>%
  spread(key = Category, value = Time, fill = 0)

# Melt the data for better handling in ggplot2
workHoursLong <- workHoursWide %>%
  gather(key = "Category", value = "Time", -Date)

# Create the heatmap
ggplot(workHoursLong, aes(x = Date, y = Category)) +
  geom_tile(aes(fill = Time), color = "white") +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(title = "Heatmap of Work Done Over Time",
       x = "Date",
       y = "Work Category",
       fill = "Minutes Worked") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

