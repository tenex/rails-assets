# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:
server(
  'rails-assets.tenex.tech',
  user: fetch(:deploy_user),
  roles: %w(app db web worker)
)

server(
  'worker-1.rails-assets.org',
  user: fetch(:deploy_user),
  roles: %w(worker)
)
