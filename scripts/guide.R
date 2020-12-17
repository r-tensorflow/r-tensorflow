library(magrittr)

packages <- list(
  keras = "rstudio/keras",
  tfdatasets = "rstudio/tfdatasets",
  tfhub = "rstudio/tfhub",
  cloudml = "rstudio/cloudml"
)

download_source <- function(repo) {
  # download the source
  file <- remotes:::remote_download(remotes:::github_remote(repo))
  exdir <- tempfile()
  fs::dir_create(path = exdir)
  # extracts the downloaded package a temporary directory
  untar(file, exdir = exdir)
  fs::dir_ls(exdir)
}

modify_image_path <- function(path) {
  
  # only modify if the file is not the index.
  if (fs::path_file(path) == "index.Rmd")
    return(NULL)
  
  file <- readr::read_file(path)
  file <- stringr::str_replace_all(
    file, 
    "([^_])(images/)", 
    "\\1../images/"
  )
  readr::write_file(file, path)
  
}

modify_vignette_references <- function(path) {
  
  if (fs::path_file(path) == "index.Rmd")
    return(NULL)
  
  file <- readr::read_file(path)
  
  # file <- c("(cover.html)",
  # "(/cover/hello.html)", "hsjahsja (only of each) sahsjha .html")
  file <- stringr::str_replace_all(
    file, 
    "\\(([^\\/\\)]*)\\.html\\)", 
    "(../\\1/)"
  )
  readr::write_file(file, path)
  
}

copy_vignette_dir <- function(name, path) {
  
  vignette_dir <- fs::dir_ls(
    path = path, 
    recurse = TRUE, 
    regexp = "/vignettes$", 
    type = "directory"
  )
  
  # modify the path for all images
  fs::dir_ls(vignette_dir, recurse = TRUE, type = "file", glob = "*.Rmd") %>% 
    purrr::walk(modify_image_path) %>% 
    purrr::walk(modify_vignette_references)
  
  # copy vignette dir to guide folder
  if (name != "cloudml")
    guide_dir <- file.path("content/guide", name)
  else
    guide_dir <- file.path("content/tools", name)
  
  if (!fs::dir_exists(guide_dir))
    fs::dir_create(guide_dir)
  
  fs::dir_ls(guide_dir, recurse = TRUE, type = "file") %>% 
    fs::file_delete()
  
  files <- fs::dir_ls(vignette_dir, recurse = TRUE, type = "file")
  
  new_files <- stringr::str_replace(files, stringr::fixed(as.character(vignette_dir)), guide_dir)
  # copy index.Rmd as _index.Rmd
  new_files <- stringr::str_replace(
    new_files, 
    stringr::fixed("/index.Rmd"), 
    "/_index.Rmd"
  )
  
  # create all necessary dirs
  dirs <- fs::path_dir(new_files) %>% unique() %>% sort()
  purrr::walk(dirs, function(path) {
    if(!fs::dir_exists(path))
      fs::dir_create(path)
  })
  
  # copy
  fs::file_copy(
    files,
    new_files,
    overwrite = TRUE
  )
}

purrr::iwalk(packages, function(repo, name) {
  exdir <- download_source(repo)
  copy_vignette_dir(name, exdir)
})




