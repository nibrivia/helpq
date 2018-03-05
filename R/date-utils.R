library(lubridate)

#' Convert datetime to shift string
#'
#' @param datetimes vector of datetimes to convert
#'
#' @return vector of strings corresponding to the shift in which the time
#'   happens
#' @export
#'
#'
time_to_shift <- function(datetimes = now()) {
  floor_date(datetimes, "30 minutes") %>%
    format(format = "%a%H%M")
}

#' Convert shift strings to datetimes
#'
#' @param shifts vector of shifts ('Sat1700', 'Tue0900', ...)
#'
#' @return datetimes corresponding to the next such shift (if the day is today,
#'   returns today's shift)
#'
#' @importFrom lubridate as_datetime
#' @export
#'
shift_to_time <- function(shifts) {
  Sys.setenv('TZ'='America/New_York')
  system2(command = "date",
          args    = c("-f", "-",    #date: read stdin
                      "--rfc-3339=seconds"),
          input = shifts,
          stdout = TRUE) %>%
    as_datetime(tz = "America/New_York")
}

#' Converts a date to a decimal hour component
#'
#' @param times datetimes to convert
#'
#' @return hours since the start of day (can be fractional)
#' @export
#'
time_to_hour <- function(times) {
  hours <- times %>% hour()
  mins  <- times %>% minute()

  hours + mins/60
}


#' Day string to ordered factor
#'
#' @param times vector of strings to convert
#'
#' @return ordered factors for a week starting on Monday
#' @export
#'
time_to_weekday <- function(times) {
  wday(times, label = T, week_start = 1)
}