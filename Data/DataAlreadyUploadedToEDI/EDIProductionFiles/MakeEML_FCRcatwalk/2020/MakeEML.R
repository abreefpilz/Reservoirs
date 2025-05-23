# 11-Jan-2021 
# Script written by WW


# helpful hints for yearly updating of catwalk dataset and publishing to EDI
# 1. make a new folder for this year, e.g. '2020', within Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLCatwalk/2020
# 2. copy all .txt files from the previous year's folder into this folder. You will edit these files to reflect changes for the newest year
#    If you were making a brand new data product you would need to create the metadata file templates following the directions within this
#    script, thanks very much to MEL for writing those up. HOWEVER, if you are appending, as you should be for the catwalk dataset, just copy last year's
#    files and edit them as needed
# 3. download most up to date catwalk data and maintenance log
#    download.file("https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data/CAT_MaintenanceLog.txt",paste0(folder, "/CAT_MaintenanceLog_2020.txt"))
#    download.file("https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data/Catwalk.csv","Catwalk_2020.csv")
# 4. perform QAQC. The QAQC script will be uploaded as one file with the datapackage into EDI
#    QAQC for 2020 is in the script: catwalk_EDI_QAQC_all_variables.R
#    and output file for EDI is Catwalk_EDI_2020.csv

#library(devtools)
#install_github("EDIorg/EMLassemblyline")
library(EMLassemblyline)

folder <- "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLCatwalk/2020"

#### USEFUL DIRECTIONS FROM MEL FOR START TO FINISH EML CREATION FOR NEW DATA PRODUCT
#Step 1: Create a directory for your dataset
#in this case, our directory is Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2020

#Step 2: Move your dataset to the directory - duh.

#Step 3: Create an intellectual rights license
#ours is CCBY

#Step 4: Identify the types of data in your dataset
#need to update which options are supported...not sure what else is
#possible besides "table"

#Step 5: Import the core metadata templates

#THIS IS ONLY NECESSARY FOR A BRAND NEW DATASET!!!!
#if you are just updating a previous dataset, PLEASE save yourself time
#by copy-pasting the metadata files from the previous year's folder 
#(in this case, 2019) into the current year's folder and editing them
#as needed. DON'T CAUSE YOURSELF MORE WORK BY BUILDING FROM SCRATCH!!

#IF you are just appending a new year of data, skip steps 5-12 and instead
#DOUBLE-CHECK all the imported metadata files and edit them as needed

#for our application, we will need to generate all types of metadata
#files except for taxonomic coverage, as we have both continuous and
#categorical variables and want to report our geographic location

# View documentation for these functions
#?template_core_metadata
#?template_table_attributes
#?template_categorical_variables #don't run this till later
#?template_geographic_coverage

# Import templates for our dataset licensed under CCBY, with 1 table.
#template_core_metadata(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
#                       license = "CCBY",
#                       file.type = ".txt",
#                       write.file = TRUE)


#we want empty to be true for this because we don't include lat/long
#as columns within our dataset but would like to provide them
#template_geographic_coverage(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
#                             data.path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
#                             data.table = "FluoroProbe.csv",
#                             empty = TRUE,
#                             write.file = TRUE)



#Step 6: Script your workflow
#that's what this is, silly!

#Step 7: Abstract
#copy-paste the abstract from your Microsoft Word document into abstract.txt
#if you want to check your abstract for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 8: Methods
#copy-paste the methods from your Microsoft Word document into methods.txt
#if you want to check your abstract for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 9: Additional information
#nothing mandatory for Carey Lab in this section but I use it for the notes
#about whole-ecosystem manipulations in FCR

#Step 10: Keywords
#DO NOT EDIT KEYWORDS FILE USING A TEXT EDITOR!! USE EXCEL!!
#see the LabKeywords.txt file for keywords that are mandatory for all Carey Lab data products

#Step 11: Personnel
#copy-paste this information in from your metadata document
#Cayelan needs to be listed several times; she has to be listed separately for her roles as
#PI, creator, and contact, and also separately for each separate funding source (!!)

#Step 12: Attributes
#grab attribute names and definitions from your metadata word document
#for units....
# View and search the standard units dictionary
view_unit_dictionary()
#put flag codes and site codes in the definitions cell
# If you've added in any new columns, rerun the template_table_attributes() function
#    To edit the file, open up in excel.
# If you want any of your variables to be categorical, change their class to 'categorical'. Then run the template_categorical_variables()
# function below to create a template
template_table_attributes(path = folder,
                          data.path = folder,
                          data.table = "Catwalk_EDI_2020.csv",
                          write.file = TRUE)
# edit this file in excel

#if you need to make custom units that aren't in the unit dictionary,
#use the customunits.txt file and the directions on the EMLassemblyline Github to do so

#Step 13: Close files
#if all your files aren't closed, sometimes functions don't work

#Step 14: Categorical variables
# Run this function for your dataset
#THIS WILL ONLY WORK once you have filled out the attributes_FluoroProbe.txt and
#identified which variables are categorical
template_categorical_variables(path = folder,
                               data.path = folder,
                               write.file = TRUE)
# edit this file in excel


#Step 15: Geographic coverage
#copy-paste the bounding_boxes.txt file that is Carey Lab specific into your working directory

## Step 16: Obtain a package.id.  ####
# Go to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords.
# These are found in the Google Drive folder regarding making EMLs in the 
# workshop notes from the original May 24, 2018 workshop.

# Select Tools --> Data Package Identifier Reservations and click 
# "Reserve Next Available Identifier"
# A new value will appear in the "Current data package identifier reservations" 
# table (e.g., edi.123)
# Make note of this value, as it will be your package.id below

