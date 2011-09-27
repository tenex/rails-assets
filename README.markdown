# Gem in a Box

![screen shot](http://pics.tomlea.co.uk/55c320/geminabox.png)

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

And finally, hook up the config.ru as you normally would ([passenger][passenger], [thin][thin], [unicorn][unicorn], whatever floats your boat).


## Client Usage

    gem install geminabox

    gem inabox pkg/my-awesome-gem-1.0.gem

Simples!

## Licence

Fork it, mod it, choose it, use it, make it better. All under the [do what the fuck you want to + beer/pizza public license][WTFBPPL].

[WTFBPPL]: http://tomlea.co.uk/WTFBPPL.txt
[sinatra]: http://www.sinatrarb.com/
[passenger]: http://www.modrails.com/
[thin]: http://code.macournoyer.com/thin/
[unicorn]: http://unicorn.bogomips.org/
