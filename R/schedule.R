
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
      arrange(shift_time) %>%
      mutate(is_new_session = (shift_time - lag(shift_time, default = -Inf)) > dhours(0.5),
             session        = cumsum(is_new_session)) %>%

    group_by(kerberos, shift_day, session) %>%
      summarise(start = min(shift_time),
                end   = max(shift_time) + dhours(0.5)) %>%
      ungroup() %>%

    mutate(duration = end - start) %>%
    select(kerberos, session_day = shift_day, start, end)
}

#' Who's on duty now?
#'
#' @param schedule Staff schedule (ungrouped)
#' @param shifts   What shifts are we interested in (not times)
#'
#' @return A nested dataframe, with two cols: `shift`, `staff`. Each row of
#'   `staff` contains a char vector of the staff on duty then.
#' @export
#'
staff_on_duty <- function(staffing, shifts) {
  staffing %>%
    filter(shift %in% shifts) %>%
    select(shift, kerberos) %>%
    group_by(shift) %>%
      summarise(staff = list(kerberos)) %>%
      ungroup()
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

