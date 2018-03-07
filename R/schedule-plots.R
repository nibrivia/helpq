# hours_clean %>%
#   ggplot(aes(x = kerberos,
#              color = kerberos,
#              y = t_numeric)) +
#   geom_point() +
#   facet_grid(. ~ day, scales = "free_x") +
#
#   scale_y_reverse() +
#   theme_ipsum_rc()



#' Title
#'
#' @param staffing
#'
#' @return
#' @export
#'
#' @importFrom ggplot2 ggplot aes geom_segment geom_text geom_hline facet_grid
#' @importFrom ggplot2 annotate scale_y_reverse theme labs guides element_blank
#'
#' @examples
schedule_plot_base <- function(schedule) {
  schedule %>%
    mutate(start_hour  = shift_start_time(start) %>% time_to_hour(),
             end_hour  = shift_end_time(end)     %>% time_to_hour()) %>%

    ggplot(aes(x     = reorder(kerberos, start_hour),
               xend  = kerberos,
               color = kerberos,
               fill  = kerberos,
               # ymin = start_hour,
               y    = start_hour,
               # ymax = end_hour,
               # y     = start_hour,
               yend  =   end_hour)) +
    geom_segment(size = 2) +


    hrbrthemes::theme_ipsum_rc() +

    labs(x = NULL, y = NULL,
         color = NULL) +
    guides(color = F)
}

schedule_plot_vertical   <- function(schedule) {
  schedule_plot_base(schedule) +
    geom_text(aes(label = kerberos),
              nudge_y = .1,
              angle = 90,
              hjust = 0,
              check_overlap = TRUE) +
    scale_y_reverse(minor_breaks = 0:48/2,
                    breaks       = 0:24) +
    facet_grid(. ~ session_day, scales = "free_x") +
    theme(panel.grid.major.x = element_blank(),
          axis.text.x        = element_blank())
}

#' Title
#'
#' @param schedule
#' @param now_line
#'
#' @return
#' @export
#'
#' @importFrom ggplot2 scale_y_continuous geom_hline coord_flip
#'
#' @examples
schedule_plot_horizontal <- function(schedule, now_line = FALSE) {
  p <- schedule_plot_base(schedule)

  if (now_line) {
    p <- p +
      geom_hline(aes(yintercept = now() %>% time_to_hour()),
                 color = "red")
  }

  p +
    geom_text(aes(label = kerberos),
              nudge_y = -.1,
              angle = 0,
              hjust = "right",
              check_overlap = TRUE) +
    facet_grid(. ~ session_day, scales = "free_x") +
    scale_y_continuous(minor_breaks = 0:48/2,
                       breaks       = 0:24) +
    theme(panel.grid.major.y = element_blank(),
          axis.text.y        = element_blank()) +
    coord_flip()

}

kerberos_name <- tibble::frame_data(
  ~kerberos, ~name,
  "luok",     "Kara Luo",
  "hwdo",     "Hyung Wan Do",
  "cjt",      "Chris Terman",
  "nibr",     "Olivia Brode-Roger",
  "msands",   "Margaret Sands",
  "apersad",  "Ashisha Persad",
  "adhikara", "Aradhana Adhikara",
  "swampfox", "Frances Hartwell",
  "arielj",   "Ariel Jacobs",
  "dkogut",   "Dougie Kogut",
  "helik",    "Kat Hendrickson"
)

schedule_attendance_plot <- function(schedule, pool = get_pool(), now_line = TRUE) {
  attendance <- pool %>%
    staff_q() %>%
    filter(date(time) == today()) %>%
    left_join(kerberos_name, by = c("staff" = "name"))

  p <- schedule %>%
    filter(session_day == today() %>% time_to_weekday()) %>%
    mutate(start_hour  = shift_start_time(start) %>% time_to_hour(),
           end_hour  = shift_end_time(end)     %>% time_to_hour()) %>%

    ggplot(aes(x     = reorder(kerberos, start_hour),
               xend  = kerberos,
               ymin     = start_hour,
               y = start_hour,
               ymax  =   end_hour))

  p +
    geom_point(data = attendance,
               inherit.aes = FALSE,
               aes(y = time %>% time_to_hour(),
                   x = kerberos),
               color = "navy")

  if (now_line) {
    p <- p +
      geom_hline(aes(yintercept = now() %>% time_to_hour()),
                 color = "red")
  }

  p +
    geom_crossbar() +
    geom_text(aes(label = kerberos),
              nudge_y = -.1,
              angle = 0,
              hjust = "right",
              check_overlap = TRUE) +


    scale_y_continuous(minor_breaks = 0:48/2,
                       breaks       = 0:24) +
    coord_flip() +

    facet_grid(. ~ session_day, scales = "free_x") +

    hrbrthemes::theme_ipsum_rc() +
    theme(panel.grid.major.y = element_blank(),
          axis.text.y        = element_blank()) +

    labs(x = NULL, y = NULL,
         color = NULL) +
    guides(color = F)
}
