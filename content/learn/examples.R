
knit_print_examples <- function(examples_dir = ".") {
  
  # get examples_yaml
  examples_yaml <- file.path(examples_dir, "examples.yml")
  
  # determine link_prefix
  if (identical(examples_dir, "."))
    link_prefix <- ""
  else
    link_prefix <- examples_dir
  
  # read the examples into a data frame
  examples <- yaml::yaml.load_file(examples_yaml)
  examples <- plyr::ldply(examples, data.frame, stringsAsFactors=FALSE)
  
  # create the link column
  link <- sprintf("[%s](%s%s.html)", examples$name, link_prefix, examples$name)
  
  # print markdown table
  knitr::kable(data.frame(
    Name = link, 
    Description = examples$description
  ))
}

