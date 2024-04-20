FROM amazonlinux:2023

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig


WORKDIR /app


RUN yum groupinstall "Development Tools" -y && \
    yum install -y python3-pip git virtualenv && \
    yum install yasm nasm pkgconfig zlib-devel libtool -y && \
    yum install freetype-devel speex-devel libtheora-devel libvorbis-devel libogg-devel libvpx-devel -y

# Clone and build x264
RUN cd /usr/local/src && \
    git clone http://git.videolan.org/git/x264.git && \
    cd x264 && \
    ./configure --enable-static --prefix=/usr/local --enable-pic && \
    make && \
    make install

# Verify if PKG_CONFIG_PATH is set correctly and pkg-config can find x264
RUN echo $PKG_CONFIG_PATH && \
    pkg-config --exists --print-errors x264

# Clone FFmpeg repo (assuming it has been previously added to /usr/local/src, adjust if necessary)
# Configure, make, and install FFmpeg with libx264 and libvpx

RUN cd /usr/local/src && \
    wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar xjvf ffmpeg-snapshot.tar.bz2 && \
    cd /usr/local/src/ffmpeg && \
    ./configure --prefix=/usr/local --enable-gpl --enable-nonfree --enable-libx264 --enable-libvpx \
    --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" && \
    make && \
    make install && \
    ffmpeg -version


# RUN yum install -y yasm nasm libX11-devel libXext-devel libXfixes-devel zlib-devel bzip2-devel openssl-devel ncurses-devel git gcc make wget pkgconfig
# RUN yum install -y autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel python3-pip httpd
# RUN python3 -m venv venv && source venv/bin/activate
# RUN git clone https://github.com/PyAV-Org/PyAV.git
# RUN cd PyAV
# RUN source scripts/activate.sh
# RUN pip install --upgrade -r tests/requirements.txt
# RUN ./scripts/build-deps

# # Build PyAV.
# RUN make
# RUN pip install .





# Install updates and Apache
RUN yum update -y && \
    yum install -y httpd && \
    yum clean all

# Adjust permissions
RUN mkdir /var/www/html/healthcheck && \ 
    chown -R apache:apache /var/www && \
    chown -R apache:apache /etc/httpd && \
    chown -R apache:apache /var/log/httpd && \
    chown -R apache:apache /run/httpd

# Customize the default web page
RUN echo '<html><body><h1>Welcome to my website running on Amazon Linux 2023 with Apache!</h1></body></html>' > /var/www/html/index.html
RUN echo 'ok' > /var/www/html/healthcheck/index.html
EXPOSE 80
USER apache

# Start Apache in the foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
