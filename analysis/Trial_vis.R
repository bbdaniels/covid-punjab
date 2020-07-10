## July 5, 2020
## Trying out visualizations based on ICMR data

library(tidyverse)
library(grid)
library(rdgal)
library(sp)
library(sf)
library(ggspatial)
library(rvest)
library(tmap)
library(rgeos)
library(maptools)
library(rvest)
library(magrittr)
library(ggplot2)
library(maps)
library(ggmap)
library(openintro)
library(ggthemes)
library(httr)
library(jsonlite)
library(xml2)
library(tigris)
library(gridExtra)
library(jsonlite)
library(RJSONIO)
library(XML)
library(gganimate)
library(readtext)
library(gtable)
library(gifski)

# load ICMR data
ICMR <- read.csv("/Users/violagattiroaf/Desktop/PUNJABCOVID19/ICMR/icmr_clean.csv")

## tables and checks
table(icmr$age)

## Replicate total tests done graphic
icmr <- ICMR
# create bins for age
icmr$age <- cut(x = icmr$age, breaks = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90))
levels(icmr$age) <- c("0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90+")
# rename factors in symptom_status
icmr$symptom_status <- as.factor(icmr$symptom_status)
levels(icmr$symptom_status) <- c("Asymptomatic", "Symptomatic")
# count total tests collected by age, gender, and symptom status
icmr <- icmr %>%
  filter(age != "NA", gender != "", gender != "T", symptom_status != "NA") %>%
  group_by(age, gender, symptom_status) %>%
  count()
# plot total tests
ggplot(icmr, aes(x = gender, y = n, fill = symptom_status)) + 
  geom_bar(stat = "identity", width = 0.9, position = "dodge") +
  facet_wrap(~age, strip.position = "bottom", scales = "free_x", nrow = 1) +
  theme_classic() + theme(panel.spacing = unit(0, "lines"), strip.background = element_blank(), strip.placement = "outside") +
  scale_fill_manual(values = c("black", "red"))

# Make animation by date
icmr <- ICMR

icmr$age <- cut(x = icmr$age, breaks = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90))
levels(icmr$age) <- c("0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90+")
icmr$symptom_status <- as.factor(icmr$symptom_status)
levels(icmr$symptom_status) <- c("Asymptomatic", "Symptomatic")

icmr <- icmr %>%
  mutate(Date = as.Date(icmr$DateofSampleCollection_1, format = "%m/%d/%y")) %>%
  filter(age != "NA", gender != "", gender != "T", symptom_status != "NA") %>%
  group_by(age, gender, symptom_status, Date) %>%
  count() %>%
  filter(Date >= "2020-03-24")

#w/o animation for aesthetics
ggplot(icmr, aes(x = gender, y = n, fill = symptom_status)) + 
  geom_bar(stat = "identity", width = 0.9, position = "dodge") +
  facet_wrap(~age, strip.position = "bottom", scales = "free_x", nrow = 1) +
  theme_classic() + theme(panel.spacing = unit(0, "lines"), strip.background = element_blank(), strip.placement = "outside") +
  scale_fill_manual(values = c("black", "red")) + 
  labs(title = "Total Tests Administered", y = "Number of Tests", fill = "") + 
  theme(legend.position = c(0.8, 0.8))

# w animation
ggplot(icmr, aes(x = gender, y = n, fill = symptom_status)) + 
  geom_bar(stat = "identity", width = 0.9, position = "dodge") +
  facet_wrap(~age, strip.position = "bottom", scales = "free_x", nrow = 1) +
  theme_classic() + theme(panel.spacing = unit(0, "lines"), strip.background = element_blank(), strip.placement = "outside") +
  scale_fill_manual(values = c("black", "red")) + transition_time(Date) + 
  labs(title = "Total Tests Administered on {frame_time}", y = "Number of Tests", fill = "") + theme(legend.position = c(0.8, 0.8))
