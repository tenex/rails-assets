# Rails Assets ![Build Status](https://circleci.com/gh/rails-assets/rails-assets.png?circle-token=3eec67ef0c9bf5973d6d074091e9f4065c7bd0b2)

> [Bundler](http://bundler.io) to [Bower](http://bower.io) proxy

This README concerns the development aspect of the project. **[Visit the site](http://rails-assets.org) to learn how to use Rails Assets in your application.**

## Development

### Setup

```sh
git clone git@github.com:rails-assets/rails-assets.git && cd $_
bundle install && npm install
ln -sf ../data/{latest_specs.4.8.gz,prerelease_specs.4.8.gz,quick,specs.4.8.gz,gems} public
foreman start
```

### Convert Bower package into Ruby gem using CLI

```sh
rake "convert[NAME]"
```

This will create `rails-assets-NAME-VERSION.gem` file.

### Symlinks

```
/gems                       -> DATA_DIR/gems
/quick                      -> DATA_DIR/quick
/latest_specs.4.8.gz        -> DATA_DIR/latest_specs.4.8.gz
/prerelease_specs.4.8.gz    -> DATA_DIR/prerelease_specs.4.8.gz
/specs.4.8.gz               -> DATA_DIR/specs.4.8.gz
```

## Credits

Rails Assets *used to* be the fork of [Gem in a Box](https://github.com/geminabox/geminabox).

---

Created by [@teamon](http://github.com/teamon) and [@porada](http://github.com/porada).

Thanks for help to [@sheerun](http://github.com/sheerun), [@jandudulski](http://github.com/jandudulski) and [contributors](https://github.com/rails-assets/rails-assets/graphs/contributors).
