
__To update site:__


__1. Make sure you have `hugo` v. 0.24 installed!__


```
blogdown::install_hugo(version = "0.24")
```


__2. Use `scripts/copy_docs.R` to sync external content from the following packages:__

- tfestimators
- keras
- tensorflow
- tfruns
- cloudml
- tfdatasets
- tfdeploy


E.g.

```
copy_docs("tfestimators")
copy_docs("keras")
```

This script assumes you have these packages installed in `~/packages`.
One way to deal with this would be creating symlinks, in the way of

```
$ pwd
/home/me/packages
$ ln -s ../path/to/keras .
```

The script may directly be sourced in the IDE.


__3. Some content exists here only and has to be edited directly.__

E.g.

`content/tensorflow`
`content/tools`


__4. Use `blogdown::serve_site()` to regenerate the site.__



-----------------------------------------------------------------------------


Q: Is this still valid?

### Search Index

npm install
node ./buildSearchIndex.js 

To preview the site/post just type this in the console: `blogdown::serve_site()`.
