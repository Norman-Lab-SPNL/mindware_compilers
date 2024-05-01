# mindware_compilers
Hi SPNL!

Here are short instructions for how to use the R Mindware Compiler scripts.  

# HRV Compiler  
  
## Step 1  
Ensure all your Mindware files are in a single directory (aka folder) and that the name of each file includes the subject ID.  
  
## Step 2  
Make sure you've installed the following packages as they are dependencies of the compiler. You can install them with `install.packages("<package name>")`.  
  
* `tidyverse`  
* `readxl`  
  
## Step 3  
Call the compiler file by including the following code/chunk in your analysis file:  

`source("HRV_compiler.R")`
  
*Note: Make sure the compiler file is saved to the same directory as your analysis file (or include the full directory address when calling the compiler file in `source()`).*  
  
## Step 4 
Call the compile function. The function takes three arguments:  

* `directory` (optional): If the data files are in a separate folder within the directory (or in a separate directory altogether), you can use this argument to override the default (which is the current working directory).  
*Note: Make sure the directory your data files live in includes no extraneous excel/csv files so they don't get read in by the function against your will.*  
* `vars_to_keep` (optional): a vector of the variables to extract from the data. Default is `c("RSA", "RMSSD")`.  
*Note: If you choose to add extra variables to extract, make sure the names match exactly with the way they appear in the excel files that Mindware spits out so you don't get an error.*  
* `resp_range` (optional): A vector (`c(lower_bound, upper_bound)`) with the lower and upper bounds of the range of acceptable respiration rates (in Hz). The function will check whether respiration rates were collected. The function will return an extra column (`resp_within_range`) with a value of 1 for each segment where the respiration rate is within the `resp_range`, 0 if it is not, or `NA` if the respiration rate was not recorded for that segment. The default is 0.12-0.4 Hz.  
  
Here is the function call with default arguments:  

`full_data_df <- compile()`  
  
Here is the function call calling a subfolder of the current working directory, adding "Mean IBI" to the vector of variables I want to extract, and changing the range for the acceptable respiration rates:  

`full_data_df <- compile(directory = paste0(getwd(), "/HRV_data"), vars_to_keep = c("RSA", "RMSSD", "Mean IBI"), resp_range = c(0.23, 0.56))`  
  
## Step 5  
Now you can save the dataframe with all the subjects' data as a csv file.  

`write_csv(full_data_df, "full_data_df.csv")`
  
# PEP Compiler  
  
## Step 1  
Ensure all your Mindware files are in a single directory (aka folder) and that the name of each file includes the subject ID.  
  
## Step 2  
Make sure you've installed the following packages as they are dependencies of the compiler. You can install them with `install.packages("<package name>")`.  
  
* `tidyverse`  
* `readxl`  
  
## Step 3  
Call the compiler file by including the following code/chunk in your analysis file:  

`source("PEP_compiler.R")`
  
*Note: Make sure the compiler file is saved to the same directory as your analysis file (or include the full directory address when calling the compiler file in `source()`).*  
  
## Step 4 
Call the compile function. The function takes two arguments:  

* `directory` (optional): If the data files are in a separate folder within the directory (or in a separate directory altogether), you can use this argument to override the default (which is the current working directory).  
*Note: Make sure the directory your data files live in includes no extraneous excel/csv files so they don't get read in by the function against your will.*  
* `vars_to_keep` (optional): a vector of the variables to extract from the data. Default is `c("PEP")`.  
*Note: If you choose to add extra variables to extract, make sure the names match exactly with the way they appear in the excel files that Mindware spits out so you don't get an error.*  
  
Here is the function call with default arguments:  
`full_data_df <- compile()`  
  
Here is the function call calling a subfolder of the current working directory and adding "Mean IBI" to the vector of variables I want to extract:  
`full_data_df <- compile(directory = paste0(getwd(), "/PEP_data"), vars_to_keep = c("PEP", "Mean IBI"))`  
  
## Step 5  
Now you can save the dataframe with all the subjects' data as a csv file.  

`write_csv(full_data_df, "full_data_df.csv")`
  

  
