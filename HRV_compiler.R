library(tidyverse)
library(readxl)


compile <- function(directory = getwd(), vars_to_keep = c("RSA", "RMSSD")) {
  directory = paste0(directory, "/")
  # obtain the excel file names
  files = c(list.files(directory, pattern = "*.xlsx$"))
  
  # extract data for each excel file
  df_out <- data.frame(matrix(ncol = (length(vars_to_keep) + 2), nrow = 0))
  colnames(df_out) <- c(vars_to_keep, "Segment", "filename")
  for(file in files){
    # save file name 
    filename <- str_replace(file, ".xlsx", "")
    # read in the file
    df <- read_excel(paste0(directory, file)) %>%
      # keep only relevant variables
      filter(`Segment Number` %in% vars_to_keep)
    # transpose the df
    df2 <- as_tibble(t(df))[2:nrow(t(df)), ]
    # change column names
    names(df2) <- as_tibble(t(df))[1,]
    # add a column for segment number
    df2$Segment <- c(seq(1, nrow(df2)))
    # add filename column
    df2$filename <- filename
    # append the subject data to the final df
    df_out = rbind(df_out, df2)
  }
  return(df_out)
}

