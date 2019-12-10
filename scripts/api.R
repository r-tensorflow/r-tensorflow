library(magrittr)

# Clone the package

packages <- list(
  keras = "rstudio/keras",
  tensorflow = "rstudio/tensorflow",
  tfdatasets = "rstudio/tfdatasets",
  tfruns = "rstudio/tfruns",
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

modify_pkgdown_config <- function(exdir) {
  pkg_yml <- file.path(exdir, "pkgdown", "_pkgdown.yml")

  # Edit pkgdown config
  config <- yaml::yaml.load_file(pkg_yml)
  config$template$path <- normalizePath(file.path("themes/rstudio-docs-theme/pkgdown/templates"))
  yaml::write_yaml(config, pkg_yml)
}

rebuild_reference <- function(exdir) {
  ref <- file.path(exdir, "website", "reference")
  # Build reference
  unlink(ref, recursive = TRUE)
  callr::r(function(exdir) {
    pkgdown::build_reference(exdir, lazy = FALSE, preview = FALSE)
  }, args = list(exdir = exdir))
}

modify_front_matter <- function(file, front_matter) {
  lines <- readr::read_lines(file)  
  delim <- which(lines=="---")
  lines <- lines[-c(delim[1]:delim[2])]
  
  front_matter <- yaml::as.yaml(front_matter)
  lines <- paste(lines, collapse = "\n")
  
  final <- paste("---\n", front_matter, "---\n", lines, sep = "")
  writeLines(final, file)
}

copy_reference <- function(exdir, name) {
  
  # Copy reference to the website folder
  ref <- paste0(file.path(getwd(), "content", "reference", name), "/")
  unlink(ref, recursive = TRUE)
  
  Sys.sleep(1)
  
  reference <- paste0(file.path(exdir, "website", "reference"), "/")
  if (!fs::is_dir(reference))
    reference <- paste0(file.path(exdir, "docs", "reference"), "/")
  
  fs::dir_copy(
    path = reference,
    new_path = ref
  )
  
  file.rename(
    from = file.path(ref, "index.html"),
    to = file.path(ref, "_index.html")
  )
  
  # rename all aliases from `.Rd` to `.html`.
  # a bug in the whisker package doesnt allow us to add this to hugo templating.
  fs::dir_ls(ref) %>% 
    purrr::walk(function(path) {
      
      front_matter <- rmarkdown::yaml_front_matter(path)
      
      if (length(front_matter$aliases) == 1) {
        front_matter$aliases <- stringr::str_replace_all(
          front_matter$aliases, 
          ".Rd", 
          ".html"
        )
        
        old_url <- stringr::str_split(front_matter$aliases, "/")[[1]]
        old_url <- paste(old_url[c(1,3,2,4)], collapse = "/")
        
        front_matter$aliases <- c(front_matter$aliases, old_url)
      }
      
      if (stringr::str_detect(path, "_index.html"))
        front_matter$aliases <- paste0("/", name, "/reference.html")
      
      modify_front_matter(path, front_matter)
      
    })
  
}

fix_reference_links <- function() {
  
  files <- fs::dir_ls("content/reference/", type = "file", recurse = TRUE)
  index <- fs::path_file(files) == "_index.html"
  files <- files[!index]
  
  purrr::walk(
    files,
    function(fname) {
      f <- readr::read_file(fname)
      f <- stringr::str_replace_all(f, "href='([^\\/]*)'", "href='../\\1'")
      readr::write_file(f, fname)
    }
  )
}

purrr::iwalk(packages, function(repo, name) {
  exdir <- download_source(repo)
  modify_pkgdown_config(exdir)
  rebuild_reference(exdir)
  copy_reference(exdir, name)
})

fix_reference_links()




