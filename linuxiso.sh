#!/usr/bin/env bash

set -e

# linuxiso - prosty downloader ISO
# Wymaga: curl, wget, grep, sed, awk

if ! command -v curl >/dev/null 2>&1; then
    echo "Brakuje: curl"
    exit 1
fi

if ! command -v wget >/dev/null 2>&1; then
    echo "Brakuje: wget"
    exit 1
fi

DISTROS=(
    "Ubuntu"
    "Debian"
    "Fedora"
    "Arch"
    "NixOS"
    "Guix"
    "openSUSE Tumbleweed"
    "Alpine"
    "Rocky Linux"
    "Linux Mint"
)

echo
echo "=== linuxiso ==="
echo

select distro in "${DISTROS[@]}"; do
    [[ -n "$distro" ]] && break
    echo "Nieprawidłowy wybór."
done

echo
echo "Wybrano: $distro"
echo

get_url() {
    case "$1" in

        Ubuntu)
            # Oficjalna strona release'ów Ubuntu.
            # Szukamy najnowszego katalogu 26.xx.x / 26.xx itd.
            page="$(curl -fsSL https://releases.ubuntu.com/)"
            version="$(echo "$page" |
                grep -oE 'href="[0-9]+\.[0-9]+(\.[0-9]+)?/"' |
                sed -E 's/href="([^"]+)\/"/\1/' |
                sort -V |
                tail -1)"

            echo "https://releases.ubuntu.com/${version}/ubuntu-${version}-desktop-amd64.iso"
            ;;

        Debian)
            # Debian stable - pobieramy najnowszy amd64 netinst ISO.
            page="$(curl -fsSL https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/)"
            file="$(echo "$page" |
                grep -oE 'debian-[0-9.]+-amd64-netinst.iso' |
                sort -V |
                tail -1)"

            echo "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$file"
            ;;

        Fedora)
            # Fedora Workstation - oficjalny redirect do aktualnego ISO.
            echo "https://download.fedoraproject.org/pub/fedora/linux/releases/$(curl -fsSL https://fedoraproject.org/workstation/download | grep -oE 'Fedora [0-9]+' | head -1 | grep -oE '[0-9]+')/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64.iso"
            ;;

        Arch)
            # Arch publikuje aktualny release w katalogu ISO.
            page="$(curl -fsSL https://geo.mirror.pkgbuild.com/iso/latest/)"
            file="$(echo "$page" |
                grep -oE 'archlinux-[0-9.]+-x86_64\.iso' |
                sort -V |
                tail -1)"

            echo "https://geo.mirror.pkgbuild.com/iso/latest/$file"
            ;;

        NixOS)
            # Stabilne graphical ISO x86_64.
            page="$(curl -fsSL https://nixos.org/download/)"
            url="$(echo "$page" |
                grep -oE 'https?://[^"]*nixos-graphical-[^"]*-x86_64-linux\.iso' |
                head -1)"

            [[ -n "$url" ]] && echo "$url" || {
                echo "Nie udało się znaleźć ISO NixOS."
                return 1
            }
            ;;

        Guix)
            # Guix System - najnowszy obraz x86_64.
            page="$(curl -fsSL https://guix.gnu.org/download/)"
            url="$(echo "$page" |
                grep -oE 'https?://[^"]*guix-system[^"]*x86_64[^"]*\.iso' |
                head -1)"

            [[ -n "$url" ]] && echo "$url" || {
                echo "Nie udało się znaleźć ISO Guix."
                return 1
            }
            ;;

        "openSUSE Tumbleweed")
            page="$(curl -fsSL https://download.opensuse.org/tumbleweed/iso/)"
            file="$(echo "$page" |
                grep -oE 'openSUSE-Tumbleweed-DVD-x86_64-[0-9.]+\.iso' |
                sort -V |
                tail -1)"

            echo "https://download.opensuse.org/tumbleweed/iso/$file"
            ;;

        Alpine)
            # Alpine ma alias latest-stable.
            page="$(curl -fsSL https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/)"
            file="$(echo "$page" |
                grep -oE 'alpine-standard-[0-9.]+-x86_64\.iso' |
                sort -V |
                tail -1)"

            echo "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/$file"
            ;;

        "Rocky Linux")
            # Rocky posiada stabilny alias latest.
            echo "https://dl.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-minimal.iso"
            ;;

        "Linux Mint")
            # Mint zmienia nazwy wydań, więc na razie kierujemy
            # parser na oficjalną stronę mirrorów.
            page="$(curl -fsSL https://www.linuxmint.com/download.php)"
            url="$(echo "$page" |
                grep -oE 'https?://[^"]+linuxmint[^"]+\.iso' |
                head -1)"

            [[ -n "$url" ]] && echo "$url" || {
                echo "Nie udało się znaleźć ISO Linux Mint."
                return 1
            }
            ;;

        *)
            echo "Nieobsługiwane distro."
            return 1
            ;;
    esac
}

echo "Sprawdzam najnowsze ISO..."
echo

URL="$(get_url "$distro")"

if [[ -z "$URL" ]]; then
    echo "Nie znaleziono ISO."
    exit 1
fi

FILE="$(basename "$URL")"

echo "URL:  $URL"
echo "Plik: $FILE"
echo

read -rp "Pobrać? [Y/n] " answer
answer="${answer:-Y}"

if [[ "$answer" =~ ^[Yy]$ ]]; then
    wget -c "$URL"
    echo
    echo "✓ Gotowe: $FILE"
else
    echo "Anulowano."
fi
