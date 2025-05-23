# R Script to QA_QC Metals Chemistry dataset for EDI publication
# Authors: Nick Hammond
# Last Edited: 01/18/2023

# NOTE: Certain aspects of the data cleaning process were done manually in Excel. We
# are working to automate the process entirely, but at this stage some tasks must
# be performed manually. These tasks include:
# - Copying data from analytical lab report to Excel spreadsheet
# - Inputting sampling times into spreadsheet
# Automated tasks include:
# - Assigning flags when 1. No samples were collected, 2. Instrument malfunctions,
# 7. samples run multiple times and averaged, and 8. sample values are outside of expected range.
# - Sorting raw data into SFe, SMn, TMn and TFe columns 
# - Assigning depths and sites to metals concentrations based on sample ID


# QA_QC Steps:
# 1. Format data properly
# 2. Ensure Dataset completeness (check for gaps in data)
# 3. Check for outliers (identify data outside of expected range)
# 4. Identify spikes (anomalous increases/decreases in data)
# 5. Check for data points where solubles > totals (may indicate sampling error)
# 6. Plot to visualize

#Set working directory, load packages
#install.packages("tidyverse","readxl","lubridate")
library(tidyverse)
library(readxl)
library(lubridate)
#setwd("C:/FCR_BVR Metals Data/EDI")

##generate site description csv file for EDI 
#Install the required googlesheets4 package
#install.packages('googlesheets4')
#Load the library 
library(googlesheets4)
sites <- read_sheet('https://docs.google.com/spreadsheets/d/1TlQRdjmi_lzwFfQ6Ovv1CAozmCEkHumDmbg_L4A2e-8/edit?usp=sharing')
data<- read_csv("Metals_2014_2022.csv") 
trim_sites = function(data,sites){
  data_res_site=data%>% #Create a Reservoir/Site combo column
    mutate(res_site = trimws(paste0(Reservoir,Site)))
  sites_merged = sites%>% #Filter to Sites that are in the dataframe
    mutate(res_site = trimws(paste0(Reservoir,Site)))%>%
    filter(res_site%in%data_res_site$res_site)%>%
    select(-res_site)
}
sites_trimmed = trim_sites(data,sites) 
write.csv(sites_trimmed,"site_descriptions.csv", row.names=F)# Write to file



# load in dataset
metals <- read_csv("Metals_2014_2022.csv") %>%
  mutate(DateTime = ymd_hms(DateTime))

# 1. check data format
str(metals)

# format columns as numeric, if necessary
metals <- metals %>% 
  mutate(TFe_mgL = as.numeric(TFe_mgL)) %>%
  mutate(TMn_mgL = as.numeric(TMn_mgL)) %>%
  mutate(SFe_mgL = as.numeric(SFe_mgL)) %>%
  mutate(SMn_mgL = as.numeric(SMn_mgL))

# Subset to just current year's data
metals_current <- metals %>% subset(DateTime > ymd_hms("2022-01-01 00:00:00"))

# subset by reservoir
FCR <- metals_current %>% filter(Reservoir=="FCR")
  
BVR <- metals_current %>% filter(Reservoir=="BVR")

#subset by sampling site
INFLOW <- FCR %>% filter(Site==100)
WETLAND <- FCR %>% filter(Site==200)
FCR <- FCR %>% filter(Site==50)


# 2. Ensure Dataset completeness (check for gaps in data)

# Identify gaps in data greater than 3 weeks
# For each gap, go into the spreadsheet and make sure no data is missing
#FCR 50
for(i in 2:nrow(FCR)){
  time1 = FCR$DateTime[i-1]
  time2 = FCR$DateTime[i]
  int = interval(time1,time2)
  if(int_length(int) > (3*7*24*60*60)){
    print(int)
  }
}

#FCR INFLOW
for(i in 2:nrow(INFLOW)){
  time1 = INFLOW$DateTime[i-1]
  time2 = INFLOW$DateTime[i]
  int = interval(time1,time2)
  if(int_length(int) > (3*7*24*60*60)){
    print(int)
  }
}

#BVR
for(i in 2:nrow(BVR)){
  time1 = BVR$DateTime[i-1]
  time2 = BVR$DateTime[i]
  int = interval(time1,time2)
  if(int_length(int) > (3*7*24*60*60)){
    print(int)
  }
}


# 3. Check for outliers (identify data outside of expected range)

