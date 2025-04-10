


#
# working with FCR data - processing

library(lubridate)
library(readr)
library(ggpubr)
library(openair)
library(REddyProc)
library(ggplot2)
library(dplyr)
library(tidyverse)

# Folder path

folder <- "./Data/DataNotYetUploadedToEDI/EddyFlux_Processing/"

# Create a misc_data_files folder for the downloaded sensor data if one doesn't already exist

misc_folder <-paste0(folder, "misc_data_files")

if (file.exists(misc_folder)) {
  cat("The folder already exists")
} else {
  dir.create(misc_folder)
}


# read compiled file (this is the output from EddyPro)

ecc <- read_csv("./Data/DataNotYetUploadedToEDI/EddyFlux_Processing/Processed_files/eddypro_EDF_091922_full_output_2022-09-23T142136_exp.csv",skip=1)

# Convert date to datetime
# This doesn't seem to work for me
ec$datetime <- as.POSIXct(paste(ec$date, ec$time), format="%Y-%m-%d %H:%M:%S")
ec$datetime <- as_datetime(ec$datetime)

# ABP tries a new way to convert to datetime

ec <- ecc%>%
  unite(., col='datetime', c('date', 'time'), sep=' ')%>%
  mutate(datetime=ymd_hm(datetime))



# convert -9999 to NA
ec[ec == -9999] <- NA

# setting up a new dataframe with complete dates

# change end date every time you run a new file
tail(ec$datetime)

ts <- seq.POSIXt(as.POSIXct("2022-09-05 13:00:00",'%Y-%m-%d %H:%M:%S'),
                 # THis is probably the starting point but commenting it out while tryin the code
  #as.POSIXct("2020-04-04 11:30:00",'%Y-%m-%d %H:%M:%S'), 
                 as.POSIXct("2022-09-19 13:00:00",'%Y-%m-%d %H:%M:%S'), by = "30 min")
ts2 <- data.frame(datetime = ts)


# join dataframes to gapfill missing dates on ec data
ec2 <- left_join(ts2, ec, by = 'datetime')

# Convert most of the columns to numeric
ec2[, c(3:157)] <- sapply(ec2[, c(3:157)], as.numeric)

#################################################################
# count how many initial NAs are in CO2 and CH4 data
#################################################################

ec2 %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100- sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

ec2 %>% group_by(year(datetime), month(datetime)) %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

#################################################################

# reading data from catwalk and from meteorological station at FCR 
# this will be used for gapfilling

# Create folders for data files for processing for Streaming sensors

download.file('https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-metstation-data/FCRmet.csv',paste0(folder, "misc_data_files/FCRmet.csv")) 

metheader<-read.csv(paste0(folder,"misc_data_files/FCRmet.csv"), skip=1, as.is=T) #get header minus wonky Campbell rows
met_s<-read.csv(paste0(folder,"misc_data_files/FCRmet.csv"), skip=4, header=F) #get data minus wonky Campbell rows
names(met_s)<-names(metheader) #combine the names to deal with Campbell logger formatting

met <- met_s %>% mutate(datetime=ymd_hms(TIMESTAMP))%>%
  select(-TIMESTAMP)

# When processing for the manuscript use the EDI dataset API here
# PUT THE API HERE FOR EDI DATA


met <- met %>% dplyr::rename(datetime = date)

# just in case gapfilling dates on met data
met2 <- left_join(ts2, met, by = 'datetime')

# reading catwalk data

# Read in the Streaming Sensor Data
download.file('https://github.com/FLARE-forecast/FCRE-data/raw/fcre-catwalk-data/fcre-waterquality.csv',paste0(folder,'misc_data_files/fcre-waterquality.csv'))


cat<-read_csv(paste0(folder,"misc_data_files/fcre-waterquality.csv"))

cat <- cat %>% dplyr::rename(datetime = TIMESTAMP)

# gapfilling dates on met data
cat2 <- left_join(ts2, cat, by = 'datetime')

# compare wind speeds from met and ec -- if they don't agree, then check that timestamps and timezones of metdata and ec are the same!
plot(ec2$wind_speed)
points(met2$WS_ms_Avg*0.5+0.22, col = 'red')

