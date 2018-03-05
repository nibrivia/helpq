#' Get database pool
#'
#' This is probably just a temporary function, will be replaced with better auth
#' later. Requires odbc to be properly setup...
#'
#' @return A dbPool object that can be used to connect to the database.
#' @export
#'
#' @examples
get_pool <- function() {
  pool::dbPool(
    drv = odbc::odbc(),
    dsn = "helpq"
  )
}

#' Get student queue
#'
#' @param pool Connection to the database
#'
#' @return A dataframe describing the student side of the queue. Many redundant
#'   rows
#' @export
#'
#' @examples
student_q <- function(pool) {
  pool %>%
    tbl("StudentQ") %>%
    collect() %>%
    mutate(time = as_datetime(time),
           being_helped = being_helped > 0)
}

#' Get staff queue
#'
#' @inheritParams student_q
#'
#' @return A dataframe describing the staff side of the queue. Redundant rows.
#' @export
#'
#' @examples
staff_q <- function(pool) {
  pool %>%
    tbl("StaffQ") %>%
    collect() %>%
    mutate(time = as_datetime(time),
           is_helping = is_helping > 0)
}
