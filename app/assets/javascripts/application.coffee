#= require angular
#= require ngNotificationsBar
#= require angular-animate
#= require popeye
#= require angular-semver-sort
#= require js-routes
#= require rails-assets
#= require_directory .

app = angular.module('rails-assets')

app.config ['notificationsConfigProvider', (notificationsConfigProvider) ->
    notificationsConfigProvider.setHideDelay(6000)
    notificationsConfigProvider.setAutoHide(true)
    notificationsConfigProvider.setAutoHideAnimation('fadeOutUp')
]
