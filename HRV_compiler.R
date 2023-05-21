library(tidyverse)
library(readxl)


compile <- function(directory = getwd(), vars_to_keep = c("RSA", "RMSSD"), 
                    resp_range = c(0.12, 0.4)) {
  directory = paste0(directory, "/")
  # obtain the excel file names
  files = c(list.files(directory, pattern = "*.xlsx$"))
  # convert resp_range from Hz to cycles per minute
  resp_range <- resp_range*60
  # extract data for each excel file
  df_out <- data.frame(matrix(ncol = (length(vars_to_keep) + 3), nrow = 0))
  colnames(df_out) <- c(vars_to_keep, "resp_within_range", "Segment", "filename")
  for(file in files){
    # save file name 
    filename <- str_replace(file, ".xlsx", "")
    # read in the file
    df <- read_excel(paste0(directory, file)) %>%
      # keep only relevant variables
      filter(`Segment Number` %in% c("Respiration Rate", vars_to_keep))
    # transpose the df
    df2 <- as_tibble(t(df))[2:nrow(t(df)), ]
    # change column names
    names(df2) <- as_tibble(t(df))[1,]
    # add a column for segment number
    df2$Segment <- c(seq(1, nrow(df2)))
    # add filename column
    df2$filename <- filename
    # make new resp_within_range column
    df2$resp_within_range <- NA
    # check if respiration rates were collected
    if (sum(is.na(df2$`Respiration Rate`)) != length(df2$`Respiration Rate`)) {
      # check if rates within range for each segment
      df2$resp_within_range <- ifelse((df2$`Respiration Rate` >= resp_range[1]) &
                                        (df2$`Respiration Rate` <= resp_range[2]), 
                                      1, 0)
    }
    # append the subject data to the final df
    df_out = rbind(df_out, df2)
  }
  return(df_out)
}

