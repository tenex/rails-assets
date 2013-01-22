# Gem in a Box – Really simple rubygem hosting
[![Build Status](https://secure.travis-ci.org/cwninja/geminabox.png)](http://travis-ci.org/cwninja/geminabox)
[![Gem Version](https://badge.fury.io/rb/geminabox.png)](http://badge.fury.io/rb/geminabox)

Geminabox lets you host your own gems, and push new gems to it just like with rubygems.org.
The bundler dependencies API is supported out of the box.
Authentication is left up to either the web server, or the Rack stack.
For basic auth, try [Rack::Auth](http://rack.rubyforge.org/doc/Rack/Auth/Basic.html).




![screen shot](http://pics.tomlea.co.uk/bbbba6/geminabox.png)




## Server Setup

    gem install geminabox

Create a config.ru as follows:

    require "rubygems"
    require "geminabox"

    Geminabox.data = "/var/geminabox-data" # ... or wherever
    run Geminabox

And finally, hook up the config.ru as you normally would ([passenger][passenger], [thin][thin], [unicorn][unicorn], whatever floats your boat).

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

## Licence

Fork it, mod it, choose it, use it, make it better. All under the [do what the fuck you want to + beer/pizza public license][WTFBPPL].

[WTFBPPL]: http://tomlea.co.uk/WTFBPPL.txt
[sinatra]: http://www.sinatrarb.com/
[passenger]: http://www.modrails.com/
[thin]: http://code.macournoyer.com/thin/
[unicorn]: http://unicorn.bogomips.org/