#Step 17: Make EML
# View documentation for this function
?make_eml

# Run this function
make_eml(path = folder,
         data.path = folder,
         eml.path = folder,
         dataset.title = "Time series of high-frequency sensor data measuring water temperature, dissolved oxygen, pressure, conductivity, 
         specific conductance, total dissolved solids, chlorophyll a, phycocyanin, and fluorescent dissolved organic matter at discrete depths 
         in Falling Creek Reservoir, Virginia, USA in 2018-2020",
         data.table = "Catwalk_EDI_2020.csv",
         other.entity = c('temp_oxy_chla_qaqc.R', 'catwalk_EDI_QAQC_all_variables.R','CAT_MaintenanceLog_2020.txt' ),
         other.entity.description = c('Automated QAQC script', 'Final script to run QAQC', 'Maintenance log for catwalk sensors'),
         data.table.description = "FCR Catwalk Sensor String",
         temporal.coverage = c("2018-07-05", "2020-12-31"),
         #geographic.description = "Southwestern Virginia, USA, North America",
         #geographic.coordinates = c("37.309589","-79.836009","37.30266","-79.839249"),
         maintenance.description = "ongoing",
         user.id =  "ccarey",
         package.id = "edi.85.7", #### this is the one that I need to change!!!
         user.domain = 'EDI')
## Step 8: Check your data product! ####
# Return to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords. 

# Select Tools --> Evaluate/Upload Data Packages, then under "EML Metadata File", 
# choose your metadata (.xml) file (e.g., edi.270.1.xml), check "I want to 
# manually upload the data by selecting files on my local system", then click Upload.

# Now, Choose File for each file within the data package (e.g., each zip folder), 
# then click Upload. Files will upload and your EML metadata will be checked 
# for errors. If there are no errors, your data product is now published! 
# If there were errors, click the link to see what they were, then fix errors 
# in the xml file. 
# Note that each revision results in the xml file increasing one value 
# (e.g., edi.270.1, edi.270.2, etc). Re-upload your fixed files to complete the 
# evaluation check again, until you receive a message with no errors.

## Step 9: PUBLISH YOUR DATA! ####
# using the package ID associated with the catwalk dataset, increase the end digit by 1
# e.g. edi.271.4 -> edi.271.5

# In the make_eml command below, change the package.id to match your 
# PUBLISHED package id. This id should end in .1 (e.g., edi.518.1)

# ALL OTHER entries in the make_eml() command should match what you ran above,
# in step 7

make_eml(path = folder,
         data.path = folder,
         eml.path = folder,
         dataset.title = "Time series of high-frequency sensor data measuring water temperature, dissolved oxygen, pressure, conductivity, 
         specific conductance, total dissolved solids, chlorophyll a, phycocyanin, and fluorescent dissolved organic matter at discrete depths 
         in Falling Creek Reservoir, Virginia, USA in 2018-2020",
         data.table = "Catwalk_EDI_2020.csv",
         other.entity = c('temp_oxy_chla_qaqc.R', 'catwalk_EDI_QAQC_all_variables.R','CAT_MaintenanceLog_2020.txt' ),
         other.entity.description = c('Automated QAQC script', 'Final script to run QAQC', 'Maintenance log for catwalk sensors'),
         data.table.description = "FCR Catwalk Sensor String",
         temporal.coverage = c("2018-07-05", "2020-12-31"),
         #geographic.description = "Southwestern Virginia, USA, North America",
         #geographic.coordinates = c("37.309589","-79.836009","37.30266","-79.839249"),
         maintenance.description = "ongoing",
         user.id =  "ccarey",
         package.id = "edi.271.5", #### make sure this matches the original catwalk file, which you are just updating, DO NOT RESERVE NEW PACKAGE ID
         user.domain = 'EDI')

# Once your xml file with your PUBLISHED package.id is Done, return to the 
# EDI Production environment (https://portal.edirepository.org/nis/home.jsp)

# Select Tools --> Preview Your Metadata, then upload your metadata (.xml) file 
# associated with your PUBLISHED package.id. Look through the rendered 
# metadata one more time to check for mistakes (author order, bounding box, etc.)

# Select Tools --> Evaluate/Upload Data Packages, then under "EML Metadata File", 
# choose your metadata (.xml) file associated with your PUBLISHED package.id 
# (e.g., edi.518.1.xml), check "I want to manually upload the data by selecting 
# files on my local system", then click Upload.

# Now, Choose File for each file within the data package (e.g., each zip folder), 
# then click Upload. Files will upload and your EML metadata will be checked for 
# errors. Since you checked for and fixed errors in the staging environment, this 
# should run without errors, and your data product is now published! 

# Click the package.id hyperlink to view your final product! HOORAY!



make_eml(path = "C:/Users/wwoel/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLCatwalk",
         dataset.title = "Time series of high-frequency sensor data measuring water temperature, dissolved oxygen, conductivity, specific conductivity, total dissolved solids, chlorophyll a, phycocyanin, and fluorescent dissolved organic matter at discrete depths in Falling Creek Reservoir, Virginia, USA in 2018",
         data.files = "Catwalk_EDI_2020.csv",
         data.files.description = "Catwalk Sensor String",
         temporal.coverage = c("2018-07-05", "2018-12-18"),
         geographic.description = "Southwestern Virginia, USA, North America",
         maintenance.description = "ongoing",
         user.id = c("carylab1", "ccarey"),
         package.id = "edi.271.2", #### this is the one that I need to change!!!
         affiliation = c("EDI", "EDI"))


