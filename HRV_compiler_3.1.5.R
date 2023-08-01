library(tidyverse)
library(readxl)


compile <- function(directory = getwd(), vars_to_keep = c("Segment Number", "RSA", "RMSSD"),
                    resp_range = c(0.12, 0.4)) {
  directory = paste0(directory, "/")
  # obtain the excel file names
  files = c(list.files(directory, pattern = "*.xlsx$"))
  
  # ensure segment number is in vars to keep
  if (!("Segment Number" %in% vars_to_keep)) {
    vars_to_keep <- c("Segment Number", vars_to_keep)
  }
  # ensure respiration rate is in vars to keep
  if (!("Respiration Rate" %in% vars_to_keep)) {
    vars_to_keep <- c("Respiration Rate", vars_to_keep)
  }
  # convert resp_range from Hz to cycles per minute
  resp_range <- resp_range*60
  # extract data for each excel file
  df_out <- data.frame(matrix(ncol = (length(vars_to_keep) + 1), nrow = 0))
  colnames(df_out) <- c(vars_to_keep, "filename")
  for(file in files){
    # save file name
    filename <- str_replace(file, ".xlsx", "")
    # read in the file
    df <- read_excel(paste0(directory, file))
    # remove rows where version is NA
    df <- df %>% filter(!is.na(Version))
    # find the row number for "Segment Number"
    index = 1
    for (row in df$Version) {
      if (row == "Segment Number") {
        break
      } else {
        index = index + 1
      }
    }
    # filter the file
    df2 <- df[index:nrow(df), ] %>%
      # keep only relevant variables
      filter(Version %in% vars_to_keep)
    # transpose the df
    df3 <- as_tibble(t(df2))[2:nrow(t(df2)), ]
    # change column names
    names(df3) <- as_tibble(t(df2))[1,]
    # add filename column
    df3$filename <- filename
    # make new resp_within_range column
    df3$resp_within_range <- NA
    # make respiration rate variable numeric
    df3$`Respiration Rate` <- as.numeric(df3$`Respiration Rate`)
    # check if respiration rates were collected
    if (sum(is.na(df3$`Respiration Rate`)) != length(df3$`Respiration Rate`)) {
      # check if rates within range for each segment
      df3$resp_within_range <- ifelse((df3$`Respiration Rate` >= resp_range[1]) &
                                        (df3$`Respiration Rate` <= resp_range[2]), 
                                      1, 0)
    }
    # append the subject data to the final df
    df_out = rbind(df_out, df3)
  }
  return(df_out)
}