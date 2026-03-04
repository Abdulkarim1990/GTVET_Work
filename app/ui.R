# =============================================================
# GTVET-IDMS  ui.R
# All helper UI functions are defined in their module files
# and sourced via global.R before this file runs.
# =============================================================

coming_soon_ui <- function(module_name) {
  fluidRow(
    column(12,
      div(class = "coming-soon-box",
        icon("clock", class = "coming-soon-icon"),
        h3(module_name),
        p("This module will be available in Phase 2."),
        p(class = "text-muted", "Pilot release: Months 4–6")
      )
    )
  )
}

# ---------------------------------------------------------------
# Main UI — dashboardPage is the top-level element (required by
# shinydashboard). A full-screen login overlay sits on top when
# the user is not authenticated; shinyjs hides/shows it.
# ---------------------------------------------------------------

ui <- shinydashboard::dashboardPage(
  skin = "green",

  # --- Header ---
  shinydashboard::dashboardHeader(
    title = tags$span(
      tags$img(src = "gtvet_logo.png", height = "30px"),
      " GTVET-IDMS"
    ),
    tags$li(
      class = "dropdown",
      uiOutput("header_user_info")
    ),
    tags$li(
      class = "dropdown",
      actionLink("btn_logout",
                 label = tagList(icon("sign-out-alt"), " Logout"),
                 style = "padding:15px 10px; color:#fff;")
    )
  ),

  # --- Sidebar ---
  shinydashboard::dashboardSidebar(
    shinydashboard::sidebarMenu(
      id = "sidebar_menu",
      shinydashboard::menuItem("Home",
        tabName = "home", icon = icon("home")),
      shinydashboard::menuItem("Module M1 — Enrolment",
        tabName = "m1", icon = icon("users"),
        badgeLabel = "Phase 1", badgeColor = "green"),
      shinydashboard::menuItem("Module M2 — Staff & HR",
        tabName = "m2", icon = icon("chalkboard-teacher"),
        badgeLabel = "Phase 1", badgeColor = "green"),
      shinydashboard::menuItem("Module M3 — WEL",
        tabName = "m3", icon = icon("briefcase"),
        badgeLabel = "Phase 2", badgeColor = "yellow"),
      shinydashboard::menuItem("Module M4 — WEL Assessment",
        tabName = "m4", icon = icon("clipboard-check"),
        badgeLabel = "Phase 2", badgeColor = "yellow"),
      hr(),
      shinydashboard::menuItem("My Submissions",
        tabName = "my_submissions", icon = icon("list-check")),
      uiOutput("sidebar_admin_menu")
    )
  ),

  # --- Body ---
  shinydashboard::dashboardBody(

    # shinyjs and CSS must live inside dashboardBody for shinydashboard
    useShinyjs(),
    tags$head(
      tags$link(rel = "stylesheet", href = "styles.css"),
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
    ),

    # Full-screen login overlay — shown until authenticated
    div(id = "login_overlay",
        loginUI("auth")
    ),

    # Dashboard content — hidden until authenticated
    shinyjs::hidden(
      div(id = "dashboard_content",
        shinydashboard::tabItems(
          shinydashboard::tabItem("home",           homeUI("home_panel")),
          shinydashboard::tabItem("m1",             m1UI("m1_module")),
          shinydashboard::tabItem("m2",             m2UI("m2_module")),
          shinydashboard::tabItem("my_submissions", mySubmissionsUI("my_subs")),
          shinydashboard::tabItem("m3", coming_soon_ui("M3 — WEL Placement & Tracking")),
          shinydashboard::tabItem("m4", coming_soon_ui("M4 — WEL Assessment & Employer Feedback"))
        )
      )
    )
  )
)
