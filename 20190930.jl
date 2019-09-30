# Today we are going to get some ecological network data from Mangal and
# inspect it. Is it with the variables that we want? Is it missing something or
# does it have something we don't need?

# First, we install and load packages:
using DataFrames
using Pkg
using CSV
using Mangal


# Getting data from the GitHub Repo
# `using CSV`
data_fromGH = CSV.read(download("https://raw.githubusercontent.com/PoisotLab/BIO3043-6037/master/_data/mangal_data.dat"))

# Look at the entire data set
show(data_fromGH, allrows=true, allcols=true)


# Filter predation more than zero
iszero.(data_fromGH.predation) # which observations are not zero
filter(x -> x[:predation] > 0, data_fromGH)


#### Testing some Mangal functions
count(MangalNetwork)
# Retrive Havens dataset
Havens_data = first(datasets("q" => "havens"))
