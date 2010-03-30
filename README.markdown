# Gem in a Box

![screen shot](http://i50.tinypic.com/2yknxnr.png)

## Really simple rubygem hosting

Gem in a box is a simple [sinatra][sinatra] app to allow you to host your own in-house gems.

It has no security, or authentication so you should handle this yourself.

## Server Setup

    gem install geminabox

Create a config.ru as follows:

    require "rubygems"
    require "geminabox"

    Geminabox.data = "/var/geminabox-data" # …or wherever
    run Geminabox

And finally, hook up the config.ru as you normally would ([passenger][passenger], [thin][thin], [unicorn][unicorn], whatever floats you boat).


## Client Usage

    gem install geminabox

    gem inabox pkg/my-awesome-gem-1.0.gem

Simples!

[sinatra]: http://www.sinatrarb.com/
[passenger]: http://www.modrails.com/
[thin]: http://code.macournoyer.com/thin/
[unicorn]: http://unicorn.bogomips.org/