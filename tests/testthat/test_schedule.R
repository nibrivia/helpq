library(helpq)
context("Staffing processing utils")

fake_staffing <- tibble::frame_data(
  ~kerberos, ~shift,
  'bitdiddle', 'Tue1230',
  'bitdiddle', 'Tue1300',
  'bitdiddle', 'Tue1330',

  'bitdiddle', 'Wed0900',

  'bitdiddle', 'Thu0930',

  'aphacker',  'Tue1300',
  'aphacker',  'Tue1330',
  'aphacker',  'Tue1400',
  'aphacker',  'Tue1430',

  'aphacker',  'Wed0930',

  'aphacker',  'Wed1030',

  'aphacker',  'Thu1300'
) %>%
  mutate(shift_time = shift_to_time(.$shift),
         shift_day  = shift_time %>% time_to_weekday(),
         shift_hour = shift_time %>% time_to_hour())

fake_schedule <- tibble::frame_data(
  ~kerberos, ~session_day, ~start, ~end,
  'aphacker',  'Tue', 'Tue1300', 'Tue1430',
  'aphacker',  'Wed', 'Wed0930', 'Wed0930',
  'aphacker',  'Wed', 'Wed1030', 'Wed1030',
  'aphacker',  'Thu', 'Thu1300', 'Thu1300',

  'bitdiddle', 'Tue', 'Tue1230', 'Tue1330',
  'bitdiddle', 'Wed', 'Wed0900', 'Wed0900',
  'bitdiddle', 'Thu', 'Thu0930', 'Thu0930'
)

test_that("Staffing->Schedule okay", {
  generated_schedule <- fake_staffing %>% group_schedule()

  generated_schedule$kerberos %>%
    expect_equal(fake_schedule$kerberos)

  generated_schedule$session_day %>%
    as.character() %>%
    expect_equal(fake_schedule$session_day)

  generated_schedule$start %>%
    expect_equal(fake_schedule$start)

  generated_schedule$end %>%
    expect_equal(fake_schedule$end)
})

fake_on_duty <- tibble::frame_data(
  ~shift, ~staff,
  'Tue1230', c('bitdiddle'),
  'Tue1300', c('aphacker', 'bitdiddle'),
  'Tue1330', c('aphacker', 'bitdiddle'),
  'Tue1400', c('aphacker'),
  'Tue1430', c('aphacker'),
  'Wed0900', c('bitdiddle'),
  'Wed0930', c('aphacker'),
  'Wed1030', c('aphacker'),
  'Thu0930', c('bitdiddle'),
  'Thu1300', c('aphacker')
)

test_that("Shift-based staffing", {
  duty_df <- fake_staffing %>%
    staffing_by_shift()

  expect_s3_class(duty_df, "data.frame")

  duty_df$shift %>% expect_equal(fake_on_duty$shift)
  duty_df$staff %>% expect_equal(fake_on_duty$staff)
})

test_that("Shift-based dataframe to list", {
  duty_list <- fake_staffing %>%
    staffing_by_shift() %>%
    staffing_to_list()

  expect_type(duty_list, "list")

  duty_df_from_list <- tibble::data_frame(
    shift = names(duty_list),
    staff = duty_list
  ) %>%
    mutate(shift_day  = shift %>% shift_to_time() %>% time_to_weekday(),
           shift_hour = shift %>% shift_to_time() %>% time_to_hour()) %>%
    arrange(shift_day, shift_hour)

  expect_s3_class(duty_df_from_list, "data.frame")

  duty_df_from_list$shift %>% expect_equal(fake_on_duty$shift)
  duty_df_from_list$staff %>% expect_equal(fake_on_duty$staff)
})