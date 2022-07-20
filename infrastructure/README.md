# Provisioning rails-assets

Prerequisites:

* Your SSH key can access root account on server

## Spin up a server

Create a server that runs Debian Bullseye (11). Ubuntu 22.04 will not
work (without a lot of labor) because Ruby 2.4.10 will not install
(only Ruby 3+ will) due to OpenSSL versions being incompatible.

## Install ansible and roles

``` shell
python3 -m pip install --user ansible
ansible-galaxy install rvm.ruby
ansible-galaxy install kamaln7.swapfile
```

## Run it

From this directory:

``` shell
ansible --inventory production \
  --ask-vault-password \
  provision-rails-assets.yml
```

If you're deploying this, you will know the vault password.

## TODO

* Install the backup scripts in the rails-assets user's home directory
  into cron
* SSH into the server as rails-assets and run gcloud init with
  credentials that can get to the backup GCS buckets