###########################################

# if there is no wind speed or wind dir data, then enter value from met

ec2$wind_speed <- ifelse(is.na(ec2$wind_speed),
                         met2$WS_ms_Avg*0.5+0.22, ec2$wind_speed)

ec2$wind_dir <- ifelse(is.na(ec2$wind_dir),
                       met2$WindDir, ec2$wind_dir)


ec2 %>% filter(wind_dir >= 250 | wind_dir <= 80) %>% 
  ggplot(aes(wind_dir, wind_speed)) + 
  geom_point() +
  scale_x_continuous(limits = c(0, 360),
                     breaks = seq(0, 360, 45)) +
  coord_polar() + theme_bw() + xlab('Wind direction') + ylab('Wind speed')


# filtering by wind speed to remove areas outside of reservoir
ec_filt <- ec2 %>% dplyr::filter(wind_dir < 80 | wind_dir > 250)

met3 <- met2 %>% dplyr::filter(WindDir < 80 | WindDir > 250)

met4 <- left_join(ts2, met3)

ec_filt <- left_join(ts2, ec_filt)


################################################################
# count NA after filtering for wind speed

ec_filt %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100- sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

ec_filt %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = n() - sum(is.na(co2_flux)),
            ch4_available = n() -sum(is.na(ch4_flux)))

################################################################

# removing large values from co2

plot(ec_filt$co2_flux, ylim = c(-100, 100))

ec_filt$co2_flux <- ifelse(ec_filt$co2_flux > 100 | ec_filt$co2_flux < -70, NA, ec_filt$co2_flux)

# removing qc = 2 for co2

ec_filt$co2_flux <- ifelse(ec_filt$qc_co2_flux >= 2, NA, ec_filt$co2_flux)

# removing large values from ch4

plot(ec_filt$ch4_flux, ylim = c(-0.1, 0.5))

ec_filt$ch4_flux <- ifelse(ec_filt$ch4_flux >= 0.25 | ec_filt$ch4_flux <= -0.1, NA, ec_filt$ch4_flux)

# removing ch4 values when signal strength < 20

ec_filt$ch4_flux <- ifelse(ec_filt$rssi_77_mean < 20, NA, ec_filt$ch4_flux)

# removing qc = 2 for ch4

ec_filt$ch4_flux <- ifelse(ec_filt$qc_ch4_flux >=2, NA, ec_filt$ch4_flux)

# removing CH4 data when it rains

ec_filt$precip <- met2$Rain_mm_Tot

ec_filt$ch4_flux <- ifelse(ec_filt$precip > 0, NA, ec_filt$ch4_flux)

# remove CH4 data when thermocouple was not working (apr 05 - apr 25)

ec_filt$ch4_flux <- ifelse(ec_filt$datetime >= '2021-04-05' & ec_filt$datetime <= '2021-04-25', 
                           NA, ec_filt$ch4_flux)

# removing qc = 2 for H and LE

ec_filt$H <- ifelse(ec_filt$qc_H >= 2, NA, ec_filt$H)
ec_filt$LE <- ifelse(ec_filt$qc_LE >= 2, NA, ec_filt$LE)

ec_filt$H <- ifelse(ec_filt$H >= 200 | ec_filt$H <= -100, NA, ec_filt$H)
plot(ec_filt$H)
ec_filt$LE <- ifelse(ec_filt$LE >= 300 | ec_filt$LE <= -30, NA, ec_filt$LE)
plot(ec_filt$LE)

# Plotting co2 and ch4 to see if we can filter implausible values

plot(ec_filt$co2_flux, type = 'o')
plot(ec_filt$ch4_flux, type = 'o')


# adding missing dates
head(ec_filt$datetime)
tail(ec_filt$datetime)


eddy_fcr <- left_join(ts2, ec_filt, by = 'datetime')

#######################################################################
# counting data again after filtering by:
# wind speed, qc, rain, unreasonable values, signal strength


eddy_fcr %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

eddy_fcr %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = n() - sum(is.na(co2_flux)),
            ch4_available = n() -sum(is.na(ch4_flux)))


