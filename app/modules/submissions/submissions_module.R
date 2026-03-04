# =============================================================
# GTVET-IDMS  My Submissions panel module
# =============================================================

mySubmissionsUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
      h3("My Submissions"),
      DTOutput(ns("submissions_table"))
    )
  )
}

mySubmissionsServer <- function(id, pool, auth) {
  moduleServer(id, function(input, output, session) {

    output$submissions_table <- DT::renderDT({
      req(auth$logged_in)

      query <- if (auth$role == "school_user") {
        list(
          "SELECT s.submission_id, s.module_code, s.academic_year, s.semester,
                  s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at,
                  TO_CHAR(s.approved_at, 'DD Mon YYYY HH24:MI') AS approved_at,
                  s.return_reason
           FROM submissions s
           WHERE s.institution_id=$1
           ORDER BY s.academic_year DESC, s.semester DESC, s.module_code",
          list(auth$institution_id))
      } else if (auth$role %in% c("regional_officer", "qa_officer")) {
        list(
          "SELECT s.submission_id, i.institution_name, s.module_code,
                  s.academic_year, s.semester, s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at,
                  s.return_reason
           FROM submissions s
           JOIN institutions i ON i.institution_id = s.institution_id
           WHERE i.region_id=$1
           ORDER BY s.submitted_at DESC NULLS LAST",
          list(auth$region_id))
      } else {
        list(
          "SELECT s.submission_id, i.institution_name, r.region_name,
                  s.module_code, s.academic_year, s.semester,
                  s.status, s.version,
                  TO_CHAR(s.submitted_at,'DD Mon YYYY HH24:MI') AS submitted_at
           FROM submissions s
           JOIN institutions i ON i.institution_id = s.institution_id
           JOIN regions r ON r.region_id = i.region_id
           ORDER BY s.submitted_at DESC NULLS LAST LIMIT 500",
          list())
      }

      df <- db_query(pool, query[[1]], query[[2]])
      if (is.null(df) || nrow(df) == 0) {
        df <- data.frame(Message = "No submissions found.")
      }

      DT::datatable(
        df,
        rownames   = FALSE,
        selection  = "single",
        options    = list(
          pageLength = 15,
          scrollX    = TRUE,
          dom        = "Bfrtip",
          buttons    = c("csv", "excel")
        ),
        extensions = "Buttons",
        class      = "table-striped table-hover"
      )
    }, server = FALSE)

    observeEvent(input$submissions_table_rows_selected, {
      req(auth$role %in% c("regional_officer", "qa_officer", "admin"))
      # Future: open Approve / Return modal — deferred to workflow panel
    })
  })
}
