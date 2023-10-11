# Read the CSV file into a data frame
billboard_data <- read.csv("billboardlyrics.csv")

# Display the column headers
column_headers <- names(billboard_data)
print(column_headers)

# Create a new data frame with selected columns
selected_columns <- billboard_data[c("date", "year", "broad_genre", "loudness", "duration_ms", "lyrics")]
print(names(selected_columns))
# Display the first few rows of the new data frame
head(selected_columns)

# Replace NA values in the "year" column with 2018
selected_columns$year <- ifelse(selected_columns$year == "NA", 2018, selected_columns$year)

head(selected_columns)

write.csv(selected_columns, "billboardCleaned.csv")
library(lubridate)
selected_columns$day <- day(mdy(selected_columns$date))
selected_columns$month <- month(mdy(selected_columns$date))

colnames(selected_columns)[colnames(selected_columns) == "broad_genre"] ="genre"
