library(helpq)
context("Queue data fetching")

# pool <- NULL
#
# test_that("ODBC properly setup", {
#   pool <<- get_pool() #Intentional over-write of global var
#   expect_s3_class(pool, c("Pool", "R6"))
# })
#
# test_that("Student queue fetching", {
#   pool %>%
#     student_q() %>%
#     expect_s3_class(c("tbl", "data.frame", "tbl_df"))
# })
#
# test_that("Staff queue fetching", {
#   pool %>%
#     staff_q() %>%
#     expect_s3_class(c("tbl", "data.frame", "tbl_df"))
# })
#
# pool::poolClose(pool)