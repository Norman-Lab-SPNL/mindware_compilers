library(tidyverse)
library(readxl)

compile <- function(directory = getwd(), vars_to_keep = c("RSA", "RMSSD", "Mean IBI", "Respiration Peak Frequency", "Mean Heart Rate")) {
  directory <- paste0(directory, "/")
  files <- list.files(directory, pattern = "*.xlsx$")
  df_out <- tibble()
  
  for (file in files) {
    path <- paste0(directory, file)
    
    # Read first sheet without column names
    raw <- read_excel(path, sheet = 1, col_names = FALSE)
    colnames(raw)[1] <- "...1"  # Standardize first column name
    
    # Filter to relevant variable rows
    data <- raw %>% filter(...1 %in% vars_to_keep)
    
    if (nrow(data) == 0) {
      warning(paste("Skipping", file, "- no matching variables found."))
      next
    }
    
    # Select columns 7 and onward — only if they exist
    if (ncol(data) < 7) {
      warning(paste("Skipping", file, "- not enough segment columns to extract."))
      next
    }
    
    variable_names <- data$...1
    data_values <- data[, 7:ncol(data), drop = FALSE]
    colnames(data_values) <- paste0("Segment_", 1:ncol(data_values))
    
    long_df <- as_tibble(t(data_values))
    colnames(long_df) <- variable_names
    long_df$Segment <- 1:nrow(long_df)
    long_df$filename <- str_remove(file, ".xlsx$")
    
    df_out <- bind_rows(df_out, long_df)
  }
  
  return(df_out)
}
