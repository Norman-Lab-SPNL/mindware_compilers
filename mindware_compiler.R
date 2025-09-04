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
                    vars_to_keep = c("Segment Number"), # HRV: RMSSD, RSA, HR, Respiration Rate; IMP: PEP, HR
                    resp_range = c(0.12, 0.4),
                    software_version = "3.2",
                    versions = VERSIONS,
                    physio_types = PHYSIO_TYPES
                    ) 
  {
  # get list of filenames to compile
  # make directory path work on both windows and mac
  directory = fs::path_abs(directory)
  # obtain the excel file names
  print(directory)
  files = map_vec(list.files(directory, pattern = "*.xlsx$"), ~fs::path(directory, .x))
  print(files)
  
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
  
  ################# Compile output from HRV software
  if(physio_type == "HRV"){
    return(compile_HRV(files, vars_to_keep, resp_range, software_version))
  } 
  ################# Compile output from  IMP software
  else if(physio_type == "IMP"){
    
  } 
  ################# Compile output from EDA software
  else if(physio_type == "EDA"){
    
  } 
  
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

compile_HRV <- function(files, vars_to_keep, resp_range, software_version, versions = VERSIONS) {
  
  # convert resp_range from Hz to cycles per minute
  resp_range <- resp_range*60
  
  # ensure respiration rate is in vars to keep
  if (!("Respiration Rate" %in% vars_to_keep)) {
    vars_to_keep <- c("Respiration Rate", vars_to_keep)
  }
  
  df_out <- tibble()
  
  for(file in files){
    if(software_version == "3.1"){
      # ensure segment number is in vars to keep
      if (!("Segment Number" %in% vars_to_keep)) {
        vars_to_keep <- c("Segment Number", vars_to_keep)
      }
      dat <- read_excel(file, sheet = 1)
      mwi_filename <- dat %>%
        filter(Version == "File Name")
      mwi_filename <- mwi_filename[,2] %>% pull()
      version_used <- as.character(colnames(dat)[2])
      print(version_used)
      dat <- dat %>%
        filter(Version %in% vars_to_keep) %>%
        t(.) %>%
        as_tibble()
      
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
      
      # read actual data
      dat <- read_excel(file, sheet = 1) %>%
        filter(`Segment Number` %in% vars_to_keep) %>%
        t(.) %>%
        as_tibble(., rownames = "Segment")
    }
  
    colnames(dat) <- dat[1,]
    # remove first row (colnames)
    dat <- dat[-1,] %>%
      type_convert() %>%
      rename(segment = "Segment Number",
             resp_rate = "Respiration Rate")
    
    # return an error if versions don't match
    print(version_used)
    version_match = compare_versions(version_used, software_version, versions)
  
    # check if respiration was collected
    resp_collected <- (sum(is.na(dat$resp_rate)) != length(dat$resp_rate))
    
    # check if respiration within range for each segment
    if(resp_collected){
      dat <- dat %>%
        mutate(resp_within_range = ifelse(as.numeric(resp_rate) >= resp_range[1] &
                                            as.numeric(resp_rate) <= resp_range[2],
                                          1, 0))}
    else{
      print("Warning: Respiration is not recorded in the data. Was this collected?")
    }
    # add metadata
    dat <- dat %>%
      mutate(mwi_filename = mwi_filename,
             excel_filename = as.character(file)) %>%
    relocate(mwi_filename, excel_filename)
 
    df_out <- bind_rows(df_out, dat)
  }

  return(df_out)
}
