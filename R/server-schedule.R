
#' Gets the current staffing schedule from the server
#'
#' @return A dataframe with columns kerberos, shift, day, and time
#'
#' @importFrom httr content
#' @importFrom tibble as_tibble
#' @export
get_staffing <- function() {
  # Authenticate and grab staffing
  resp <- POST("https://6004.mit.edu/login",
               body = list(url      = "https://6004.mit.edu/user/lab_hours",
                           `_id`    = Sys.getenv("helpq_username"),
                           password = Sys.getenv("helpq_password"),
                           submit   = "Login"),
               encode = "form")

  # Extract global vars
  global_vars <- resp %>%
    content() %>%
    html_node("head") %>%
    html_nodes("script") %>%
    tail(1) %>%
    html_text()

  # Extract wanted vars
  hours_list <- global_vars %>%
    strsplit(";") %>%
    .[[1]] %>%
    .[[1]] %>%
    gsub(pattern = "var slist = ", replacement = "") %>%
    jsonlite::fromJSON()

  # It's now a dataframe!
  hours <- hours_list %>%
    map(as_tibble) %>%
    map2_df(names(.), ~ .x %>% mutate(kerberos = .y)) %>%
    rename(shift = value) %>%
    mutate(shift = gsub("Late", "2300", .$shift))


  hours %>%
    mutate(shift_time = shift_to_time(.$shift),
           shift_day  = time_to_weekday(shift_time),
           shift_hour = time_to_hour(shift_time)) %>%
    arrange(.$kerberos, .$shift_day, .$shift_time)
}