# I'm struggling a bit to find a good way to identify outliers, since there are
# numerous data points outside the IQR and/or 5*sd that are correct.
# Right now I am just identifying data points outside the expected range,
# based on knowledge of the system (0-40 mg/L for Fe, 0-4 mg/L for Mn)

# Identify values outside of expected range
Fe.range.check <- metals_current %>%
  filter(TFe_mgL > 40 | SFe_mgL > 40)
Fe.range.check

Mn.range.check <- metals_current %>%
  filter(TMn_mgL > 4 | SMn_mgL > 4)
Mn.range.check

# FCR TFe
boxplot(TFe_mgL~as.factor(Depth_m),data = FCR)
summary(FCR$TFe_mgL)
# FCR SFe
boxplot(SFe_mgL~as.factor(Depth_m),data = FCR)
summary(FCR$SFe_mgL)
# FCR TMn
boxplot(TMn_mgL~as.factor(Depth_m),data = FCR)
summary(FCR$TMn_mgL)
# FCR SMn
boxplot(SMn_mgL~as.factor(Depth_m),data = FCR)
summary(FCR$SMn_mgL)


# BVR TFe
boxplot(TFe_mgL~as.factor(Depth_m),data = BVR)
summary(BVR$TFe_mgL)
# BVR SFe
boxplot(SFe_mgL~as.factor(Depth_m),data = BVR)
summary(BVR$SFe_mgL)
# BVR TMn
boxplot(TMn_mgL~as.factor(Depth_m),data = BVR)
summary(BVR$TMn_mgL)
# BVR SMn
boxplot(SMn_mgL~as.factor(Depth_m),data = BVR)
summary(BVR$SMn_mgL)

# INFLOW TFe
boxplot(TFe_mgL~as.factor(Depth_m),data = INFLOW)
summary(INFLOW$TFe_mgL)
# INFLOW SFe
boxplot(SFe_mgL~as.factor(Depth_m),data = INFLOW)
summary(INFLOW$SFe_mgL)
# INFLOW TMn
boxplot(TMn_mgL~as.factor(Depth_m),data = INFLOW)
summary(INFLOW$TMn_mgL)
# INFLOW SMn
boxplot(SMn_mgL~as.factor(Depth_m),data = INFLOW)
summary(INFLOW$SMn_mgL)

# WETLAND TFe
boxplot(TFe_mgL~as.factor(Depth_m),data = WETLAND)
summary(WETLAND$TFe_mgL)
# WETLAND SFe
boxplot(SFe_mgL~as.factor(Depth_m),data = WETLAND)
summary(WETLAND$SFe_mgL)
# WETLAND TMn
boxplot(TMn_mgL~as.factor(Depth_m),data = WETLAND)
summary(WETLAND$TMn_mgL)
# WETLAND SMn
boxplot(SMn_mgL~as.factor(Depth_m),data = WETLAND)
summary(WETLAND$SMn_mgL)


# 4. Identify spikes (anomalous increases/decreases in data)
#FCR
FCR_by_depth = FCR %>% 
  group_by(Depth_m) %>% 
  arrange(DateTime, by_group=TRUE) %>%
  mutate(Change_TFe = TFe_mgL - lag(TFe_mgL,n=1)) %>%
  mutate(Change_SFe = SFe_mgL - lag(SFe_mgL,n=1)) %>%
  mutate(Change_TMn = TMn_mgL - lag(TMn_mgL,n=1)) %>%
  mutate(Change_SMn = SMn_mgL - lag(SMn_mgL,n=1))
  
#Compile list of all spikes greater than 15 mg/L (Fe) or 2 mg/L (Mn)
check.change.Fe <- FCR_by_depth %>%
  filter(Change_TFe > 15 | Change_SFe > 15)
check.change.Fe

check.change.Mn <- FCR_by_depth %>%
  filter(Change_TMn > 2 | Change_SMn > 2)
check.change.Mn

#Plot time series of concentration changes 
ggplot(FCR_by_depth, aes(x=DateTime,y=Change_TFe))+
  geom_path()
ggplot(FCR_by_depth, aes(x=DateTime,y=Change_SFe))+
  geom_path()
ggplot(FCR_by_depth, aes(x=DateTime,y=Change_TMn))+
  geom_path()
ggplot(FCR_by_depth, aes(x=DateTime,y=Change_SMn))+
  geom_path()

