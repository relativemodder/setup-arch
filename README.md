# setup-arch

This action provides a simple `chroot`-based [Arch Linux](https://archlinux.org) environment to be used in later steps.

## Usage

See [action.yml](action.yml) for more information.

```yaml
- uses: RangHo/setup-arch@main
  with:
    # Version of Arch Linux rootfs tarball to use (optional).
    # See the index of https://geo.mirror.pkgbuild.com/iso/ for the list of
    # versions available.
    # Default is `latest`.
    version: latest

    # Mirror to use when downloading packages (optional).
    # Default is to use Arch Linux Geographic Mirror to automatically select
    # the closest mirror.
    mirror: https://geo.mirror.pkgbuild.com

    # Space-separated list of packages to install in the Arch Linux chroot
    # (optional).
    # `base-devel` package group is always installed, followed by packages
    # specified here.
    # Note that additional packages can be installed later in other steps.
    packages: "cowsay ponysay"
```

Once initialized, the Arch Linux enviroment can be accessed by specifying the shell to `arch.sh {0}`.
The current working directory is shared, and any changes made in Arch Linux working directory will be reflected to the host directory.

```yaml
- run: |
    cat /etc/os-release
  shell: arch.sh {0}
```

## License

This project is licensed under [MIT License](https://opensource.org/license/mit/).
For the full text of the license, see the [LICENSE](LICENSE) file.

## Acknowledgement

This project is inspired by amazing [`setup-alpine`](https://github.com/jirutka/setup-alpine) action by [@jirutka](https://github.com/jirutka).
I was able to save a lot of time debugging weird `chroot` issues thanks to his [setup script](https://github.com/jirutka/setup-alpine/blob/master/setup-alpine.sh)!