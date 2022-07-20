server(
  'ariane-5.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(app db web worker)
)
