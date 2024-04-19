# Use Amazon Linux 2023 as the base image
FROM amazonlinux:2023
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
WORKDIR /app

RUN yum groupinstall "Development Tools" -y

RUN yum install -y python3-pip git virtualenv

RUN yum install yasm nasm pkgconfig zlib-devel libtool -y
RUN yum install freetype-devel speex-devel libtheora-devel libvorbis-devel libogg-devel libvpx-devel -y



RUN cd /usr/local/src
RUN git clone http://git.videolan.org/git/x264.git
RUN cd x264
RUN ./configure --enable-static
RUN make
RUN make install

RUN echo $PKG_CONFIG_PATH
RUN pkg-config --exists --print-errors x264




RUN cd /usr/local/src/ffmpeg
RUN -E ./configure --prefix=/usr/local --enable-gpl --enable-nonfree --enable-libx264 --enable-libvpx \
--extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib"
RUN make
RUN make install
RUN ffmpeg -version

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