eddy_fcr %>% group_by(year(datetime), month(datetime)) %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

########################################################################

# despike co2 - this is a function to remove spikes from co2 and ch4 data

# Despike NEE
source(paste0(folder,"/despike.R"))

flag <- spike_flag(eddy_fcr$co2_flux,z = 7)
NEE_low <- ifelse(flag == 1, NA, eddy_fcr$co2_flux)
flag <- spike_flag(eddy_fcr$co2_flux,z = 5.5)
NEE_medium <- ifelse(flag == 1, NA, eddy_fcr$co2_flux)
flag <- spike_flag(eddy_fcr$co2_flux,z = 4)
NEE_high <- ifelse(flag == 1, NA, eddy_fcr$co2_flux)

plot(eddy_fcr$datetime,eddy_fcr$co2_flux,xlab = "Date", ylab = "NEE (umol m-2s-1)", col = "gray70")
points(eddy_fcr$datetime,NEE_low,col = "gray10")
points(eddy_fcr$datetime,NEE_medium,col = "blue")
points(eddy_fcr$datetime,NEE_high,col = "red")
abline(h=0)

#use medium despiking to remove outliers
eddy_fcr$NEE.med <- NEE_medium


#Despike CH4 flux
flag <- spike_flag(eddy_fcr$ch4_flux,z = 7)
CH4_low <- ifelse(flag == 1, NA, eddy_fcr$ch4_flux)
flag <- spike_flag(eddy_fcr$ch4_flux,z = 5.5)
CH4_medium <- ifelse(flag == 1, NA, eddy_fcr$ch4_flux)
flag <- spike_flag(eddy_fcr$ch4_flux,z = 4)
CH4_high <- ifelse(flag == 1, NA, eddy_fcr$ch4_flux)


plot(eddy_fcr$datetime,eddy_fcr$ch4_flux,xlab = "Date", ylab = "CH4 (umol m-2s-1)", col = "gray70")
points(eddy_fcr$datetime,CH4_low,col = "gray10")
points(eddy_fcr$datetime,CH4_medium,col = "blue")
points(eddy_fcr$datetime,CH4_high,col = "red")
abline(h=0)


eddy_fcr$ch4.low <- CH4_low
eddy_fcr$ch4.med <- CH4_medium
eddy_fcr$ch4.hig <- CH4_high


##########################################################################


head(eddy_fcr$datetime)
tail(eddy_fcr$datetime)

eddy_fcr$air_temp_celsius <- eddy_fcr$air_temperature - 273.15
eddy_fcr$sonic_temp_celsius <- eddy_fcr$sonic_temperature - 273.15

# Remove bad air temps on 10 Feb to 14 Feb
eddy_fcr$air_temp_celsius <- ifelse(eddy_fcr$datetime >= '2021-02-10' & eddy_fcr$datetime <='2021-02-14' & 
                                      eddy_fcr$air_temp_celsius >= 15, NA, 
                                    eddy_fcr$air_temp_celsius)


eddy_fcr$sonic_temp_celsius <- ifelse(eddy_fcr$datetime >= '2021-02-10' & eddy_fcr$datetime <='2021-02-14' & 
                                        eddy_fcr$sonic_temp_celsius >= 15, NA, 
                                      eddy_fcr$sonic_temp_celsius)


eddy_fcr$air_temp_celsius <- ifelse(is.na(eddy_fcr$air_temp_celsius),
                                    met2$AirTC_Avg, eddy_fcr$air_temp_celsius)


eddy_fcr$sonic_temp_celsius <- ifelse(is.na(eddy_fcr$sonic_temp_celsius),
                                      eddy_fcr$air_temp_celsius, eddy_fcr$sonic_temp_celsius)


plot(eddy_fcr$datetime, eddy_fcr$sonic_temp_celsius)

eddy_fcr$RH <- ifelse(is.na(eddy_fcr$RH),
                      met2$RH, eddy_fcr$RH)

plot(eddy_fcr$datetime, eddy_fcr$RH)

# adding meteorological variables to gapfill data



