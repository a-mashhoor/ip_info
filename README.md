# IP Info
Simple bash script to ease the usage of [IP API](https://ip-api.com/) in the Linux CLI
I wrote the script for my personal usage and nothing more

## Usage:
works with a single Command line argument: the IP you want to check out, or it can read the input from stdin

```shell
chmod 111 ./ip_info.sh
./ip_info.sh $(curl ident.me)
./ip_info.sh 1.1.1.1
