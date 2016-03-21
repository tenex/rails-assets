# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
server(
  'staging.rails-assets.tenex.tech',
  user: fetch(:deploy_user),
  roles: %w(app db web worker)
)
