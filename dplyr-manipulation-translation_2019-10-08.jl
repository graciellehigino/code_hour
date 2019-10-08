# Source
# https://swcarpentry.github.io/r-novice-gapminder/13-dplyr/index.html

# Citation
#=
Thomas Wright and Naupaka Zimmerman (eds): "Software Carpentry: R for
Reproducible Scientific Analysis."  Version 2016.06, June 2016,
https://github.com/swcarpentry/r-novice-gapminder,
10.5281/zenodo.57520.
=#

# Import data
# Gapminder package in R
using CSV, DataFrames
using RCall
using Statistics

gapminder = CSV.read("gapminder.txt")

# $rnorm(100,42,2)

# Send Julia element to R
@rput gapminder

## Filter data by rows
R"""
mean(gapminder[gapminder$continent == "Africa", "gdpPercap"])
"""
# Need to load Statistics.jl to use mean function
mean(gapminder[gapminder.continent .== "Africa", :gdpPercap])


R"""
mean(gapminder[gapminder$continent == "Americas", "gdpPercap"])
"""

mean(gapminder[gapminder.continent .== "Americas", :gdpPercap])

R"""
mean(gapminder[gapminder$continent == "Asia", "gdpPercap"])
"""

mean(gapminder[gapminder.continent .== "Asia", :gdpPercap])



## The `dplyr` package

# Assignment for next week:
# translate select(), filter(), group_by() and summarize() exercices
