#' Title
#'
#' @return
#' @export
#'
#' @examples
get_pool <- function() {
  pool <- pool::dbPool(
    drv = odbc::odbc(),
    dsn = "helpq"
  )
}

#' Title
#'
#' @param pool
#'
#' @return
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

#' Title
#'
#' @param pool
#'
#' @return
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
