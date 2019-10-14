# Install R dependencies

Rscript -e 'install.packages(c("remotes", "blogdown", "rprojroot", "pkgdown"),  
                             repos = "https://demo.rstudiopm.com/all/__linux__/bionic/latest")'
Rscript -e 'remotes::install_github(c("rstudio/keras",
                                      "rstudio/tensorflow",
                                      "rstudio/reticulate",
                                      "rstudio/tfdatasets",
                                      "rstudio/tfhub",
                                      "rstudio/tfds",
                                      "t-kalinowski/tfautograph"))'

# Install Python dependencies

Rscript -e 'tensorflow::install_tensorflow()'
Rscript -e 'tfhub::install_tfhub()'
Rscript -e 'keras::install_keras()'
Rscript -e 'tfds::install_tfds()'

# Download/cache used datasets

Rscript -e 'tfds::tfds_load(
  "imdb_reviews:1.0.0", 
  split = list("train[:60%]", "train[-40%:]", "test"), 
  as_supervised = TRUE,
  data_dir = "tensorflow_datasets"
)'


