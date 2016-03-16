# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'rails-assets'
set :repo_url, 'git@github.com:tenex/rails-assets.git'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :deploy_user, -> { fetch(:application) }
set :deploy_to, lambda {
  "/home/#{fetch :deploy_user}/rails-apps/#{fetch :application}"
}
set :scm, :git
set :format, :pretty
set :log_level, :debug
set :pty, false
set(:linked_files,
    fetch(:linked_files, []).push(
      'config/database.yml',
      'config/application.yml',
      'public/components.json',
      'public/prerelease_specs.4.8',
      'public/prerelease_specs.4.8.gz',
      'public/specs.4.8',
      'public/specs.4.8.gz',
      'public/latest_specs.4.8',
      'public/latest_specs.4.8.gz',
      'public/packages.json'
    ))

set(:linked_dirs,
    fetch(:linked_dirs, []).push(
      'public/gems',
      'public/quick',
      'tmp/cache',
      'log'
    ))
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :keep_releases, 5

set :npm_flags, '--production --silent --no-spin'
set :npm_roles, :all
set :npm_env_variables, {}

set :foreman_roles, :worker
procfile_concurrency = { all: 1, web: 0 }
foreman_env_path = 'foreman.env'
set :foreman_options, {
  concurrency: procfile_concurrency.map { |pair| pair.join('=') }.join(','),
  env: foreman_env_path
}
set :foreman_export_path, '/etc/init'
set :foreman_use_sudo, true

namespace :foreman do
  before :export, :upload_env do
    on roles fetch(:foreman_roles) do
      upload! StringIO.new("RAILS_ENV=#{fetch(:stage)}"), "#{current_path}/#{foreman_env_path}"
    end
  end

  after :'deploy:restart', :restart_safe do
    begin
      invoke :'foreman:restart'
    rescue => ex
      SSHKit.config.output.warn "Failed to restart #{fetch(:foreman_app)}, attempting cold start"
      invoke :'foreman:start'
    end
  end
end

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
