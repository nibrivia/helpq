library(helpq)
context("Date utils")

times <- c("Sat1900", "Mon0900", "Sun2330")

test_that("Chaining works", {
  expect_equal(times, time_to_shift(shift_to_time(times)) )
})