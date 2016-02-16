#= require angular
#= require ngNotificationsBar
#= require angular-semver-sort
#= require js-routes
#= require rails-assets
#= require_directory .

app = angular.module('rails-assets')

app.config ['notificationsConfigProvider', (notificationsConfigProvider) ->
    notificationsConfigProvider.setAutoHide(true)
    notificationsConfigProvider.setAutoHideAnimationDelay(6000)
]
