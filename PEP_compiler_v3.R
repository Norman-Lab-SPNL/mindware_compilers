suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(tools)
})

# Core compiler that can extract one or MANY metrics into long, then pivots wide by metric
compile_impedance_long <- function(directory = getwd(),
                                   sheet = "Impedance Stats",
                                   metrics = c("PEP")) {
  directory <- normalizePath(directory, mustWork = FALSE)
  files <- list.files(directory, pattern = "\\.xlsx$", full.names = TRUE)
  if (length(files) == 0) {
    warning("No .xlsx files found in: ", directory)
    return(tibble(filename = character(), Segment = integer()))
  }
  
  purrr::map_dfr(files, function(f) {
    df <- tryCatch(read_excel(f, sheet = sheet),
                   error = function(e) {
                     warning(sprintf("Skipping %s (cannot read sheet '%s'): %s",
                                     basename(f), sheet, e$message))
                     return(NULL)
                   })
    if (is.null(df) || ncol(df) < 2) return(NULL)
    
    names(df)[1] <- "Metric"
    
    long <- df %>%
      mutate(Metric = trimws(as.character(Metric))) %>%
      pivot_longer(cols = -Metric, names_to = "Segment", values_to = "value") %>%
      mutate(
        Segment = suppressWarnings(as.integer(as.character(Segment))),
        value   = suppressWarnings(as.numeric(value))
      ) %>%
      filter(!is.na(Segment), Metric %in% metrics)
    
    # Wide by metric: one row per filename x segment, columns per requested metric
    out <- long %>%
      select(Metric, Segment, value) %>%
      pivot_wider(names_from = Metric, values_from = value) %>%
      mutate(filename = file_path_sans_ext(basename(f))) %>%
      relocate(filename, Segment) %>%
      arrange(filename, Segment)
    
    out
  })
}

# Backward-compatible wrappers ----------------------------------------------

# Old name you might still call in scripts:
compile_pep_long <- function(directory = getwd(),
                             sheet = "Impedance Stats",
                             metric_label = "PEP") {
  compile_impedance_long(directory = directory, sheet = sheet, metrics = c(metric_label))
}

# Fully backward-compatible 'compile(...)' that accepts vars_to_keep like your old code
compile <- function(directory = getwd(),
                    sheet = "Impedance Stats",
                    metric_label = "PEP",
                    vars_to_keep = NULL) {
  # If vars_to_keep is provided, use it; otherwise fall back to single metric_label
  metrics <- if (!is.null(vars_to_keep)) vars_to_keep else c(metric_label)
  compile_impedance_long(directory = directory, sheet = sheet, metrics = metrics)
}

