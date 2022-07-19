# Provisioning rails-assets

Prerequisites:

* Your SSH key can access root account on server

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
