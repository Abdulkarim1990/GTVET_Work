# =============================================================
# GTVET-IDMS  server.R
# =============================================================

server <- function(input, output, session) {

  # ------ Authentication -----------------------------------
  auth <- loginServer("auth", pool)

  # Show/hide overlay based on auth state
  observe({
    if (isTRUE(auth$logged_in)) {
      shinyjs::hide("login_overlay")
      shinyjs::show("dashboard_content")
    } else {
      shinyjs::show("login_overlay")
      shinyjs::hide("dashboard_content")
    }
  })

  # ------ Logout -------------------------------------------
  observeEvent(input$btn_logout, {
    log_action(pool, auth$user_id, "LOGOUT")
    session$reload()
  })

  # ------ Header user info ---------------------------------
  output$header_user_info <- renderUI({
    req(auth$logged_in)
    role_label <- switch(auth$role,
      school_user      = "School User",
      regional_officer = "Regional Officer",
      qa_officer       = "QA Officer",
      national_viewer  = "National Viewer",
      admin            = "Administrator",
      auth$role)
    tags$li(
      class = "dropdown",
      style = "padding:12px 15px; color:#fff;",
      icon("user-circle"),
      " ", strong(auth$full_name %||% auth$username),
      tags$small(paste0(" (", role_label, ")"))
    )
  })

  # ------ Admin-only sidebar items -------------------------
  output$sidebar_admin_menu <- renderUI({
    req(auth$logged_in, auth$role == "admin")
    tagList(
      hr(),
      shinydashboard::menuItem("Admin — Users",
        tabName = "admin_users",  icon = icon("users-cog")),
      shinydashboard::menuItem("Admin — Windows",
        tabName = "admin_windows", icon = icon("calendar-alt")),
      shinydashboard::menuItem("Audit Log",
        tabName = "audit_log",    icon = icon("history"))
    )
  })

  # ------ Module servers -----------------------------------
  m1Server("m1_module",  pool, auth)
  m2Server("m2_module",  pool, auth)
  homeServer("home_panel", pool, auth)
  mySubmissionsServer("my_subs", pool, auth)

}
