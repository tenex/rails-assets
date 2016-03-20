# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'rails-assets'
set :repo_url, 'git@github.com:tenex/rails-assets.git'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :deploy_user, -> { fetch(:application) }
set :deploy_user_home, -> { File.join '/home', fetch(:deploy_user) }
set :rails_apps_path, -> { File.join fetch(:deploy_user_home), 'rails-apps' }
set :deploy_to, -> { File.join fetch(:rails_apps_path), fetch(:application) }

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

task :restart_workers do
  on roles(:worker) do
    sudo 'restart sidekiq'
  end
end
after "deploy:published", 'restart_workers'
