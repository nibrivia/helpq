
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