#BVR
BVR_by_depth = BVR %>% 
  group_by(Depth_m) %>% 
  arrange(DateTime, by_group=TRUE) %>%
  mutate(Change_TFe = TFe_mgL - lag(TFe_mgL,n=1)) %>%
  mutate(Change_SFe = SFe_mgL - lag(SFe_mgL,n=1)) %>%
  mutate(Change_TMn = TMn_mgL - lag(TMn_mgL,n=1)) %>%
  mutate(Change_SMn = SMn_mgL - lag(SMn_mgL,n=1))

#Compile list of all spikes greater than 15 mg/L (Fe) or 2 mg/L (Mn)
check.change.Fe.B <- BVR_by_depth %>%
  filter(Change_TFe > 15 | Change_SFe > 15)
check.change.Fe.B

check.change.Mn.B <- BVR_by_depth %>%
  filter(Change_TMn > 2 | Change_SMn > 2)
check.change.Mn.B

#Plot time series of concentration changes
ggplot(BVR_by_depth, aes(x=DateTime,y=Change_TFe))+
  geom_path()
ggplot(BVR_by_depth, aes(x=DateTime,y=Change_SFe))+
  geom_path()
ggplot(BVR_by_depth, aes(x=DateTime,y=Change_TMn))+
  geom_path()
ggplot(BVR_by_depth, aes(x=DateTime,y=Change_SMn))+
  geom_path()

# 5. Check for data points where solubles > totals (may indicate sampling error)
metals_diff = metals_current %>% mutate(Fe_diff=TFe_mgL - SFe_mgL)%>%
  mutate(Mn_diff = TMn_mgL - SMn_mgL)%>%
  filter(Fe_diff< -1 | Mn_diff< -1)
metals_diff

# 6. Plot to visualize

#Adding a column for Year just for plotting purposes
FCR <- FCR %>%
  mutate(Year = year(DateTime))
BVR <- BVR %>%
  mutate(Year = year(DateTime))

