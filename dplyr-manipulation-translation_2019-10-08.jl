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


#### The `dplyr` package
begin
    R"""
    library(dplyr)
    """
end

## Using `select()`
begin
    R"""
    year_country_gdp <- select(gapminder, year, country, gdpPercap)
    """
end
year_country_gdp = select(gapminder, [:year, :country, :gdpPercap])

begin
    R"""
    year_country_gdp <- gapminder %>% select(year, country, gdpPercap)
    """
end
year_country_gdp = gapminder |> x -> select(x, [:year, :country, :gdpPercap])
# Pipe.jl offers an alternative syntax
#=
using Pipe
@pipe year_country_gdp <- gapminder |> select(_, [:year, :country, :gdpPercap])
=#

## Using `filter()`
begin
    R"""
    year_country_gdp_euro <- gapminder %>%
        filter(continent == "Europe") %>%
        select(year, country, gdpPercap)
    """
end
# Exact translation
year_country_gdp_euro = gapminder |>
    x -> filter(y -> y.continent == "Europe", x) |>
    x -> select(x, [:year, :country, :gdpPercap])
# Julia-esque translation
year_country_gdp_euro = filter(y -> y.continent == "Europe", gapminder)
# OR
year_country_gdp_euro = copy(gapminder)
filter!(y -> y.continent == "Europe", year_country_gdp_euro)
# Then
select!(year_country_gdp_euro, [:year, :country, :gdpPercap])

## Challenge 1
begin
    R"""
    year_country_lifeExp_Africa <- gapminder %>%
                           filter(continent == "Africa") %>%
                           select(year, country, lifeExp)
    """
end
year_country_lifeExp_africa = gapminder |>
    x -> filter(y -> y.continent == "Africa", x) |>
    x -> select(x, [:lifeExp, :country, :year])

# Using `group_by` and `summarize`
begin
    R"""
    str(gapminder)
    """
end
describe(gapminder)

begin
    R"""
    str(gapminder %>% group_by(continent))
    """
end
groupby(gapminder, :continent)
# no exact translation for `str()`

begin
    R"""
    gdp_bycontinents <- gapminder %>%
    group_by(continent) %>%
    summarize(mean_gdpPercap = mean(gdpPercap))
    """
end
# Exact translation
gdp_bycontinents = gapminder |>
    x -> groupby(x, :continent) |>
    x -> [mean(y.gdpPercap) for y in x]
# Julia-esque translaton 1
by(gapminder, :continent, mean_gdpPercap = :gdpPercap => mean)

# Challenge 2
begin
    R"""
    lifeExp_bycountry <- gapminder %>%
        group_by(country) %>%
        summarize(mean_lifeExp = mean(lifeExp))
    """
    R"""
    lifeExp_bycountry %>%
        filter(mean_lifeExp == min(mean_lifeExp) | mean_lifeExp == max(mean_lifeExp))
    """
end
lifeExp_bycountry = by(gapminder, :country, mean_lifeExp = :lifeExp => mean)
sort(lifeExp_bycountry, :mean_lifeExp)[[1,end],:]
#

begin
    R"""
    gdp_bycontinents_byyear <- gapminder %>%
        group_by(continent, year) %>%
        summarize(mean_gdpPercap = mean(gdpPercap))
    """
end
by(gapminder, [:continent, :year], mean_gdpPercap = :gdpPercap => mean)

begin
    R"""
    gdp_pop_bycontinents_byyear <- gapminder %>%
    group_by(continent, year) %>%
        summarize(mean_gdpPercap = mean(gdpPercap),
                  sd_gdpPercap = sd(gdpPercap),
                  mean_pop = mean(pop),
                  sd_pop = sd(pop))
    """
end
gdp_pop_bycontinents_byyear = by(gapminder, [:continent, :year], [:gdpPercap, :pop] =>
                                    x -> (mean_gdpPercap = mean(x.gdpPercap),
                                          sd_gdpPercap = std(x.gdpPercap),
                                          mean_pop = mean(x.pop),
                                          sd_pop = std(x.pop)));
sort(gdp_pop_bycontinents_byyear, :continent)
