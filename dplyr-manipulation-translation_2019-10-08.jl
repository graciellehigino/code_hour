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
# Simple piping example
gapminder |> nrow
# Julia piping translation, requires anonymous function (x -> ...)
year_country_gdp = gapminder |> x -> select(x, [:year, :country, :gdpPercap])

# Pipe.jl offers an alternative syntax
#=
using Pipe
year_country_gdp = @pipe gapminder |> select(_, [:year, :country, :gdpPercap])
=#

## Example where piping in Julia might be relevant:
# Applying changes in column names
newnames = names(gapminder) .|> # . is needed to broadcast piping on array elements
    string .|> # has to be converted to string first
    uppercasefirst .|> # convert first letter to uppercase
    Symbol # has to be converted back to Symbol
# Alternative 1 line call
newnames = Symbol.(uppercasefirst.(string.(names(gapminder)))) # maybe too long and confusing
# Change column names (temporary)
rename(gapminder, names(gapminder) .=> newnames)

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
year_country_gdp_euro = @pipe gapminder |>
    filter(y -> y.continent == "Europe", _) |>
    select(_, [:year, :country, :gdpPercap])
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

## Using `group_by` and `summarize`
begin
    R"""
    str(gapminder)
    """
end
describe(gapminder)
# no exact translation for `str()`

begin
    R"""
    str(gapminder %>% group_by(continent))
    """
end
groupby(gapminder, :continent)

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
    x -> [mean(group.gdpPercap) for group in x] # inline for-loop
# Same with long format for-loop
for group in groupby(gapminder, :continent)
    result = mean(group.gdpPercap)
    println(result)
end
# Julia-esque translation
gdp_bycontinents = by(gapminder, :continent, :gdpPercap => mean)
# Additionnal `sort` example
sort(by(gapminder, :continent, nrow), :x1)

## Challenge 2
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
# Julia translation
lifeExp_bycountry = by(gapminder, :country, mean_lifeExp = :lifeExp => mean)
sort(lifeExp_bycountry, :mean_lifeExp)[[1,end],:]

## Using `group_by` and `summarize` on multiple columns
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


## count() and n()

begin
    R"""
    gapminder %>%
        filter(year == 2002) %>%
        count(continent, sort = TRUE)
    """
end

gapminder |>
    x -> filter(y -> y.year == 2002, x) |>
    x -> by(x, :continent,
    count = :continent => length) |>
    x -> sort(x, :count, rev = true)

sort(by(gapminder[gapminder.year .== 2002,:], :continent, count = :continent => length), :count, rev = true)


begin
    R"""
    gapminder %>%
        group_by(continent) %>%
        summarize(se_le = sd(lifeExp)/sqrt(n()))
    """
end

gapminder |>
    x -> by(x, :continent, se_le = [:continent, :lifeExp] =>
                            x -> std(x.lifeExp)/sqrt(length(x.continent)), sort = true)

begin
    R"""
    gapminder %>%
        group_by(continent) %>%
        summarize(
          mean_le = mean(lifeExp),
          min_le = min(lifeExp),
          max_le = max(lifeExp),
          se_le = sd(lifeExp)/sqrt(n()))
    """
end



## Using mutate()
begin
    R"""
    gdp_pop_bycontinents_byyear <- gapminder %>%
        mutate(gdp_billion = gdpPercap*pop/10^9) %>%
        group_by(continent,year) %>%
        summarize(mean_gdpPercap = mean(gdpPercap),
                  sd_gdpPercap = sd(gdpPercap),
                  mean_pop = mean(pop),
                  sd_pop = sd(pop),
                  mean_gdp_billion = mean(gdp_billion),
                  sd_gdp_billion = sd(gdp_billion))
    """
end

gapminder.gdp_billion = gapminder.gdpPercap .* gapminder.pop ./ 10^9


insertcols!(gapminder, ncol(gapminder)+1, gdp_billion15 = gapminder.gdpPercap .* gapminder.pop ./ 10^9)
insertcols!(gapminder, ncol(gapminder)+1, gdp_billion17 = [:gdpPercap, :pop] =>
                                            x -> x.gdpPercap * x.pop / 10^9)

## Connect mutate with logical filtering: ifelse

