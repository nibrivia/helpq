# # suppressPackageStartupMessages({
# #   library(jsonlite)
# #   library(lubridate)
# #   library(dplyr)
# #   library(purrr)
# #   # library(pool)
# #   library(readr)
# #   library(tibble)
# #   library(tidyr)
# #   library(DBI)
# # })
#
# data_to_df <- function(lines) {
#   lines %>%
#     map(fromJSON) %>%
#     do.call(rbind, .) %>%
#     as_tibble() %>%
#     unnest(connections, time) %>%
#     mutate(on_duty = map(on_duty,
#                          function(x) {
#                            if (length(x) == 0)
#                              return(data_frame())
#
#                            transpose(x) %>%
#                              as_tibble() %>%
#                              unnest()
#                          }),
#            queue = map(queue,
#                        function(x) {
#                          tmp <- x %>%
#                            as.data.frame()
#
#                          if ("being_helped" %in% colnames(tmp)) {
#                            tmp <- cbind(tmp[, setdiff(colnames(tmp), "being_helped")],
#                                         tmp$being_helped %>%
#                                           rename_all(.funs = (
#                                             function(x) { paste0("staff_", x)})))
#                          }
#
#                          return(tmp)
#                        }),
#            time  = as.POSIXct(time, format = "%Y-%m-%dT%H:%M:%S", tz = "Zulu") %>%
#              format(tz = "America/New_York") %>%
#              as.POSIXct()) %>%
#     mutate(q_len           = map_int(queue, nrow),
#            is_being_helped = map_lgl(queue, ~ "staff_username" %in% colnames(.x)),
#            n_being_helped  = map_int(queue,
#                                      function(x) {
#                                        if ("staff_username" %in% colnames(x)) {
#                                          x %>%
#                                            ungroup() %>%
#                                            filter(!is.na(staff_username)) %>%
#                                            nrow()
#                                        } else {
#                                          return(0L)
#                                        }
#                                      }),
#            staff_helping = map(queue,
#                                ~ map_chr(.x[["staff_name"]], paste, collapse = " ") %>%
#                                  .[. != ""] %>%
#                                  unique()),
#            staff_names = map2(on_duty, queue,
#                               function(on_duty, queue) {
#                                 unique(c(on_duty[["name"]],
#                                          map_chr(queue[["staff_name"]],
#                                                  paste, collapse = " ")) %>%
#                                          .[. != ""])
#                               }),
#            n_staff = map_int(staff_names, length),
#            n_helping = map_int(staff_helping, length))
# }
#
# student_q_data <- function(dta) {
#   tmp <- dta %>%
#     select(time, queue, n_staff) %>%
#     mutate(queue = map_if(queue,
#                           map_lgl(queue, ~ nrow(.x) == 0),
#                           ~ data_frame(username = NA,
#                                        name = NA,
#                                        section = NA,
#                                        location = NA,
#                                        request = NA,
#                                        staff_username = NA,
#                                        staff_name = NA,
#                                        staff_section = NA,
#                                        staff_location = NA)),
#            queue = map(queue,
#                        ~ .x %>%
#                          mutate(position = seq_len(nrow(.x)))) ) %>%
#     unnest()
#
#   if (nrow(tmp) == 0) {
#     return(dta %>%
#              select(time, n_staff) %>%
#              mutate(position = NA,
#                     staff_username = NA,
#                     username = NA,
#                     being_helped = 0,
#                     req_id = NA,
#                     position_adj = NA))
#   }
#
#   if (!"staff_name" %in% colnames(tmp)) {
#     tmp <- tmp %>%
#       mutate(staff_name     = NA,
#              staff_username = NA,
#              staff_location = NA,
#              staff_section  = NA)
#   }
#
#   if (!"name" %in% colnames(tmp)) {
#     tmp <- tmp %>%
#       mutate(name     = NA,
#              username = NA,
#              location = NA,
#              section  = NA)
#   }
#
#   tmp %>%
#     select(-name,     -staff_name,
#            -location, -staff_location,
#            -section,  -staff_section) %>%
#     unique() %>%
#
#     mutate(being_helped = !is.na(staff_username)) %>%
#     group_by(username) %>%
#       arrange(time) %>%
#       mutate(req_id = cumsum(lag(position, default = 0) < position) ) %>%
#     group_by(time) %>%
#       mutate(position_adj = position - sum(being_helped))
# }
#
# staff_q_data <- function(dta) {
#   dta %>%
#     select(time, staff_names, staff_helping) %>%
#     mutate(staff = map2(staff_names, staff_helping,
#                         ~ data_frame(staff = .x) %>%
#                           filter(staff != "") %>%
#                           mutate(is_helping = staff %in% .y))) %>%
#     select(time, staff) %>%
#     unnest(staff)
# }
#
# read_fn <- function() {
#   f <- file("stdin")
#   open(f)
#
#   pool <- dbPool(
#     drv = odbc::odbc(),
#     dsn = "helpq"
#   )
#   on.exit(function() {
#     poolClose(pool)
#   })
#
#   while (length(line <- readLines(f, n = 1)) > 0) {
#     proc_data <- data_to_df(list(line))
#     student_q <- proc_data %>% student_q_data()
#     staff_q   <- proc_data %>% staff_q_data()
#
#     #Student ----
#     fn_stu_q <- "student-queue.csv"
#     write_csv(student_q, fn_stu_q, append = T)
#     dbWriteTable(pool,
#                  name  = "StudentQ",
#                  value = student_q,
#                  row.names = FALSE,
#                  append    = TRUE)
#
#     #Staff ----
#     fn_sta_q <- "staff-queue.csv"
#     write_csv(staff_q, fn_sta_q, append = T)
#     dbWriteTable(pool,
#                  name  = "StaffQ",
#                  value = staff_q,
#                  row.names = FALSE,
#                  append    = TRUE)
#
#     gc()
#   }
#
#   poolClose(pool)
# }
#
# read_fn()
