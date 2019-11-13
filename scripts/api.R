# Clone the package

packages <- list(
  keras = "rstudio/keras",
  tensorflow = "rstudio/tensorflow",
  tfdatasets = "rstudio/tfdatasets"
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
      lines <- readLines(path)
      alias <- which(stringr::str_detect(lines, "aliases:"))
      if (length(alias) == 1) {
        lines[alias] <- stringr::str_replace_all(lines[alias], ".Rd", ".html")
        writeLines(lines, path)
      }
    })
  
}

purrr::iwalk(packages, function(repo, name) {
  exdir <- download_source(repo)
  modify_pkgdown_config(exdir)
  rebuild_reference(exdir)
  copy_reference(exdir, name)
})




