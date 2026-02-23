library(shiny)
library(DBI)
library(duckdb)

# Define UI for application
ui <- fluidPage(

    # Application title
    titlePanel("SEC Dashboard with DuckDB"),

    # Sidebar 
    sidebarLayout(
        sidebarPanel(
            helpText("Data is fetched from Data/sec_dashboard.duckdb"),
            actionButton("refresh", "Refresh Data")
        ),

        # Show a plot and the table
        mainPanel(
           plotOutput("distPlot"),
           dataTableOutput("metricsTable")
        )
    )
)

# Define server logic
server <- function(input, output) {

    # Reactive expression to fetch data
    data <- eventReactive(input$refresh, {
        con <- dbConnect(duckdb::duckdb(), dbdir = "Data/sec_dashboard.duckdb", read_only = TRUE)
        on.exit(dbDisconnect(con, shutdown = TRUE))
        dbReadTable(con, "metrics")
    }, ignoreNULL = FALSE)

    output$distPlot <- renderPlot({
        df <- data()
        hist(df$value, col = 'darkgray', border = 'white',
             xlab = 'Value',
             main = 'Histogram of Metrics')
    })
    
    output$metricsTable <- renderDataTable({
        data()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
