FROM amazonlinux:2023

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

WORKDIR /app

RUN yum groupinstall "Development Tools" -y && \
    yum install -y python3-pip git virtualenv && \
    yum install yasm nasm pkgconfig zlib-devel libtool -y && \
    yum install freetype-devel speex-devel libtheora-devel libvorbis-devel libogg-devel libvpx-devel wget -y

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

# Clone FFmpeg repo, configure, make, and install FFmpeg with libx264 and libvpx
RUN cd /usr/local/src && \
    wget https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
    tar xjvf ffmpeg-snapshot.tar.bz2 && \
    cd /usr/local/src/ffmpeg && \
    ./configure --prefix=/usr/local --enable-gpl --enable-nonfree --enable-libx264 --enable-libvpx \
    --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" && \
    make && \
    make install && \
    ffmpeg -version

# Copy the current directory contents into the container at /app
COPY . .

# Set up Python environment and install dependencies
RUN python3 -m venv venv && \
    ./venv/bin/pip install -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Run app.py when the container launches
CMD ["./venv/bin/python", "app.py"]
