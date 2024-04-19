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

# Download and verify FFmpeg
WORKDIR ${FUNCTION_DIR}
RUN wget -O ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.3.tar.bz2
RUN tar xvjf ffmpeg.tar.bz2 && ls -l

# List extracted contents to check directory structure and names
RUN ls -l ${FUNCTION_DIR}

# Verify and adjust WORKDIR based on the actual directory name from the listing above
# Assuming the directory is named "ffmpeg-4.3" based on earlier assumption
WORKDIR ${FUNCTION_DIR}/ffmpeg-4.3
RUN ls -l  # This should list all contents including 'configure'

# Check if 'configure' script is present
RUN if [ -f ./configure ]; then echo "Configure script found"; else echo "Configure script not found"; exit 1; fi

# If 'configure' script is found, proceed with configuration and installation
RUN ./configure --prefix=/usr/local --enable-shared --enable-gpl --enable-libx264
RUN make
RUN make install
RUN /usr/local/bin/ffmpeg -version

COPY . .
RUN pip install -r requirements.txt

CMD ["main.lambda_handler"]
