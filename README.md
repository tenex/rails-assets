# Rails Assets [![Build Status](https://travis-ci.org/tenex/rails-assets.svg?branch=master)](https://travis-ci.org/tenex/rails-assets)

> [Bundler](http://bundler.io) to [Bower](http://bower.io) proxy

This README concerns the development aspect of the project. **[Visit the site](https://rails-assets.org) to learn how to use Rails Assets in your application.**

## Development

### Setup

```sh
git clone git@github.com:tenex/rails-assets.git && cd rails-assets
bundle install && npm install
cp config/database{.sample,}.yml
cp config/application{.sample,}.yml
# edit config/database.yml and config/application.yml if necessary.
bin/rake db:setup
foreman start
```

### Headless chrome

`rspec` tests will use `capybara` for tests. Capybara's driver is set
up to use `selenium` with headless Chrome. Therefore, you will need
Chrome and the Chrome Selenium web driver.

``` sh
# get chrome
cat << EOF > /etc/apt/sources.list.d/google-chrome.list
deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main
EOF
wget -O- https://dl.google.com/linux/linux_signing_key.pub |gpg
--dearmor > /etc/apt/trusted.gpg.d/google.gpg
apt update && apt install -y google-chrome-stable
# get appropriate driver
chrome_version="$(google-chrome --version | cut -d ' ' -f3)" # Google Chrome 103.0.5060.53 -> 103.0.5060.53
(wget "https://chromedriver.storage.googleapis.com/${chrome_version}/chromedriver_linux64.zip" &&
 unzip chromedriver_linux64.zip -d /usr/local/bin)
```

### Convert Bower package into Ruby gem using CLI

```sh
bin/rake 'component:convert[jquery,2.0.3]'
```

This will create `rails-assets-NAME-VERSION.gem` file.

You can remove this component by:

```sh
bin/rake 'component:destroy[jquery,2.0.3]'
```


## Gems with a .js in their name

For packages from bower that have a .js in their name like [typeahead.js](https://github.com/twitter/typeahead.js) which can generate a gem with the name rails-assets-typehead.js if You want to use this gem with Rails 4.2 or higher in order for your gem to work in your application.js you have to require it as follow

```
//= require typeahead.js.js
```

instead of

```
//= require typeahead.js
```

## Credits

Maintained by Tenex Developers [@tenex](http://github.com/tenex).

Originally created by [@teamon](http://github.com/teamon), [@porada](http://github.com/porada) and [@sheerun](http://github.com/sheerun), with the help of [contributors](https://github.com/tenex/rails-assets/graphs/contributors). :heart:

Please don’t tweet bugs to us—[report an issue](https://github.com/tenex/rails-assets/issues) instead. :v:
