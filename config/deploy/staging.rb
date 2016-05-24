server(
  'wopr.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(app db web worker)
)
