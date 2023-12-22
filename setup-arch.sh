#!/usr/bin/env bash

# This script sets up a minimal Arch Linux installation in a chroot environment.
# It is meant to be run on a Debian-based system (e.g. Ubuntu) with root privileges via sudo.
#
# Following environment variables are required:
#   - INPUT_ARCH_VERSION: Version of Arch Linux to install (e.g. 2023.12.01)
#   - INPUT_ARCH_MIRROR: Mirror to download the bootstrap tarball from (e.g. https://mirror.pkgbuild.com)
#   - INPUT_ARCH_PACKAGES: List of additional packages to install, separated by spaces (e.g. git vim)
#
# Bash 4 and higher is required.
# shellcheck shell=bash
#
set -euo pipefail

## Constants
####################################################################################################
readonly RUNNER_HOME="/home/$SUDO_USER"
readonly ARCH_ROOTFS_DIR="$RUNNER_HOME/root.x86_64"

## Logging functions
####################################################################################################

_CURRENT_GROUP=""

debug() {
    printf "::debug::%s\n" "$*"
}

notice() {
    printf "::notice::%s\n" "$*"
}

warning() {
    printf "::warning::%s\n" "$*"
}

error() {
    printf "::error::%s\n" "$*"
}

group() {
    [ -n "$_CURRENT_GROUP" ] && endgroup

    printf "::group::%s\n" "$*"
    _CURRENT_GROUP="$*"
}

endgroup() {
    [ -n "$_CURRENT_GROUP" ] && printf "::endgroup::\n"
    _CURRENT_GROUP=""
}

output() {
    local variable="$1"
    shift

    printf "%s=%s\n" "$variable" "$*" >> "$GITHUB_OUTPUT"
}


## Helper functions
####################################################################################################

## Download a file from a URL.
##
## $1: URL to download
## $2: Path to save the file to
download() {
    local url="$1"
    local path="$2"

    group "Downloading $url..."
    curl -sSL -o "$path" "$url" 2>&1
    endgroup
}

## Verify a file with a given GPG signature.
##
## $1: Path to the file to verify
## $2: Path to the signature file
verify() {
    local file="$1"
    local sig="$2"

    group "Verifying $file..."
    gpg --verify "$sig" "$file" 2>&1
    endgroup
}

## Extract a tarball while preserving permissions.
##
## $1: Path to the tarball to extract
## $2: Path to extract the tarball to
extract() {
    local tarball="$1"
    local path="$2"

    group "Extracting $tarball..."
    tar xzf "$tarball" -C "$path" --numeric-owner 2>&1
    endgroup
}

## Write to a file as root.
##
## $1: Path to the file to write to
## $2: Content to write to the file
write() {
    local path="$1"
    local content="$2"

    group "Writing to $path..."
    echo "$content" | sudo tee "$path" 2>&1
    endgroup
}

## Run a command in the chroot environment.
##
## $1: Command to run
run() {
    local cmd="$1"

    group "Running $cmd..."
    sudo "$ARCH_ROOTFS_DIR/bin/arch-chroot" "$ARCH_ROOTFS_DIR" /bin/bash -c "$cmd" 2>&1
    endgroup
}

## Entrypoint
####################################################################################################

# Download the latest bootstrap tarball from the mirror and signature from the official server
download "$INPUT_ARCH_MIRROR/iso/$INPUT_ARCH_VERSION/archlinux-bootstrap-x86_64.tar.gz" "archlinux-bootstrap-x86_64.tar.gz"
download "https://archlinux.org/iso/$INPUT_ARCH_VERSION/archlinux-bootstrap-x86_64.tar.gz.sig" "archlinux-bootstrap-x86_64.tar.gz.sig"

# Verify the signature
gpg --auto-key-locate clear,wkd -v --locate-external-key "pierre@archlinux.org"
verify "archlinux-bootstrap-x86_64.tar.gz" "archlinux-bootstrap-x86_64.tar.gz.sig"

# Extract the tarball
extract "archlinux-bootstrap-x86_64.tar.gz" "$RUNNER_HOME"

# Populate the mirror list
write "$ARCH_ROOTFS_DIR/etc/pacman.d/mirrorlist" "Server = $INPUT_ARCH_MIRROR/\$repo/os/\$arch"

# Install essential packages (base-devel)
run "pacman-key --init"
run "pacman-key --populate archlinux"
run "sed -i 's/CheckSpace/#CheckSpace/' /etc/pacman.conf"
run "pacman -Syu --noconfirm --needed base-devel"

# Install additional packages if specified
if [ -n "$INPUT_ARCH_PACKAGES" ]; then
    run "pacman -Syu --noconfirm --needed $INPUT_ARCH_PACKAGES"
fi

# Set up the user
run "useradd -m -G wheel -s /bin/bash $SUDO_USER"

# Set up sudo
run "echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"

# Clean up
rm -rf "archlinux-bootstrap-x86_64.tar.gz" "archlinux-bootstrap-x86_64.tar.gz.sig"

# Output the path to the rootfs directory
output root-path "$ARCH_ROOTFS_DIR"