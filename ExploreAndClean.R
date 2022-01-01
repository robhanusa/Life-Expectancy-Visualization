library(tidyverse)
library(reshape)

dfRawData <- read.csv('WorldBankHealthData.csv')

#check what countries are included
print(sort(unique(dfRawData$country_name)))

#Upon reviewing, the following entries are not countries, and will be removed
#non_countries----
non_contries <- c("Africa Eastern and Southern",
                  "Africa Western and Central",
                  "Arab World",
                  "Caribbean small states",
                  "Central Europe and the Baltics",
                  "Early-demographic dividend",                     
                  "East Asia & Pacific",                         
                  "East Asia & Pacific (excluding high income)",         
                  "East Asia & Pacific (IDA & IBRD countries)",
                  "Euro area",         
                  "Europe & Central Asia",                               
                  "Europe & Central Asia (excluding high income)",       
                  "Europe & Central Asia (IDA & IBRD countries)",      
                  "European Union",
                  "Fragile and conflict affected situations", 
                  "Heavily indebted poor countries (HIPC)",           
                  "High income",
                  "IDA & IBRD total", 
                  "Late-demographic dividend",                           
                  "Latin America & Caribbean",                          
                  "Latin America & Caribbean (excluding high income)",   
                  "Latin America & the Caribbean (IDA & IBRD countries)",
                  "Least developed countries: UN classification",
                  "Low & middle income",       
                  "Low income",                                
                  "Lower middle income", 
                  "Middle East & North Africa",                          
                  "Middle East & North Africa (excluding high income)",  
                  "Middle East & North Africa (IDA & IBRD countries)", 
                  "Middle income",
                  "North America",
                  "OECD members",
                  "Other small states",                                  
                  "Pacific island small states", 
                  "Post-demographic dividend",                        
                  "Pre-demographic dividend",
                  "Small states",
                  "South Asia",                                       
                  "South Asia (IDA & IBRD)", 
                  "Sub-Saharan Africa",                            
                  "Sub-Saharan Africa (excluding high income)",          
                  "Sub-Saharan Africa (IDA & IBRD countries)",
                  "Upper middle income",
                  "World")

#Remove non-countries----
df <- dfRawData[!(dfRawData$country_name %in% non_contries), ]

#Check for completeness of full dataset----
#We expect 6 values per country per year.
df_count <- count(df,country_name,year)

#The output below makes it clear there is a lot of missing data. Since
#excluding countries or years with incomplete data would greatly reduce the
#dataset, absent values will just have to be dealt with

#Check completeness of life expectancy data----
#This is the most important variable, so we'll use the image() function to see
#the extent of missing life expectancy data.

#filter for only life expectancy values
df_LE <- df[df$indicator_name == 'Life expectancy at birth, total (years)', ]

#create wide df of life expectancy values
df_LE_wide <- cast(df_LE, country_name~year)

#convert to a df with 1 if value exists, otherwise 0 if NA. Exclude country_name column
df_binary <- df_LE_wide
df_binary[is.na(df_binary)] <- 0
df_binary[, names(df_binary) != 'country_name'][df_binary[, names(df_binary) != 'country_name'] > 0] <- 1

#convert to matrix, so it can be input into an image.
df_binary <- column_to_rownames(df_binary, 'country_name')
mat_binary <- as.matrix(df_binary)

#Make image of density of life expectancy values----
image(z = mat_binary)

#We can see that most countries (x axis) have most or all of the life expectancy
#data. However, there are a few that have very little. It wouldn't make sense to 
#allow the user to graph these, so we'll filter out all countries from the data set
#that have < 50% (25 years worth) of data
#To do this, I'll sum up every row of the binary df, and remove countries whose
#sum is less than 25

#Determine countries with <50% (25 total) life expectancy values----

#tidy data
df_binary2 <- rownames_to_column(df_binary,'country_name')
df_gathered <- gather(df_binary2,'year','value',2:ncol(df_binary2))

#summarize by sum
df_summed <- aggregate(df_gathered$value, 
                       by = list(country_name = df_gathered$country_name), 
                       FUN = sum)

#filter for countries with < 25 data points
df_lowInfo <- df_summed[df_summed$x < 25, ]

#extract list of countries to remove
countries_to_remove <- c(df_lowInfo$country_name)
