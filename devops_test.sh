#!/bin/bash
#Ubuntu 16.04:
set -e
sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get -y update
# Verify that APT is pulling from the right repository.
apt-cache policy docker-engine

sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual

sudo apt-get -y install docker-engine
sudo service docker start

# Install dropbox
#cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
# ~/.dropbox-dist/dropboxd

# Create a new docker image based on Ubuntu 16.04 from created Dockerfile
mkdir ~/ubuntu_img 
cd ~/ubuntu_img/

# Create Dockerfile
cat > Dockerfile << EOF
FROM ubuntu:16.04
WORKDIR /build
RUN apt-get update && \
apt-get install -y \
g++ \
curl \
git \
file \
binutils
EOF

# Rust version. Default: stable
if [ "$1" = beta ];
then 
	echo "Rust: "$1
	echo "RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain beta" >> Dockerfile
elif [ "$1" = nightly ];
then
	echo "Rust: "$1
	echo "RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly" >> Dockerfile
else
	echo "Rust: stable"
	echo "RUN curl https://sh.rustup.rs -sSf | sh -s -- -y" >> Dockerfile
fi

# Parity branch. Default: master
if [ "$2" = beta ];
then
	echo "Parity: "$2
elif [ "$2" = stable ];
then
	echo "Parity: "$2
else
	set "$2" master
	echo "Parity: "$2
fi

echo 'ENV PATH /root/.cargo/bin:$PATH' >> Dockerfile
echo "ENV RUST_BACKTRACE 1" >> Dockerfile
# build parity
cat >> Dockerfile << EOF
RUN git clone https://github.com/ethcore/parity && \
       cd parity && \
       git checkout $2 && \
       git pull && \
       cargo build --release --verbose && \
       ls /build/parity/target/release/parity && \
       strip /build/parity/target/release/parity
# RUN curl -T /build/parity/target/release/parity ftp://ftp.example.com --user user:pwd
EOF

sudo docker build -t ubuntu:16.04 ~/ubuntu_img/