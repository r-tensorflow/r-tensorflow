Rscript -e 'install.packages(c("remotes", "blogdown", "rprojroot", "pkgdown"),  
                             repos = "https://cran.rstudio.com")'
Rscript -e 'remotes::install_github(c("rstudio/keras",
                                      "rstudio/tensorflow",
                                      "rstudio/reticulate",
                                      "rstudio/tfdatasets",
                                      "rstudio/tfhub",
                                      "rstudio/tfds"))'
Rscript -e 'tensorflow::install_tensorflow()'
