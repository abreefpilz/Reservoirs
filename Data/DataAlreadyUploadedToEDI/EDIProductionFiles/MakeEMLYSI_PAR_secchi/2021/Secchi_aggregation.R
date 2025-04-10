# Script to pull in Secchi data from multiple reservoirs and years ####
 
#install.packages('pacman') ## Run this line if you don't have "pacman" package installed
pacman::p_load(tidyverse, lubridate) ## Use pacman package to install/load other packages

#### Secchi depths ####

# read in new data file
raw_secchi <- read_csv(file.path("/Users/heatherwander/Documents/VirginiaTech/research/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLYSI_PAR_secchi/2021/2021_Secchi_depth.csv"))

#date format
raw_secchi$DateTime <- as.POSIXct(strptime(raw_secchi$DateTime, "%m/%d/%y %H:%M"))
raw_secchi$Flag_DateTime <- NA

secchi <- raw_secchi %>%
  # Omit rows where all Secchi values NA (e.g., rows from files with trailing ,'s)
  filter(!is.na(Secchi_m) ) %>%
  
  # Add 'flag' columns for each variable; 1 = flag 
  mutate(Flag_Secchi = ifelse(is.na(Secchi_m), 1, 0), # Flag for night sampling
         Flag_DateTime = ifelse(Notes=="time not recorded", 1, 0))  %>%  
  
  # Arrange order of columns for final data table
  select(Reservoir, Site, DateTime, Secchi_m, Flag_DateTime, Flag_Secchi) %>%
  arrange(Reservoir, DateTime, .by_group = TRUE ) 

#replce NA in flag col with 0
secchi[is.na(secchi)] <- 0

# Write to CSV (using write.csv for now; want ISO format embedded?)
write.csv(secchi, file.path(getwd(),'Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLYSI_PAR_secchi/2021/2021_Secchi_depth_final.csv'), row.names=F)
  
#------------------------------------------------------------------------------#
#### Secchi diagnostic plots #### 
secchi_long <- secchi %>%
  mutate(year = as.factor(year(DateTime)), day = yday(DateTime))

# Plot range of values per year for each reservoir; 
# annual mean value indicated with large black dot
ggplot(secchi_long, aes(x = year, y = Secchi_m, col=Reservoir)) +
  geom_point(size=1) +
  stat_summary(fun.y="mean", geom="point",pch=21,  size=3, fill='black') +
  facet_grid(. ~ Reservoir, scales= 'free_x') +
  scale_x_discrete("Date", breaks=seq(2013,2019,1)) +
  scale_y_continuous("Secchi depth (m)", breaks=seq(0,15,3), limits=c(0,15)) +
  theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position='none')

# All reservoirs time series 
#jpeg("Secchi_months.jpg", width = 6, height = 5, units = "in",res = 300)
ggplot(secchi_long, aes(x = DateTime, y = Secchi_m, col=Reservoir)) +
  geom_point(size=1) +
  facet_grid(. ~ Reservoir, scales= 'free_x') +
  scale_x_datetime("Date", date_breaks= "6 months", date_labels = "%b %Y") +
  scale_y_continuous("Secchi depth (m)", breaks=seq(0,15,3), limits=c(0,15)) +
  theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position='none')
#dev.off()

# Time series for each reservoir by julian day (see interannual varaibility)
#jpeg("Secchi_JulianDay.jpg", width = 6, height = 5, units = "in",res = 300)
ggplot(secchi_long, aes(x = day, y = Secchi_m)) +
  geom_point(size=2) + 
  facet_grid(Reservoir ~ ., scales= 'free_y') +
  scale_x_continuous("Julian day", limits=c(10,315), breaks=seq(50,300,50))+
  scale_y_continuous("Secchi depth (m)") +
  theme(axis.text.x = element_text(angle = 45, hjust=1), legend.position='bottom')

secchi_old <- read_csv(file.path("/Users/heatherwander/Documents/VirginiaTech/research/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLYSI_PAR_secchi/2020/Secchi_depth_2013-2020.csv"))
secchi_new <- read_csv(file.path("/Users/heatherwander/Documents/VirginiaTech/research/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLYSI_PAR_secchi/2021/2021_Secchi_depth_final.csv"))

#add Flag_DateTime to old secchi
secchi_old$Flag_DateTime <- ifelse(hour(secchi_old$DateTime)==12 & minute(secchi_old$DateTime)==0,1,0)

secchi <- rbind(secchi_old,secchi_new)

# Arrange order of columns for final data table
secchi <- secchi %>% select(Reservoir, Site, DateTime, Secchi_m, Flag_DateTime, Flag_Secchi) %>%
  arrange(Reservoir, DateTime) 

write.csv(secchi,file.path("/Users/heatherwander/Documents/VirginiaTech/research/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLYSI_PAR_secchi/2021/Secchi_depth_2013-2021.csv"), row.names=FALSE)

#### secchi diagnostic plots ####
secchi_long <- secchi %>% 
  gather(metric, value, Secchi_m) %>% 
  mutate(month = strftime(DateTime, "%b")) %>%
  mutate(DateTime = as.Date(DateTime))

ggplot(secchi_long, aes(x=DateTime, y=value )) +
  facet_wrap(~Reservoir) + geom_point(cex=2) + theme_bw()
