#!/bin/bash

echo "--------------------------------------"
echo "Downloading dependencies -------------"
echo "--------------------------------------"


Rscript -e "renv::restore()"

echo "--------------------------------------"
echo "Re-building the API Reference --------"
echo "--------------------------------------"

Rscript scripts/api.R

echo "--------------------------------------"
echo "Re-building the Guides ---------------"
echo "--------------------------------------"

Rscript scripts/guide.R

echo "--------------------------------------"
echo "Re-building the website --------------"
echo "--------------------------------------"

Rscript -e "blogdown::build_site()"
