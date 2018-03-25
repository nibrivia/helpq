#' Get database pool
#'
#' This is probably just a temporary function, will be replaced with better auth
#' later. Requires odbc to be properly setup...
#'
#' @return A dbPool object that can be used to connect to the database.
#' @export
#'
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
student_q <- function(pool) {
  pool %>%
    tbl("StudentQ") %>%
    collect() %>%
    mutate(time = as_datetime(.$time),
           being_helped = .$being_helped > 0)
}

#' Simplify the student queue data
#'
#' @param student_q_full A dataframe, output from student_q()
#'
#' @return A simplified dataframe
#' @export
student_queue_deltas <- function(student_q_full) {
  sq %>%

    # Remove extra columns
    select(time, username, request, staff_username, position) %>%
    mutate(time_id = dense_rank(time)) %>%

    # Remove extra rows
    filter(!is.na(username)) %>%

    # Find interesting rows
    arrange(time) %>%
    group_by(username) %>%
      mutate(enter =      time_id                  - lag(time_id, default = -Inf) > 1,
             exit  = lead(time_id, default = +Inf) -     time_id                  > 1) %>%
      mutate(got_help  = lag( is.na(staff_username), default = F) & !is.na(staff_username),
             stop_help = lag(!is.na(staff_username), default = F) &  is.na(staff_username)) %>%
      mutate(interesting    = enter | exit | got_help | stop_help) %>%

      ungroup() %>%
    filter(interesting) %>%
    mutate(event = ifelse(enter, "enter",
                          ifelse(exit, "exit",
                                 ifelse(got_help, "got_help", NA))) %>%
             factor())
}


#' Get staff queue
#'
#' @inheritParams student_q
#'
#' @return A dataframe describing the staff side of the queue. Redundant rows.
#' @export
#'
#' @importFrom dplyr tbl collect
#'
staff_q <- function(pool) {
  pool %>%
    tbl("StaffQ") %>%
    collect() %>%
    mutate(time = as_datetime(.$time),
           is_helping = .$is_helping > 0)
}

#' Simplify staff queue
#'
#' @param staff_queue_full
#'
#' @return
#' @export
#'
#' @examples
staff_queue_deltas <- function(staff_queue_full) {
  staff_queue_full %>%
    mutate(time_id = dense_rank(time)) %>%

    group_by(staff) %>%
      mutate(enter =      time_id                  - lag(time_id, default = -Inf) > 1,
             exit  = lead(time_id, default = +Inf) -     time_id                  > 1) %>%
      ungroup() %>%

    mutate(event = ifelse(enter, "enter",
                          ifelse(exit, "exit", NA)) %>%
             factor())
}
