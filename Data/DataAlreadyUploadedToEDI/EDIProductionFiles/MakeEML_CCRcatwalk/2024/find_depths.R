find_depths <- function(data_file, # data_file = the file of most recent data either from EDI or GitHub. Currently reads in the L1 file
                        depth_offset,  # depth_offset = the file of depth of each sensor relative to each other. This file for BVR is on GitHub
                        output, # output = the path where you would like the data saved
                        date_offset, # Date_offset = the date we moved the sensors so we know where to split the file. If you don't need to split the file put NULL
                        offset_column1,# offset_column1 = name of the column in the depth_offset file to subtract against the actual depth to get the sensor depth
                        offset_column2, # offset_column2 = name of the second column if applicable for the column with the depth offsets
                        round_digits = 2, #round_digits = number of digits you would like to round to
                        bin_width = 0.25, # bin width in m
                        wide_data = F) { # data will be in the wide format with observations above the water already removed


  # Read in files if data file is a character. If not rename data_file to data
  if(is.character(data_file)){
    data <- readr::read_csv(data_file, show_col_types = F)
  }else{
    data <- data_file
  }

  # Read in depth offset if it is a character. If not then just rename the file
  if(is.character(depth_offset)){
    depth <- readr::read_csv(depth_offset, show_col_types = F)
  } else{
    depth <- depth_offset
  }



  # Select the sensors on the temp string because they are stationary.
  # Then pivot the data frame longer to merge the offset file so you can add a depth to each sensor reading
  long <- data |>
    dplyr::select(any_of(c("Reservoir", "Site", "DateTime")),
                  starts_with("Depth"),
                  starts_with("Ther"),
                  starts_with("RDO"),
                  starts_with("Lvl")) |>
    dplyr::rename("Depth_m" = contains("Depth")) |>
    tidyr::pivot_longer(-c("Reservoir", "Site", "DateTime", "Depth_m"),
                        names_to = "variable",
                        values_to = "observation",
                        values_drop_na = FALSE) |>
    tidyr::separate_wider_delim(cols = variable,
                                names = c("variable","units","Position"),
                                delim = "_") |>
    dplyr::mutate(Position = as.numeric(Position)) |>
    dplyr::left_join(depth, #add in the offset file
                     by = c("Position","Reservoir","Site"))


  # The pressure sensor was moved to be in line with the bottom thermistor. The top two thermistors had slid closer to each other
  # and were re-secured about a meter a part from each other. Because of this we need to filter before 2021-04-05 13:20:00 EST
  # and after. The top two thermistors exact offset will have to be determined again when the water level is high enough again.

  cuts <- tibble::tibble(cuts = as.integer(factor(seq(0,
                                                      ceiling(max(long$Depth_m, na.rm = T)),
                                                      0.25))),
                         depth_bin = seq(0,
                                         ceiling(max(long$Depth_m, na.rm = T)), 0.25))

  # If the sensors string was never moved then Date_offset is NULL
  if (is.null(date_offset)){
    long_depth <- long |>
      dplyr::mutate(sensor_depth = Depth_m-get(offset_column1)) |>
      #find the depth of the sensor using the specified offset column
      dplyr::mutate(rounded_depth = round(sensor_depth,
                                          round_digits),
                    cuts = cut(sensor_depth,
                               breaks = cuts$depth_bin,
                               include.lowest = T, right = F, labels = F)) |>
      dplyr::left_join(cuts, by = 'cuts')
    #rounded the depth to 0.5 if I did to 1 there would be duplicates

    # For using the wide format we want to keep all NAs because we want all of the observations from the original data frame
    # We are not going to drop anything to have the same number of rows

    if(wide_data==F){
      long_depth <- long_depth |>
        dplyr::filter(!is.na(observation)) |> # take out readings that are NA
        dplyr::filter(!is.na(sensor_depth)) # remove observations if there is no depth associated with it
    }

  }else{

    pre_depth <- long |>
      dplyr::filter(DateTime <= lubridate::ymd(date_offset)) |>
      dplyr::mutate(sensor_depth = Depth_m - get(offset_column1)) |>
      #this gives you the depth of the thermistors from the surface
      dplyr::mutate(rounded_depth = round(sensor_depth, round_digits),
                    cuts = cut(sensor_depth,
                               breaks = cuts$depth_bin,
                               include.lowest = T, right = F, labels = F)) |>
      dplyr::left_join(cuts, by = 'cuts')
    #Round to digits specified in function


    post_depth <- long |>
      dplyr::filter(DateTime > lubridate::ymd(date_offset)) |>
      dplyr::mutate(sensor_depth = Depth_m - get(offset_column2)) |>
      # this gives you the depth of the thermistor from the surface
      dplyr::mutate(rounded_depth = round(sensor_depth, round_digits),
                    cuts = cut(sensor_depth,
                               breaks = cuts$depth_bin,
                               include.lowest = T, right = F, labels = F, )) |>
      dplyr::left_join(cuts, by = 'cuts')
    # Round the digit specified in the function

    # For using the wide format we want to keep all NAs because we want all of the observations from the original data frame
    # We are not going to drop anything to have the same number of rows

    if(wide_data==F){
      long_depth <- pre_depth |>
        dplyr::bind_rows(post_depth) |> # bind the 2 separate data frames
        dplyr::filter(!is.na(observation)) |> # take out readings that are NA
        dplyr::filter(!is.na(sensor_depth)) # remove observations if there is no depth associated with it
    }else{
      long_depth <- pre_depth |>
        dplyr::bind_rows(post_depth)  # bind the 2 separate data frames
    }
  }
  # Make the data frame wide again and changes observations to NA that are out of the water
  if(wide_data ==T){

    final_Temp <- long_depth |>
      dplyr::mutate(observation = ifelse(sensor_depth<0, NA, observation)) |>
      tidyr::pivot_wider(id_cols =  c(Reservoir, Site, DateTime), names_from = c("variable", "units", "Position"),
                         names_sep = "_",
                         values_from = "observation",
                         values_fill = NA)

    # Add the columns that were cut

    oth_sensors <- data|>
      select(any_of(c("Reservoir", "Site", "DateTime")),
             starts_with("EXO"),
             starts_with("Flag"),
             contains("Depth"),
             starts_with("RECORD"),
             starts_with("CR"))

    # merge the two files together to get a file that looks like the one you started with except the observations above the
    # water are removed

    final_depths <- merge(final_Temp,oth_sensors, by=(c("Reservoir", "Site", "DateTime"))) |>
      select(colnames(data))


  } else{

    # only select the columns you want
    final_depths <- long_depth |>
      dplyr::mutate(Depth_m = round(Depth_m, round_digits)) |>
      dplyr::select(Reservoir, Site, Depth_m,
                    DateTime, variable,
                    Position, observation, sensor_depth,
                    rounded_depth,
                    depth_bin)

  }



  # If you want to save the output then give the file a name
  if(!is.null(output)){
    write.csv(final_depths, output, row.names = FALSE)
  }

  return(final_depths)

}
