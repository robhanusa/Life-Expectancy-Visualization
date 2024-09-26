library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(reshape)

df <- read.csv("Data.csv")
df_life_expectancy <- df[df$indicator_name == "Life expectancy at birth, total (years)", ]

# UI ----
ui <- dashboardPage(
  
  skin = "purple",
  
  # Header ----
  dashboardHeader(
    title = "Life Expectancy Comparison",
    titleWidth = 300
  ),
  
  # Sidebar ----
  dashboardSidebar(
    width = 300,
    
    # Header for input section
    h4("Choose Inputs", style = "padding-left:15px"),
    
    # Slider input
    sliderInput(
      inputId = 'year_range', 
      label = 'Indicate Year Range', 
      min = 1970, 
      max = 2020, 
      step = 1,
      value = c(1970, 2019), 
      sep = ""
    ),
    
    # Dropdown input
    selectInput(
      inputId = 'countries', 
      label = 'Select Countries to Graph', 
      multiple = TRUE,
      choices = sort(unique(df_life_expectancy$country_name)),
      selected = c('United States', 'Belgium', 'France')
    )
  ),
  
  # Body ----
  dashboardBody(
    tabsetPanel(
      type = "tabs",
      id = "tab_select",
      tabPanel(
        title = "Yearly Progression",
        plotlyOutput('p1')
      ),
      tabPanel(
        title = "Factor Comparison",
        style = 'background-color: white',
        plotlyOutput('p2'),
        uiOutput('factor_choice')
      )
    )
  )
)

# Server----
server <- function(input, output) {
  
  # Clean df for p1----
  df_p1 <- reactive({
    df[df$indicator_name == 'Life expectancy at birth, total (years)' &
         df$year >= input$year_range[1] & df$year <= input$year_range[2] &
         df$country_name %in% input$countries, ]
    })
  
  # Life Expectancy by year graph----
  output$p1 <- renderPlotly({
    # Create initial plotly object
    p1 <- plot_ly(
      data = df_p1(), 
      x = ~year, 
      y = ~value, 
      color = ~country_name, 
      text = ~country_name,
      hovertemplate = paste(
        paste0('<extra></extra>Country: %{text}\nLife Expectancy: %{y}\nYear: %{x}')
      )
    ) %>% 
      # Add scatter trace with lines and markers
      add_trace(type = 'scatter', mode = 'lines+markers') %>%
      # Set layout options for the plot
      layout(
        xaxis = list(title = 'Year'), 
        yaxis = list(title = 'Life Expectancy', hoverformat = '.1f')
      )
  
  })
  
  # Clean df for p2----
  df_p2 <- reactive(df[df$year == 2010, ])
  df_p2_wide <- reactive(cast(df_p2(), country_name~indicator_name))

  # This function will make abbreviations (i.e. first word only) for each metric
  # and make a list that links the abbreviations to the full name. This is 
  # because it is difficult to reference a column name with spaces or special
  # characters, but I want the full names to remain visible for the user.
  make_metric_abbrs <- function(df_temp) {
    
    # Create vector of metrics (indicators) from dataframe. 
    metrics_names <- colnames(df_temp)
    
    # Replace column names with first word only
    metrics_abbr <- sub(' .*', '', metrics_names)
    names(df_temp) <- metrics_abbr
    metrics_names_list <- as.list(metrics_names)
    metrics_abbr_list <- as.list(metrics_abbr)
    names(metrics_abbr_list) <- metrics_names_list
    
    return(metrics_abbr_list)
  }
  
  metrics_abbr_list <- reactive(make_metric_abbrs(df_p2_wide()))
  
  # Function to make a new df with the abbreviated column names
  # This requires a function instead of a single line because of the reactive 
  # context
  change_col_names <- function(df_temp) {
    names(df_temp) <- metrics_abbr_list()
    return(df_temp)
  }
  
  df_p2_wide2 <- reactive(change_col_names(df_p2_wide()))
  
  # Factor comparison graph----
  output$p2 <- renderPlotly({
    req(input$metric)
    p2 <- ggplot(data = df_p2_wide2(), 
                 aes_string(x = metrics_abbr_list()[[input$metric]], 
                            y = 'Life',
                            text = 'country_name')) +
      geom_point() +
      xlab(input$metric) +
      ylab('Life Expectancy') +
      ggtitle(paste0('Life expectancy in 2010 versus ', input$metric)) +
      theme(plot.title = element_text(hjust = 0.5))
    
    ggplotly(p2, tooltip = 'text')
  })
  
  # Panel to choose factor----
  output$factor_choice <- renderUI({
    div(
      class = 'container',
      style = 'background-color: white',
      div(
        class = 'jumbotron',
        style = 'background-color: white',
        h4('Choose a factor to compare life expectancy against'),
        selectInput(inputId = 'metric', 
                    label = 'Select metric:',
                    choices = sort(unique(df$indicator_name)[-3]),
                    width = 400)
      )
    )
  })
}

shinyApp(ui, server)