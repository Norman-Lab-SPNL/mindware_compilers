library(tidyverse)
library(readxl)


compile <- function(directory = getwd(), vars_to_keep = c("Segment Number", "RSA", "RMSSD")) {
  directory = paste0(directory, "/")
  # obtain the excel file names
  files = c(list.files(directory, pattern = "*.xlsx$"))
  
  # ensure segment number is in vars to keep
  if (!("Segment Number" %in% vars_to_keep)) {
    vars_to_keep <- c("Segment Number", vars_to_keep)
  }
  
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
    # append the subject data to the final df
    df_out = rbind(df_out, df3)
  }
  return(df_out)
}