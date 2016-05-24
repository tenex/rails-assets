server(
  'srv.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(app db web)
)

server(
  'build-1.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(worker)
)

server(
  'wopr.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(app db web worker)
)
