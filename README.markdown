# Gem in a Box – Really simple rubygem hosting
[![Build Status](https://secure.travis-ci.org/cwninja/geminabox.png)](http://travis-ci.org/cwninja/geminabox)
[![Gem Version](https://badge.fury.io/rb/geminabox.png)](http://badge.fury.io/rb/geminabox)

Geminabox lets you host your own gems, and push new gems to it just like with rubygems.org.
The bundler dependencies API is supported out of the box.
Authentication is left up to either the web server, or the Rack stack.
For basic auth, try [Rack::Auth](http://rack.rubyforge.org/doc/Rack/Auth/Basic.html).

![screen shot](http://pics.tomlea.co.uk/bbbba6/geminabox.png)

## System Requirements

    Tested on Mac OS X 10.8.2
    Ruby 1.9.3-392

    Tests fail on Ruby 2.0.0-p0

## Server Setup

    gem install geminabox

Create a config.ru as follows:

    require "rubygems"
    require "geminabox"

    Geminabox.data = "/var/geminabox-data" # ... or wherever
    run Geminabox

Start your gem server with 'rackup' to run WEBrick or hook up the config.ru as you normally would ([passenger][passenger], [thin][thin], [unicorn][unicorn], whatever floats your boat).

## Legacy RubyGems index

RubyGems supports generating indexes for the so called legacy versions (< 1.2), and since it is very rare to use such versions nowadays, it can be disabled, thus improving indexing times for large repositories. If it's safe for your application, you can disable support for these legacy versions by adding the following configuration to your config.ru file:

    Geminabox.build_legacy = false

## Client Usage

    gem install geminabox

    gem inabox pkg/my-awesome-gem-1.0.gem

Configure Gem in a box (interactive prompt to specify where to upload to):

    geminabox -c

Change the host to upload to:

    geminabox -g HOST

Simples!

## Command Line Help

    Usage: gem inabox GEM [options]

      Options:
        -c, --configure                  Configure GemInABox
        -g, --host HOST                  Host to upload to.
        -o, --overwrite                  Overwrite Gem.


      Common Options:
        -h, --help                       Get help on this command
        -V, --[no-]verbose               Set the verbose level of output
        -q, --quiet                      Silence commands
            --config-file FILE           Use this config file instead of default
            --backtrace                  Show stack backtrace on errors
            --debug                      Turn on Ruby debugging


      Arguments:
        GEM       built gem to push up

      Summary:
        Push a gem up to your GemInABox

      Description:
        Push a gem up to your GemInABox

## Licence

Fork it, mod it, choose it, use it, make it better. All under the [do what the fuck you want to + beer/pizza public license][WTFBPPL].

[WTFBPPL]: http://tomlea.co.uk/WTFBPPL.txt
[sinatra]: http://www.sinatrarb.com/
[passenger]: http://www.modrails.com/
[thin]: http://code.macournoyer.com/thin/
[unicorn]: http://unicorn.bogomips.org/
