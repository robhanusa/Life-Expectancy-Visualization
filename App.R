library(shiny)
library(shinydashboard)
library(tidyverse)
library(plotly)
library(reshape)
library(ivmte)

df <- read.csv('Data.csv')

#Initial cleaning to remove indicators (rows) were not interested in
# indicators <- c('Life expectancy at birth, total (years)',
#                 'Current health expenditure per capita (current US$)',
#                 'Prevalence of overweight (% of adults)')
# df <- df[df$indicator_name %in% indicators, ]


chosen_year <- 2000
metric <- 'Current health expenditure per capita (current US$)'

df_p2 <- df[df$year == chosen_year, ]
df_p2_wide <- cast(df_p2, country_name~indicator_name)

#filter based on selected metrics

#Create vector of metrics from dataframe. 
metrics_names <- colnames(df_p2_wide)

#replace column names with first word only, as column names without spaces or special
#characters are easier to manage
metrics_abbr <- sub(' .*','',metrics_names)
names(df_p2_wide) <- metrics_abbr
metrics_names_list <- as.list(metrics_names)
metrics_abbr_list <- as.list(metrics_abbr)
names(metrics_abbr_list) <- metrics_names_list

p2 <- ggplot(data = df_p2_wide, aes_string(x = metrics_abbr_list[[metric]], 
                                           y = 'Life',
                                           text = 'country_name')) +
  geom_point()+
  xlab(metric)+
  ylab('Life Expectancy')
              
ggplotly(p2, tooltip = 'text')

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
    sliderInput('year_range', 'Indicate Year Range', 1970, 2020, step = 1,
                value = c(1970,2018), sep = ""),
    selectInput('countries', label = 'Select Contries to Graph', multiple = TRUE,
                choices = sort(unique(df$country_name)),
                selected = c('United States', 'Belgium', 'France')),
    selectInput('metric', 'Select metric:', choices = sort(unique(df$indicator_name)[-3]))
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
        plotlyOutput('p2')
    
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
  
  #Clean df for p2----
  df_p2 <- reactive(df[df$year == 2010, ])
  df_p2_wide <- reactive(cast(df_p2(), country_name~indicator_name))

  make_metric_abbrs <- function(df_temp) {
    #Create vector of metrics from dataframe. 
    metrics_names <- colnames(df_temp)
    
    #replace column names with first word only, as column names without spaces or special
    #characters are easier to manage
    metrics_abbr <- sub(' .*','',metrics_names)
    names(df_temp) <- metrics_abbr
    metrics_names_list <- as.list(metrics_names)
    metrics_abbr_list <- as.list(metrics_abbr)
    names(metrics_abbr_list) <- metrics_names_list
    
    return(metrics_abbr_list)
  }
  
  metrics_abbr_list <- reactive(make_metric_abbrs(df_p2_wide()))
  
  change_col_names <- function(df_temp) {
    names(df_temp) <- metrics_abbr_list()
    return(df_temp)
  }
  
  df_p2_wide2 <- reactive(change_col_names(df_p2_wide()))
  
  output$p2 <- renderPlotly({
    p2 <- ggplot(data = df_p2_wide2(), aes_string(x = metrics_abbr_list()[[input$metric]], 
                                                 y = 'Life',
                                                 text = 'country_name')) +
      geom_point()+
      xlab(input$metric)+
      ylab('Life Expectancy')+
      ggtitle('Life expectancy compared to selected factors per country in 2010')+
      theme(plot.title = element_text(hjust = 0.5))
    
    ggplotly(p2, tooltip = 'text')
  })
}

shinyApp(ui, server)