#FCR TFe
TFe_plot=ggplot(FCR, aes(x =DateTime, y = TFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#FCR TMn
TMn_plot=ggplot(FCR, aes(x =DateTime, y = TMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#FCR SFe
SFe_plot=ggplot(FCR, aes(x =DateTime, y = SFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#FCR SMn
SMn_plot=ggplot(FCR, aes(x =DateTime, y = SMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SMn_plot


#BVR TFe
TFe_plot=ggplot(BVR, aes(x =DateTime, y = TFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#BVR TMn
TMn_plot=ggplot(BVR, aes(x =DateTime, y = TMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#BVR SFe
SFe_plot=ggplot(BVR, aes(x =DateTime, y = SFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#BVR SMn
SMn_plot=ggplot(BVR, aes(x =DateTime, y = SMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SMn_plot


#INFLOW TFe
TFe_plot=ggplot(INFLOW, aes(x =DateTime, y = TFe_mgL)) +
  geom_path(size = 0.7)
TFe_plot

#INFLOW TMn
TMn_plot=ggplot(INFLOW, aes(x =DateTime, y = TMn_mgL)) +
  geom_path(size = 0.7)
TMn_plot

#INFLOW SFe
SFe_plot=ggplot(INFLOW, aes(x =DateTime, y = SFe_mgL)) +
  geom_path(size = 0.7)
SFe_plot

#INFLOW SMn
SMn_plot=ggplot(INFLOW, aes(x =DateTime, y = SMn_mgL)) +
  geom_path(size = 0.7)
SMn_plot


#WETLAND TFe
TFe_plot=ggplot(WETLAND, aes(x =DateTime, y = TFe_mgL)) +
  geom_path(size = 0.7)
TFe_plot

#WETLAND TMn
TMn_plot=ggplot(WETLAND, aes(x =DateTime, y = TMn_mgL)) +
  geom_path(size = 0.7)
TMn_plot

#WETLAND SFe
SFe_plot=ggplot(WETLAND, aes(x =DateTime, y = SFe_mgL)) +
  geom_path(size = 0.7)
SFe_plot

#WETLAND SMn
SMn_plot=ggplot(WETLAND, aes(x =DateTime, y = SMn_mgL)) +
  geom_path(size = 0.7)
SMn_plot

### Now let's plot the entire time series for one last check ###

# subset by reservoir
FCR <- metals %>% filter(Reservoir=="FCR")

BVR <- metals %>% filter(Reservoir=="BVR")

#subset by sampling site
INFLOW <- FCR %>% filter(Site==100)
WETLAND <- FCR %>% filter(Site==200)
FCR <- FCR %>% filter(Site==50)

#Adding a column for Year just for plotting purposes
FCR <- FCR %>%
  mutate(Year = year(DateTime))
BVR <- BVR %>%
  mutate(Year = year(DateTime))
INFLOW <- INFLOW %>%
  mutate(Year = year(DateTime))
WETLAND <- WETLAND %>%
  mutate(Year = year(DateTime))

#FCR TFe
TFe_plot=ggplot(FCR, aes(x =DateTime, y = TFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#FCR TMn
TMn_plot=ggplot(FCR, aes(x =DateTime, y = TMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#FCR SFe
SFe_plot=ggplot(FCR, aes(x =DateTime, y = SFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#FCR SMn
SMn_plot=ggplot(FCR, aes(x =DateTime, y = SMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SMn_plot


#BVR TFe
TFe_plot=ggplot(BVR, aes(x =DateTime, y = TFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#BVR TMn
TMn_plot=ggplot(BVR, aes(x =DateTime, y = TMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#BVR SFe
SFe_plot=ggplot(BVR, aes(x =DateTime, y = SFe_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#BVR SMn
SMn_plot=ggplot(BVR, aes(x =DateTime, y = SMn_mgL, colour = as.factor(Depth_m))) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SMn_plot


#INFLOW TFe
TFe_plot=ggplot(INFLOW, aes(x =DateTime, y = TFe_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#INFLOW TMn
TMn_plot=ggplot(INFLOW, aes(x =DateTime, y = TMn_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#INFLOW SFe
SFe_plot=ggplot(INFLOW, aes(x =DateTime, y = SFe_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#INFLOW SMn
SMn_plot=ggplot(INFLOW, aes(x =DateTime, y = SMn_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SMn_plot


#WETLAND TFe
TFe_plot=ggplot(WETLAND, aes(x =DateTime, y = TFe_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TFe_plot

#WETLAND TMn
TMn_plot=ggplot(WETLAND, aes(x =DateTime, y = TMn_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
TMn_plot

#WETLAND SFe
SFe_plot=ggplot(WETLAND, aes(x =DateTime, y = SFe_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
  geom_path(size = 0.7)
SFe_plot

#WETLAND SMn
SMn_plot=ggplot(WETLAND, aes(x =DateTime, y = SMn_mgL)) +
  facet_wrap(~Year,nrow = 2,scales = "free_x")+
   geom_path(size = 0.7)
SMn_plot

# If everything looks good, write to csv
write_csv(metals,paste0(getwd(),"/Metals_EDI.csv"))


# 1. Make sure data is properly flagged
# Flags 1 (sample not taken), 2 (instrument malfunction), and 3 (negative value set to 0) were manually input

# Assign MDL flags to 2020 data
# Add flags for values below the MDL (0.005 mg/L for Fe and 0.0001 mg/L for Mn)
# missing = "Flag_X" keeps the original values
metals_2020 <- metals_2020 %>%
  mutate(Flag_TFe= if_else(TFe_mgL<0.005 & TFe_mgL>0,3,Flag_TFe, missing = Flag_TFe))%>% # Flag 3 for below MDL
  mutate(Flag_SFe= if_else(SFe_mgL<0.005 & SFe_mgL>0,3,Flag_SFe, missing = Flag_SFe)) %>% # Flag 3 for below MDL
  mutate(Flag_TMn= if_else(TMn_mgL<0.0001 & TMn_mgL>0,3,Flag_TMn, missing = Flag_TMn))%>% # Flag 3 for below MDL
  mutate(Flag_SMn= if_else(SMn_mgL<0.0001 & SMn_mgL>0,3,Flag_SMn, missing = Flag_SMn)) # Flag 3 for below MDL

below = metals %>% filter(TFe_mgL<0.005|SFe_mgL<0.005|TMn_mgL<0.0001|SMn_mgL<0.0001)

mutate(Flag_TFe= if_else(TFe_mgL<0,4,0, missing = Flag_TFe))%>% # Flag 4 for negative value set to 0
  mutate(Flag_SFe= if_else(SFe_mgL<0,4,0, missing = Flag_SFe))%>%  # Flag 4 for negative value set to 0
  mutate(Flag_TMn= if_else(TMn_mgL<0,4,0, missing = Flag_TMn))%>%  # Flag 4 for negative value set to 0
  mutate(Flag_SMn= if_else(SMn_mgL<0,4,0, missing = Flag_SMn)) # Flag 4 for negative value set to 0
