Rscript -e 'install.packages(c("remotes", "blogdown", "rprojroot", "pkgdown"),  
                             repos = "https://demo.rstudiopm.com/all/__linux__/bionic/latest")'
Rscript -e 'remotes::install_github(c("rstudio/keras",
                                      "rstudio/tensorflow",
                                      "rstudio/reticulate",
                                      "rstudio/tfdatasets",
                                      "rstudio/tfhub",
                                      "rstudio/tfds"))'
Rscript -e 'tensorflow::install_tensorflow()'