begin
    R"""
    ## keeping all data but "filtering" after a certain condition
    # calculate GDP only for people with a life expectation above 25
    gdp_pop_bycontinents_byyear_above25 <- gapminder %>%
        mutate(gdp_billion = ifelse(lifeExp > 25, gdpPercap * pop / 10^9, NA)) %>%
        group_by(continent, year) %>%
        summarize(mean_gdpPercap = mean(gdpPercap),
                  sd_gdpPercap = sd(gdpPercap),
                  mean_pop = mean(pop),
                  sd_pop = sd(pop),
                  mean_gdp_billion = mean(gdp_billion),
                  sd_gdp_billion = sd(gdp_billion))
    """
end

gdp_pop_bycontinents_byyear_above25 = insertcols!(gapminder, ncol(gapminder) + 1, gdp_billion = ifelse.(gapminder.lifeExp .> 25, gapminder.gdpPercap .* gapminder.pop ./ 10^9, missing)) |>
        x -> by(x, [:continent, :year], [:gdpPercap, :pop, :gdp_billion] =>
             x -> (mean_gdpPercap = mean(x.gdpPercap),
                   sd_gdpPercap = std(x.gdpPercap),
                   mean_pop = mean(x.pop),
                   sd_pop = std(x.pop),
                   mean_gdp_billion = mean(x.gdp_billion),
                   sd_gdp_billion = std(x.gdp_billion)))

# Probably a bit less confusing
gapminder.gdp_billion = ifelse.(gapminder.lifeExp .> 25, gapminder.gdpPercap .* gapminder.pop ./ 10^9, missing)
gdp_pop_bycontinents_byyear_above25 = by(gapminder, [:continent, :year], [:gdpPercap, :pop, :gdp_billion] =>
     x -> (mean_gdpPercap = mean(x.gdpPercap),
           sd_gdpPercap = std(x.gdpPercap),
           mean_pop = mean(x.pop),
           sd_pop = std(x.pop),
           mean_gdp_billion = mean(x.gdp_billion),
           sd_gdp_billion = std(x.gdp_billion)))

# Alternative to ifelse: ternary operator ?:
@time map(x -> x.lifeExp > 25 ? x.gdpPercap .* x.pop ./ 10^9 : missing, eachrow(gapminder));
@time ifelse.(gapminder.lifeExp .> 25, gapminder.gdpPercap .* gapminder.pop ./ 10^9, missing);
# Much less efficient in this case because of map() and eachrow(), but can be useful in other situations
# Example: print smallest variable
a = 1
b = 2
@time a < b ? "a" : "b"
@time ifelse(a < b, "a", "b")

## updating only if certain condition is fullfilled
# for life expectations above 40 years, the gpd to be expected in the future is scaled
begin
    R"""
    gdp_future_bycontinents_byyear_high_lifeExp <- gapminder %>%
        mutate(gdp_futureExpectation = ifelse(lifeExp > 40, gdpPercap * 1.5, gdpPercap)) %>%
        group_by(continent, year) %>%
        summarize(mean_gdpPercap = mean(gdpPercap),
                mean_gdpPercap_expected = mean(gdp_futureExpectation))
    """
end

gapminder.gdp_futureExpectation = ifelse.(gapminder.lifeExp .> 40, gapminder.gdpPercap .* 1.5, gapminder.gdpPercap)
gdp_future_bycontinents_byyear_high_lifeExp = by(gapminder, [:continent, :year], [:gdpPercap, :gdp_futureExpectation] =>
     x -> (mean_gdpPercap = mean(x.gdpPercap),
           mean_gdpPercap_expected = mean(x.gdp_futureExpectation)))



#### Combining dplyr and ggplot2

begin
    R"""
    library("ggplot2")
    """
end

begin
    R"""
    # Get the start letter of each country
    starts.with <- substr(gapminder$country, start = 1, stop = 1)
    # Filter countries that start with "A" or "Z"
    az.countries <- gapminder[starts.with %in% c("A", "Z"), ]
    # Make the plot
    ggplot(data = az.countries, aes(x = year, y = lifeExp, color = continent)) +
        geom_line() + facet_wrap( ~ country)
  """
end

using Gadfly

# Option 1
starts_with = string.(first.(gapminder.country))
az_countries = gapminder[map(x -> in(x, ["A", "Z"]), starts_with), :]
az_countries = gapminder[[in(s, ["A", "Z"]) for s in starts_with], :]
# Option 2 with regular expression
az_countries = gapminder[startswith.(gapminder.country, r"A|Z"), :]
az_countries = filter(x -> startswith(x.country, r"A|Z"), gapminder)
