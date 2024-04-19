ARG FUNCTION_DIR="/function"
FROM public.ecr.aws/amazonlinux/amazonlinux:2023 AS build-image

WORKDIR ${FUNCTION_DIR}
RUN yum groupinstall "Development Tools" -y
RUN yum -y install yasm nasm libX11-devel libXext-devel libXfixes-devel zlib-devel bzip2-devel openssl-devel ncurses-devel git gcc make wget

# Download and extract FFmpeg
RUN wget -O ffmpeg.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.2.tar.bz2
RUN tar xvjf ffmpeg.tar.bz2 && ls -l  # Lists contents to check the directory structure

# Move to the FFmpeg directory
WORKDIR ${FUNCTION_DIR}/ffmpeg-4.2
RUN ls -l  # Lists contents to confirm presence of configure script

# Configure, make, and install FFmpeg
RUN ./configure --prefix=/usr/local --enable-shared --enable-gpl --enable-libx264
RUN make
RUN make install
RUN /usr/local/bin/ffmpeg -version

COPY . .
RUN pip install -r requirements.txt

CMD ["main.lambda_handler"]
