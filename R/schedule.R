
#' Groups unprocessed dataframe into sessions
#'
#' @param hours A dataframe with kerberos, shift_day, shift_hour columns
#'
#' @return A dataframe with kerberos, session_day, start, end columns
#'   corresponding to the same staffing schedule as `hours`.
#' @export
group_schedule <- function(hours) {
  hours %>%
    group_by(kerberos, shift_day) %>%
      arrange(.$shift_time) %>%
      mutate(is_new_session = (shift_time - lag(shift_time, default = -Inf)) > dhours(0.5),
             session        = cumsum(is_new_session)) %>%

    group_by(kerberos, shift_day, session) %>%
      summarise(start = min(shift_time),
                end   = max(shift_time)) %>%
      ungroup() %>%

    mutate(start    = time_to_shift(start),
           end      = time_to_shift(end)) %>%
    select(kerberos, session_day = shift_day, start, end)
}

#' Who's on duty now?
#'
#' @param staffing Staff schedule (ungrouped)
#' @param shifts   What shifts are we interested in (not times)
#'
#' @return A nested dataframe, sorted by shift with two cols: `shift`, `staff`.
#'   Each row of `staff` contains a char vector of the staff on duty then. If no
#'   staff are on duty, staff is empty list (NULL).
#' @export
#'
staff_on_duty <- function(staffing, shifts) {
  data_frame(shift = shifts) %>%
    left_join(staffing, by = "shift") %>%
    select(shift, kerberos) %>%
    group_by(shift) %>%
      summarise(staff = ifelse(any(is.na(kerberos)), list(), list(kerberos))) %>%
      ungroup()
}

#' Who's on duty now?
#'
#' @param staffing Staff schedule (ungrouped)
#'
#' @return A nested dataframe sorted by shift, with two cols: `shift`,
#'   `staff`.Each row of `staff` contains a char vector of the staff on duty
#'   then. If no staff are on duty, staff is empty list (NULL). Staff list
#'   sorted alphabetically.
#' @export
#'
staffing_by_shift <- function(staffing) {
  staffing %>%
    select(shift, kerberos) %>%
    group_by(shift) %>%
      summarise(staff = kerberos %>% sort() %>% list()) %>%
      ungroup() %>%

    ## Sort
    mutate(shift_day  = shift %>% shift_to_time() %>% time_to_weekday(),
           shift_hour = shift %>% shift_to_time() %>% time_to_hour()) %>%
    arrange(shift_day, shift_hour) %>%

    ##Remove temp cols
    select(shift, staff)
}

#' Convert staffing dataframe to a list
#'
#' This is a helper for when we want a list to use as \code{on_duty[now]}
#'
#' @param staffing_df A dataframe as output by \link{staff_on_duty}
#'
#' @return A named list: the name is the shift, the content is a charactor
#'   vector with the staff on duty then
#' @export
#'
staffing_to_list <- function(staffing_df) {
  staffing_list        <- staffing_df[["staff"]]
  names(staffing_list) <- staffing_df[["shift"]]

  return(staffing_list)
}

