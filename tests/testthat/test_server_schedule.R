library(helpq)
context("Staffing schedule fetching")

staffing <- NULL

test_that("Server fetching succeeds", {
  staffing <<- get_staffing() #Intentional over-write of global var
  expect_s3_class(staffing, c("tbl", "data.frame", "tbl_df"))
})

test_that("Server output is usable", {
  staffing %>%
    group_schedule() %>%
    expect_s3_class(c("tbl", "data.frame", "tbl_df"))
})