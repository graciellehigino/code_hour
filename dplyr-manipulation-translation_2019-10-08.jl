## Dplyr translation exercice

# Source
# https://swcarpentry.github.io/r-novice-gapminder/13-dplyr/index.html

# Citation
#=
Thomas Wright and Naupaka Zimmerman (eds): "Software Carpentry: R for
Reproducible Scientific Analysis."  Version 2016.06, June 2016,
https://github.com/swcarpentry/r-novice-gapminder,
10.5281/zenodo.57520.
=#

using CSV, DataFrames
using RCall
using Statistics

## Import data
# Load data exported from gapminder package in R
gapminder = CSV.read("gapminder.txt")

# Send Julia element to R
@rput gapminder

## Filter data by rows using base syntax
# R code
begin
    R"""
    mean(gapminder[gapminder$continent == "Africa", "gdpPercap"])
    """
end
# Julia translation
# Need to load Statistics.jl to use mean function
mean(gapminder[gapminder.continent .== "Africa", :gdpPercap])

begin
    R"""
    mean(gapminder[gapminder$continent == "Americas", "gdpPercap"])
    """
end
mean(gapminder[gapminder.continent .== "Americas", :gdpPercap])

begin
    R"""
    mean(gapminder[gapminder$continent == "Asia", "gdpPercap"])
    """
end
mean(gapminder[gapminder.continent .== "Asia", :gdpPercap])






## The `dplyr` package

# Assignment for next week:
# translate select(), filter(), group_by() and summarize() exercices