eddy_fcr$SW_in <- met2$SW_in
eddy_fcr$SW_out <- met2$SW_out
eddy_fcr$par_tot <- met2$PAR_Tot_Tot
eddy_fcr$air_pressure <- met2$BP_kPa_Avg
eddy_fcr$LW_in <- met2$LW_in
eddy_fcr$LW_out <- met2$LW_out
eddy_fcr$albedo <- met2$Albedo_Avg
eddy_fcr$air_pressure <- ifelse(is.na(eddy_fcr$air_pressure), 
                                met2$Pressure, eddy_fcr$air_pressure)

eddy_fcr$VPD <- ifelse(is.na(eddy_fcr$VPD), 
                       fCalcVPDfromRHandTair(rH = eddy_fcr$RH, Tair = eddy_fcr$air_temp_celsius)*100, 
                       eddy_fcr$VPD)

eddy_fcr$par_tot <- ifelse(eddy_fcr$datetime >='2020-07-03' & eddy_fcr$datetime <= '2020-07-22', NA, eddy_fcr$par_tot)

eddy_fcr$wind_dir <- ifelse(is.na(eddy_fcr$wind_dir), met4$WindDir, eddy_fcr$wind_dir)

eddy_fcr$LW_out <- ifelse(eddy_fcr$LW_out <= 360, NA, eddy_fcr$LW_out)


eddy_fcr$LW_out <- ifelse(eddy_fcr$datetime >= '2020-06-22' & eddy_fcr$datetime <= '2020-07-13' & eddy_fcr$LW_out <= 420, NA, eddy_fcr$LW_out)

# get net radiation
eddy_fcr$Rn <- eddy_fcr$SW_in - eddy_fcr$SW_out + eddy_fcr$LW_in - eddy_fcr$LW_out

plot(eddy_fcr$Rn, type = 'o')

plot(eddy_fcr$SW_in)

plot(eddy_fcr$VPD/1000)  # in kpa


###############################################################################
# filter out all the values (x_peak) that are out of the reservoir
# here I am using x_peak but you can use x_80 or x_90 too 

eddy_fcr$footprint_flag <- ifelse(eddy_fcr$wind_dir >= 15 & eddy_fcr$wind_dir <= 90 & eddy_fcr$x_peak >= 40, 1, 
                                  ifelse(eddy_fcr$wind_dir < 15 & eddy_fcr$wind_dir > 327 & eddy_fcr$x_peak > 120, 1,
                                         ifelse(eddy_fcr$wind_dir < 302 & eddy_fcr$wind_dir >= 250 & eddy_fcr$x_peak > 50, 1, 0)))



eddy_fcr_footprint <- eddy_fcr %>% filter(footprint_flag == 0)

eddy_fcr_footprint %>% ggplot(aes(wind_dir, x_peak)) + 
  geom_hline(yintercept = 40, col = 'goldenrod2', lwd = 2) +
  geom_hline(yintercept = 50, col = 'green', lwd = 1.4) +
  geom_hline(yintercept = 100, col = 'blue', lwd = 1.4) +
  geom_hline(yintercept = 120, col = 'gray2', lwd = 1.4) +
  geom_hline(yintercept = 150, col = 'red',lwd = 1.4) +
  geom_point() +
  scale_x_continuous(limits = c(0, 360),
                     breaks = seq(0, 360, 45)) +
  theme_bw() + 
  coord_polar()


# merge with full df

eddy_fcr_footprint_full <- left_join(ts2, eddy_fcr_footprint)

# counting data

eddy_fcr_footprint_full %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

eddy_fcr_footprint_full %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = n() - sum(is.na(co2_flux)),
            ch4_available = n() -sum(is.na(ch4_flux)))


eddy_fcr_footprint_full %>% group_by(year(datetime), month(datetime)) %>% select(datetime, co2_flux, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(co2_flux))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)


######################################################################
# FILTERING BY USTAR AND GAPFILLING
######################################################################

# Setting up a new process on REddyProc

