# =============================================================
# GTVET-IDMS  Home panel module
# =============================================================

homeUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
      div(class = "home-welcome",
        uiOutput(ns("welcome_msg"))
      )
    ),
    column(3, uiOutput(ns("box_m1_status"))),
    column(3, uiOutput(ns("box_m2_status"))),
    column(6, uiOutput(ns("box_window_status")))
  )
}

homeServer <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {

    output$welcome_msg <- renderUI({
      req(auth$logged_in)
      div(class = "page-header",
        h3(icon("home"), " Welcome, ", strong(auth$full_name %||% auth$username)),
        p(class = "text-muted",
          APP_CONFIG$app_title, " — Academic Year: ",
          strong(APP_CONFIG$current_ay))
      )
    })

    output$box_m1_status <- renderUI({
      req(auth$logged_in, auth$institution_id)
      sub <- db_query(pool,
        "SELECT status FROM submissions
         WHERE institution_id=$1 AND module_code='M1' AND academic_year=$2
         ORDER BY version DESC LIMIT 1",
        list(auth$institution_id, APP_CONFIG$current_ay))
      status <- if (nrow(sub) == 0) "Not started" else sub$status[1]
      colour <- switch(status,
        `Not started` = "yellow", Draft = "blue",
        Submitted = "orange", `Under Review` = "orange",
        Approved = "green", Returned = "red", "blue")
      shinydashboard::valueBox(
        value = status, subtitle = "M1 — Enrolment",
        icon = icon("users"), color = colour, width = 12)
    })

    output$box_m2_status <- renderUI({
      req(auth$logged_in, auth$institution_id)
      sub <- db_query(pool,
        "SELECT status FROM submissions
         WHERE institution_id=$1 AND module_code='M2' AND academic_year=$2
         ORDER BY version DESC LIMIT 1",
        list(auth$institution_id, APP_CONFIG$current_ay))
      status <- if (nrow(sub) == 0) "Not started" else sub$status[1]
      colour <- switch(status,
        `Not started` = "yellow", Draft = "blue",
        Submitted = "orange", `Under Review` = "orange",
        Approved = "green", Returned = "red", "blue")
      shinydashboard::valueBox(
        value = status, subtitle = "M2 — Staff & HR",
        icon = icon("chalkboard-teacher"), color = colour, width = 12)
    })

    output$box_window_status <- renderUI({
      today   <- Sys.Date()
      windows <- db_query(pool,
        "SELECT module_code, semester, open_date, close_date FROM submission_windows
         WHERE academic_year=$1 AND is_active=TRUE ORDER BY module_code, semester",
        list(APP_CONFIG$current_ay))
      if (is.null(windows) || nrow(windows) == 0) {
        return(div(class = "alert alert-warning",
                   "No submission windows are currently configured."))
      }
      rows <- lapply(seq_len(nrow(windows)), function(i) {
        w       <- windows[i, ]
        is_open <- today >= w$open_date & today <= w$close_date
        tags$tr(
          tags$td(w$module_code),
          tags$td(paste("Semester", w$semester)),
          tags$td(format(w$open_date, "%d %b %Y")),
          tags$td(format(w$close_date, "%d %b %Y")),
          tags$td(
            if (is_open)
              span(class = "label label-success", "OPEN")
            else if (today < w$open_date)
              span(class = "label label-info", "Upcoming")
            else
              span(class = "label label-default", "Closed")
          )
        )
      })
      shinydashboard::box(
        title = "Submission Windows", status = "primary",
        solidHeader = TRUE, width = 12,
        tags$table(class = "table table-condensed table-striped",
          tags$thead(tags$tr(
            tags$th("Module"), tags$th("Period"),
            tags$th("Opens"), tags$th("Closes"), tags$th("Status")
          )),
          tags$tbody(rows)
        )
      )
    })
  })
}
