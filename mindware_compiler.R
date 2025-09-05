library(tidyverse)
library(readxl)

VERSIONS <- list("3.2" = "3.2", "3.2.13" = "3.2", 
                 "2022-10-25" = "3.2", "2022" = "3.2",
                 "3.1" = "3.1", "3.1.7" = "3.1", "3.1.5" = "3.1",
                 "2021-08-01" = "3.1", "2021" = "3.1")

PHYSIO_TYPES <- list("HRV" = "HRV", "RSA" = "HRV", "PNS" = "HRV", 
                     "IMP" = "IMP", "PEP" = "IMP", "SNS" = "IMP",
                     "EDA" = "EDA", "GSR" = "EDA")


compile <- function(directory = getwd(), 
                    physio_type = "HRV",
                    vars_to_keep = c("Segment Number"),
                    software_version = "3.2",
                    resp_range = c(0.12, 0.4),
                    versions = VERSIONS,
                    physio_types = PHYSIO_TYPES
                    ) 
  {
  ############### Check Input
  # get physio type label
  if(physio_type %in% physio_types){
    physio_type <- physio_types[physio_type]
  } else {
    print("Sorry, the physio_type you have entered is not currently supported.")
  }
  # get version label
  if(software_version %in% versions){
    software_version <- versions[software_version]
  } else {
    print("Sorry, you have entered an invalid software version.")
  }
  ############## Get File List
  # make directory path work on both windows and mac
  directory = fs::path_abs(directory)
  # obtain the excel file paths
  print(directory)
  files = map_vec(list.files(directory, pattern = "*.xlsx$"), ~fs::path(directory, .x))
  print(files)
  
  ############# Respiration (HRV only)
  if(physio_type == "HRV"){
    # convert resp_range from Hz to cycles per minute
    resp_range <- resp_range*60
    
    # ensure respiration rate is in vars to keep
    if (!("Respiration Rate" %in% vars_to_keep)) {
      vars_to_keep <- c("Respiration Rate", vars_to_keep)
    }
  } 
  
  ################# Process Files
  df_out <- tibble()
  for(file in files){
    # get software version and mwi file name
    metadata <- extract_metadata(file, software_version)
    version_used <- metadata["version_used"]
    print(version_used)
    mwi_filename <-  metadata["mwi_filename"]
    print(mwi_filename)
    # return an error if versions don't match
    version_match = compare_versions(version_used, 
                                     software_version, versions)
    # extract data and clean
    dat <- extract_vars(file, software_version, vars_to_keep)
    print(dat)
    # add resp_rate (HRV only)
    if(physio_type == "HRV"){
      dat <- process_resp(dat, resp_range)
    }
    print(dat)
    # append metadata columns
    dat <- add_metadata(dat, mwi_filename, file)
    # attach dat to df_out
    df_out <- bind_rows(df_out, dat)
  }
  return(df_out)
}


################################## HELPER FUNCTIONS #############################
compare_versions <- function(version_used, software_version, versions){
  if(as.character(versions[as.character(version_used)]) == software_version){
    return(TRUE)
  }else{
    print(str_c("ERROR: wrong software_version entered. These data were generated with Mindware version ", 
                as.character(version_used)))
    return(FALSE)
  }
}

process_resp <- function(df, resp_range){
  # check if respiration was collected
  resp_collected <- (sum(is.na(df$`Respiration Rate`)) != length(df$`Respiration Rate`))
  
  # check if respiration within range for each segment
  if(resp_collected){
    df <- df %>%
      mutate(resp_within_range = ifelse(as.numeric(`Respiration Rate`) >= resp_range[1] &
                                          as.numeric(`Respiration Rate`) <= resp_range[2],
                                        1, 0))
    }
  else{
    print("Warning: Respiration is not recorded in the data. Was this collected?")
  }
  return(df)
}

extract_metadata <- function(file, software_version){
  if(software_version == "3.1"){
    dat <- read_excel(file, sheet = 1)
    mwi_filename <- dat %>%
      filter(Version == "File Name")
    mwi_filename <- mwi_filename[,2] %>% pull()
    version_used <- as.character(colnames(dat)[2])
    
  } else if(software_version == "3.2"){
    # Read "Settings" sheet to extract meta-data
    settings <- read_excel(file, sheet = "Settings", 
                           col_names = c("Setting", "Value"))
    version_used <- settings %>%
      filter(Setting == "Version") %>%
      select(Value) %>%
      pull() %>%
      as.character(.)
    
    mwi_filename <- settings %>%
      filter(Setting == "File Name") %>%
      select(Value) %>%
      pull()
  }
  return(c("mwi_filename" = mwi_filename, 
              "version_used" = version_used))
}

add_metadata <- function(df, mwi_filename, file){
  print(mwi_filename)
  df <- df %>%
    mutate("mwi_filename" := {{ mwi_filename }},
           excel_filename = as.character({{ file }})) %>%
    relocate(mwi_filename, excel_filename)
  return(df)
}

extract_vars <- function(file, software_version, vars_to_keep){
  if(software_version == "3.1"){
    # ensure segment number is in vars to keep
    if (!("Segment Number" %in% vars_to_keep)) {
      vars_to_keep <- c("Segment Number", vars_to_keep)
    }
    dat <- read_excel(file, sheet = 1) %>%
      filter(Version %in% vars_to_keep) %>%
      t(.) %>%
      as_tibble()
    
  } else if(software_version == "3.2"){
    dat <- read_excel(file, sheet = 1) %>%
      filter(`Segment Number` %in% vars_to_keep) %>%
      t(.) %>%
      as_tibble(., rownames = "Segment")
  }
  
  colnames(dat) <- dat[1,]
  # remove first row (colnames)
  dat <- dat[-1,] %>%
    type_convert() %>%
    rename(segment = "Segment Number")
  
  return(dat)
}

