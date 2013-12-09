# Rails Assets [![Build Status](https://travis-ci.org/rails-assets/rails-assets.png)](https://travis-ci.org/rails-assets/rails-assets)

> [Bundler](http://bundler.io) to [Bower](http://bower.io) proxy

This README concerns the development aspect of the project. **[Visit the site](http://rails-assets.org) to learn how to use Rails Assets in your application.**

## Development

### Setup

```sh
git clone git@github.com:rails-assets/rails-assets.git && cd rails-assets
bundle install && npm install
foreman start
```

### Convert Bower package into Ruby gem using CLI

```sh
bundle exec rake 'component:convert[jquery,2.0.3]'
```

This will create `rails-assets-NAME-VERSION.gem` file.

You can remove this component by issuing:

```sh
bundle exec rake 'component:destroy[jquery,2.0.3]'
```

## Credits

Rails Assets *used to* be the fork of [Gem in a Box](https://github.com/geminabox/geminabox).

---

Created by [@teamon](http://github.com/teamon), [@sheerun](http://github.com/sheerun), and [@porada](http://github.com/porada).

Thanks for help to [@jandudulski](http://github.com/jandudulski) and [contributors](https://github.com/rails-assets/rails-assets/graphs/contributors).
