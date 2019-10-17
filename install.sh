# Install R dependencies

Rscript -e 'install.packages(c("remotes", "blogdown", "rprojroot", "pkgdown", "pins"),  
                             repos = "https://demo.rstudiopm.com/all/__linux__/bionic/latest")'
Rscript -e 'remotes::install_github(c("rstudio/keras",
                                      "rstudio/tensorflow",
                                      "rstudio/reticulate",
                                      "rstudio/tfdatasets",
                                      "rstudio/tfhub",
                                      "rstudio/tfds",
                                      "t-kalinowski/tfautograph"))'

# Install Python dependencies

Rscript -e 'tensorflow::install_tensorflow(
  extra_packages = c("tensorflow_hub", "tensorflow_datasets", "h5py", "pyyaml", 
                     "requests", "Pillow" , "scipy"))'
                     
Rscript -e 'tensorflow::install_tensorflow(
              version = "nightly",
              extra_packages = c("tf-hub-nightly", "tfds-nightly", "h5py", 
                                 "pyyaml", "requests", "Pillow" , "scipy"),
              envname = "nightly"
            )'


# Download/cache used datasets
# a workaround to download the dataset and avoid C stack usage errors
Rscript -e 'Sys.setenv("RETICULATE_REMAP_OUTPUT_STREAMS"=""); Sys.getenv("RETICULATE_REMAP_OUTPUT_STREAMS"); tfds::tfds_load("imdb_reviews:1.0.0")'


