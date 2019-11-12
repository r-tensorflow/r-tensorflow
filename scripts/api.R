# Clone the package
git2r::clone(
  "https://github.com/rstudio/keras", 
  local_path = path.expand("~/Desktop/packages")
)

# Edit pkgdown config
config <- yaml::yaml.load_file("~/Desktop/packages/pkgdown/_pkgdown.yml")
config$template$path <- normalizePath(file.path("themes/rstudio-docs-theme/pkgdown/templates"))
yaml::write_yaml(config, "~/Desktop/packages/pkgdown/_pkgdown.yml")

# Build reference
unlink("~/Desktop/packages/website/reference/", recursive = TRUE)
pkgdown::build_reference("~/Desktop/packages/", lazy = FALSE, preview = FALSE)

# Copy reference to the website folder
unlink("content/reference/keras/", recursive = TRUE)
fs::dir_copy(
  path = "~/Desktop/packages/website/reference/",
  new_path = "content/reference/keras"
  )

file.rename(
  from = "content/reference/keras/index.html", 
  to = "content/reference/keras/_index.html"
)

# rename all aliases from `.Rd` to `.html`.
# a bug in the whisker package doesnt allow us to add this to hugo templating.
fs::dir_ls("content/reference/keras/") %>% 
  purrr::walk(function(path) {
    lines <- readLines(path)
    alias <- which(stringr::str_detect(lines, "aliases:"))
    if (length(alias) == 1) {
      lines[alias] <- stringr::str_replace_all(lines[alias], ".Rd", ".html")
      writeLines(lines, path)
    }
  })



