ARG FUNCTION_DIR="/function"
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS build-image

WORKDIR ${FUNCTION_DIR}
RUN yum groupinstall "Development Tools" -y
RUN yum -y install yasm nasm libX11-devel libXext-devel libXfixes-devel zlib-devel bzip2-devel openssl-devel ncurses-devel git gcc make wget pkgconfig

ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig
# Clone and install x264
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git
WORKDIR ${FUNCTION_DIR}/x264
RUN ./configure --prefix=/usr/local --enable-shared --enable-static --enable-libx264
RUN make
RUN make install

# Download and extract FFmpeg
WORKDIR ${FUNCTION_DIR}
RUN wget -O ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.2.tar.bz2
RUN tar xvjf ffmpeg.tar.bz2 && ls -l  # This lists contents to check the directory structure

# Verify and adjust WORKDIR based on actual extracted directory name
RUN ls -l  # This will help to identify the actual directory name
# Assuming the directory is correctly named "ffmpeg-4.2", if not, adjust below
WORKDIR ${FUNCTION_DIR}/ffmpeg-4.2
RUN ls -l  # This should list 'configure' among other files

# Configure, make, and install FFmpeg
RUN if [ -f ./configure ]; then ./configure --prefix=/usr/local --enable-shared --enable-gpl --enable-libx264; else echo "Configure script not found"; exit 1; fi
RUN make
RUN make install
RUN /usr/local/bin/ffmpeg -version

COPY . .
RUN pip install -r requirements.txt

CMD ["main.lambda_handler"]
