library(helpq)
context("Date utils")

shifts <- c("Sat1900", "Mon0900", "Sun2230", "Tue2330")

test_that("Chaining works", {
  shifts %>%
    shift_to_time() %>%
    time_to_shift() %>%
    expect_equal(shifts)
})

test_that("Time to Weekday", {
  wdays <- c("Sat", "Mon", "Sun", "Tue")
  times <- shifts %>% shift_to_time()

  shift_weekdays <- times %>% time_to_weekday()

  # tests ---
  shift_weekdays %>%
    as.character() %>%
    expect_equal(wdays)
})

test_that("Time to Hour", {
  wdays <- c(19, 9, 22.5, 23.5)
  times <- shifts %>% shift_to_time()

  times %>%
    time_to_hour() %>%
    expect_equal(wdays)
})

test_that("DST works okay", {
  time <- as_datetime("2018-03-11 22:30:00 EDT")

  time_to_hour(time) %>%
    expect_equal(22.5)
})