eddy_fcr3 <- eddy_fcr_footprint_full %>% 
  select(DateTime = datetime, daytime, NEE = NEE.med, ch4_flux = ch4.med, VPD, 
         H, LE, Tair = sonic_temp_celsius, rH = RH, Ustar = `u*`, u = wind_speed, 
         pressure = air_pressure, L, z_d_L = `(z-d)/L`, sigma_v = v_var, 
         precip, Rn, SW_in, SW_out, LW_out, LW_in, albedo, par_tot, wind_dir, 
         airP = air_pressure) %>% 
  mutate(VPD = VPD/100,
         z_d = z_d_L*L,
         ln_z_d = log(z_d)) %>% 
  rename(Rg = SW_in,
         PAR = par_tot)


########################################################################
# count available data before gapfilling


eddy_fcr3 %>% select(DateTime, NEE, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(NEE))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

eddy_fcr3 %>% select(DateTime, NEE, ch4_flux) %>% 
  summarise(co2_available = n()-sum(is.na(NEE)),
            ch4_available = n()-sum(is.na(ch4_flux)))

eddy_fcr3 %>% group_by(year(DateTime), month(DateTime)) %>% 
  select(DateTime, NEE, ch4_flux) %>% 
  summarise(co2_available = 100-sum(is.na(NEE))/n()*100,
            ch4_available = 100-sum(is.na(ch4_flux))/n()*100)

windRose(mydata = eddy_fcr3, ws = "u", wd = "wind_dir", 
         width = 3, key.position = 'bottom', 
         offset = 3, paddle = FALSE, key.header = 'Wind speed (m/s)', 
         key.footer = ' ', dig.lab = 2, annotate = FALSE,
         angle.scale = 45, ws.int = 1, breaks = c(0, 2, 4, 6, 8))


###########################################################################
# get ustar distribution and filter by ustar
###########################################################################

Eproc <- sEddyProc$new('FCR', eddy_fcr3, c('NEE','Tair', 'VPD',
                                           'rH','H', 'LE', 'Ustar', 
                                           'ch4_flux', 'u', 'PAR', 
                                           'SW_out', 'Rg', 
                                           'Rn', 'LW_out', 'LW_in'))

# gapfill air temperature, solar radiation, par, H and LE
Eproc$sMDSGapFill('Tair', V1 = 'Rg', V2 = 'VPD')
Eproc$sMDSGapFill('Rg',  V2 = 'VPD', V3 = 'Tair')
Eproc$sMDSGapFill('PAR', V1 = 'Rg', V2 = 'VPD', V3 = 'Tair')
Eproc$sMDSGapFill('Rn', V1 = 'Rg', V2 = 'VPD', V3 = 'Tair')
Eproc$sMDSGapFill('H', V1 = 'Rg', V2 = 'VPD', V3 = 'Tair')
Eproc$sMDSGapFill('LE', V1 = 'Rg', V2 = 'VPD', V3 = 'Tair')

# estimate ustar threshold distribution by bootstrapping the data

Eproc$sEstimateUstarScenarios(UstarColName = 'Ustar', NEEColName = 'NEE', RgColName= 'Rg',
                              nSample = 200L, probs = c(0.05, 0.5, 0.95))

Eproc$sGetUstarScenarios()

Eproc$sMDSGapFillUStarScens(fluxVar = 'NEE')
Eproc$sMDSGapFillUStarScens(fluxVar = 'ch4_flux')


# exporting results

filled_fcr <- Eproc$sExportResults()
fcr_gf <- cbind(eddy_fcr3, filled_fcr)


fcr_gf %>% ggplot() + 
  geom_line(aes(DateTime, ch4_flux_uStar_orig)) +
  geom_line(aes(DateTime, ch4_flux_uStar_f), col = 'red', alpha = 0.3) +
  theme_bw() +
  xlab("") + ylab(expression(~CH[4]~flux~(mu~mol~m^-2~s^-1)))

fcr_gf %>% ggplot() +
  geom_line(aes(DateTime, NEE)) +
  geom_line(aes(DateTime, NEE_uStar_f), col='red', alpha = 0.3) +
  theme_bw() +
  xlab("") + ylab(expression(~CO[2]~flux~(mu~mol~m^-2~s^-1)))



# saving the data 

write_csv(fcr_gf, "C:/Users/Panasonic/Documents/Falling creek reservoir data/processed_data_upto_2021-05-06.csv")
