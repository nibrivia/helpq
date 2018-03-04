# hours_clean %>%
#   ggplot(aes(x = kerberos,
#              color = kerberos,
#              y = t_numeric)) +
#   geom_point() +
#   facet_grid(. ~ day, scales = "free_x") +
#
#   scale_y_reverse() +
#   theme_ipsum_rc()



# hours_group %>%
#   ggplot(aes(x     = kerberos,
#              xend  = kerberos,
#              color = kerberos,
#              y     = start,
#              yend  = end)) +
#   geom_segment(size = 2) +
#   facet_grid(. ~ day, scales = "free_x") +
#
#   scale_y_reverse() +
#   theme_ipsum_rc()
