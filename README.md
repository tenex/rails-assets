## Rails Assets - Bundler to Bower proxy

The final solution to managing asset dependencies in your rails apps

### Setup

Add new source to your app's `Gemfile`

    # Gemfile
    source "http://rails-assets.org"


Then add bower packages as gems following the convention:

`RUBY_GEM_NAME = rails-assets-BOWER_PACKAGE_NAME`

Examples:

    # Gemfile
    gem "rails-assets-angular"
    gem "rails-assets-jquery.cookie"
    gem "rails-assets-leaflet"

And then just simply run `bundle install`.

### Using assets

    # app/assets/application.js
    //= require angular
    //= require jquery.cookie
    //= require leaflet

    # app/assets/application.css
    *= require leaflet


Check out [example rails app](https://github.com/rails-assets/rails-assets/tree/master/test-app)



### How it works

When bundler requests gem that wasn't yet converted rails-assets server
downloads correct package using bower and repackages it as valid ruby gem.


### Development

### Setup

    git clone git@github.com:rails-assets/rails-assets.git
    cd rails-assets
    bundle
    ln -sf ../data/{latest_specs.4.8.gz,prerelease_specs.4.8.gz,quick,specs.4.8.gz,gems} public
    foreman start

### Convert bower package to gem using command line

    rake convert[NAME]

This will create `rails-assets-NAME-VERSION.gem` file



## Symlinks

```
/gems                       -> DATA_DIR/gems
/quick                      -> DATA_DIR/quick
/latest_specs.4.8.gz        -> DATA_DIR/latest_specs.4.8.gz
/prerelease_specs.4.8.gz    -> DATA_DIR/prerelease_specs.4.8.gz
/specs.4.8.gz               -> DATA_DIR/specs.4.8.gz
```
