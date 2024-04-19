ARG FUNCTION_DIR="/function"
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS build-image

WORKDIR ${FUNCTION_DIR}
RUN yum groupinstall "Development Tools" -y
RUN yum -y install yasm nasm libX11-devel libXext-devel libXfixes-devel zlib-devel bzip2-devel openssl-devel ncurses-devel git gcc make wget pkgconfig

RUN echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:\$PKG_CONFIG_PATH" >> ~/.bashrc
RUN source ~/.bashrc
# Clone and install x264
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git
WORKDIR ${FUNCTION_DIR}/x264
RUN ./configure --prefix=/usr/local --enable-shared --enable-static --enable-libx264
RUN make
RUN make install

# Download and extract FFmpeg
WORKDIR ${FUNCTION_DIR}
RUN pkg-config --libs --cflags x264
RUN wget -O ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.2.tar.bz2
RUN tar xvjf ffmpeg.tar.bz2 && ls -l  # This lists contents to check the directory structure

# Adjust WORKDIR to match the extracted directory
# Check that this is the correct directory with an ls command
RUN ls -l ${FUNCTION_DIR}  # This will help to identify the actual directory name
WORKDIR ${FUNCTION_DIR}/ffmpeg-4.2
RUN ls -l  # Confirm presence of the configure script

# Configure, make, and install FFmpeg
RUN ./configure --prefix=/usr/local --enable-shared --enable-gpl
RUN make
RUN make install
RUN /usr/local/bin/ffmpeg -version

COPY . .
RUN pip install -r requirements.txt

CMD ["main.lambda_handler"]