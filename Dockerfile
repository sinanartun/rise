ARG FUNCTION_DIR="/function"
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS build-image

WORKDIR ${FUNCTION_DIR}
RUN yum groupinstall "Development Tools" -y
RUN yum install -y yasm nasm libX11-devel libXext-devel libXfixes-devel zlib-devel bzip2-devel openssl-devel ncurses-devel git gcc make wget pkgconfig
RUN yum install -y autoconf automake bzip2 bzip2-devel cmake freetype-devel gcc gcc-c++ git libtool make pkgconfig zlib-devel python3-pip httpd
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig

# Clone and install x264
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git
WORKDIR ${FUNCTION_DIR}/x264
RUN ./configure --prefix=/usr/local --enable-shared --enable-static --enable-libx264
RUN make
RUN make install
RUN systemctl start httpd
RUN systemctl enable httpd
EXPOSE 80
RUN cd /var/www/html
RUN mkdir healthcheck
RUN echo "ok" > ./healthcheck/index.html
COPY bin/ffmpeg /usr/local/bin/
RUN chmod +x /usr/local/bin/ffmpeg
ENV PATH="/usr/local/bin:${PATH}"

COPY . .
RUN pip install -r requirements.txt

CMD ["main.lambda_handler"]

