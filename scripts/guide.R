packages <- list(
  keras = "dfalbel/keras@newdocs"
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
  
  file <- readr::read_file(path)
  file <- stringr::str_replace_all(
    file, 
    stringr::fixed("images/"), 
    "../images/"
  )
  readr::write_file(file, path)
  
}

path <- download_source(repo = packages$keras)

copy_vignette_dir <- function(name, path) {
  
  vignette_dir <- fs::dir_ls(
    path = path, 
    recurse = TRUE, 
    regexp = "/vignettes$", 
    type = "directory"
  )
  
  # modify the path for all images
  fs::dir_ls(vignette_dir, recurse = TRUE, type = "file", glob = "*.Rmd") %>% 
    purrr::walk(modify_image_path)
  
  # copy vignette dir to guide folder
  guide_dir <- file.path("content/guide", name)
  
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




