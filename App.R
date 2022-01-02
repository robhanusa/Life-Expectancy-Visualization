library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)

df <- read.csv('Data.csv')

#Initial cleaning to remove indicators (rows) were not interested in
indicators <- c('Life expectancy at birth, total (years)',
                'Current health expenditure per capita (current US$)',
                'Prevalence of overweight (% of adults)')
df <- df[df$indicator_name %in% indicators, ]

min_year <- 1990
max_year <- 2018
countries <- c('France','India')

df_p1 <- df[df$indicator_name == 'Life expectancy at birth, total (years)' &
              df$year >= min_year & df$year <= max_year &
              df$country_name %in% countries, ]

p1 <- plot_ly(data = df_p1, x = ~year, y = ~value, 
              color = ~country_name, text = ~country_name,
              hovertemplate = paste(paste0('<extra></extra>Country: %{text}\nLife Expectancy: %{y}\nYear: %{x}')))
p1 <- p1 %>% add_trace(type = 'scatter', mode = 'lines+markers')

p1 <- p1 %>% layout(xaxis = list(title = 'Year'), 
                    yaxis = list(title = 'Life Expectancy', hoverformat = '.1f'))
p1

#UI ----
ui <- dashboardPage(
  
  skin = "purple",
  
  #Header ----
  dashboardHeader(
    title = "Life Expectancy Comparison",
    titleWidth = 300
  ),
  #Sidebar ----
  dashboardSidebar(
    width = 300,
    h4("Choose Inputs", style = "padding-left:30px"),
    sliderInput('year_range', 'Indicate Year Range', 1970, 2019, step = 1,
                value = c(1970,2019)),
    selectInput('countries', label = 'Select Contries to Graph', multiple = TRUE,
                choices = sort(unique(df$country_name)),
                selected = c('United States', 'Belgium', 'France')
      
    )
  ),
  #Body ----
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
    
      )
    )
  )
)

server <- function(input, output) {
  
  #Clean df for p1----
  df_p1 <- reactive(df[df$indicator_name == 'Life expectancy at birth, total (years)' &
                df$year >= input$year_range[1] & df$year <= input$year_range[2] &
                df$country_name %in% input$countries, ])
  
  #Life Expectancy by year graph----
  output$p1 <- renderPlotly({
    p1 <- plot_ly(data = df_p1(), x = ~year, y = ~value, 
                  color = ~country_name, text = ~country_name,
                  hovertemplate = paste(paste0('<extra></extra>Country: %{text}\nLife Expectancy: %{y}\nYear: %{x}')))
    p1 <- p1 %>% add_trace(type = 'scatter', mode = 'lines+markers')
    
    p1 <- p1 %>% layout(xaxis = list(title = 'Year'), 
                        yaxis = list(title = 'Life Expectancy', hoverformat = '.1f'))
    return(p1)
  })
  
}

shinyApp(ui, server)