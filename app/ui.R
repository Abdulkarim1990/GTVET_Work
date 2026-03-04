# =============================================================
# GTVET-IDMS  ui.R
# =============================================================

ui <- fluidPage(
  title = APP_CONFIG$app_title,

  # ------ Head tags ------------------------------------------
  tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),

  useShinyjs(),

  # ------ Login panel (shown when not authenticated) ---------
  shinyjs::hidden(
    div(id = "app_login",
        loginUI("auth")
    )
  ),

  # ------ Main app (shown after authentication) ---------------
  shinyjs::hidden(
    div(id = "app_main",
        shinydashboard::dashboardPage(
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
              actionLink("btn_logout", label = tagList(icon("sign-out-alt"), " Logout"),
                         style = "padding:15px 10px; color:#fff;")
            )
          ),

          # --- Sidebar ---
          shinydashboard::dashboardSidebar(
            shinydashboard::sidebarMenu(
              id = "sidebar_menu",
              shinydashboard::menuItem("Home",
                tabName = "home", icon = icon("home")),

              # School-facing modules
              shinydashboard::menuItem("Module M1 — Enrolment",
                tabName = "m1", icon = icon("users"),
                badgeLabel = "Phase 1", badgeColor = "green"),
              shinydashboard::menuItem("Module M2 — Staff & HR",
                tabName = "m2", icon = icon("chalkboard-teacher"),
                badgeLabel = "Phase 1", badgeColor = "green"),

              # Coming soon
              shinydashboard::menuItem("Module M3 — WEL",
                tabName = "m3", icon = icon("briefcase"),
                badgeLabel = "Phase 2", badgeColor = "yellow"),
              shinydashboard::menuItem("Module M4 — WEL Assessment",
                tabName = "m4", icon = icon("clipboard-check"),
                badgeLabel = "Phase 2", badgeColor = "yellow"),

              hr(),
              shinydashboard::menuItem("My Submissions",
                tabName = "my_submissions", icon = icon("list-check")),

              # Admin only
              uiOutput("sidebar_admin_menu")
            )
          ),

          # --- Body ---
          shinydashboard::dashboardBody(
            shinydashboard::tabItems(
              # Home
              shinydashboard::tabItem("home",     homeUI("home_panel")),
              # M1
              shinydashboard::tabItem("m1",       m1UI("m1_module")),
              # M2
              shinydashboard::tabItem("m2",       m2UI("m2_module")),
              # My Submissions
              shinydashboard::tabItem("my_submissions", mySubmissionsUI("my_subs")),
              # Coming soon placeholders
              shinydashboard::tabItem("m3",       coming_soon_ui("M3 — WEL Placement & Tracking")),
              shinydashboard::tabItem("m4",       coming_soon_ui("M4 — WEL Assessment & Employer Feedback"))
            )
          )
        )
    )
  )
)

# ------ Helper: Coming Soon panel ----------------------------
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

# ------ Helper: Home tab ------------------------------------
homeUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
      div(class = "home-welcome",
        uiOutput(NS(id, "welcome_msg"))
      )
    ),
    column(3, uiOutput(NS(id, "box_m1_status"))),
    column(3, uiOutput(NS(id, "box_m2_status"))),
    column(6, uiOutput(NS(id, "box_window_status")))
  )
}

mySubmissionsUI <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(12,
      h3("My Submissions"),
      DTOutput(ns("submissions_table"))
    )
  )
}
