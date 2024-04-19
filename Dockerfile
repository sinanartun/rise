# Use Amazon Linux 2023 as the base image
FROM amazonlinux:2023

# Install updates and Apache
RUN yum update -y && \
    yum install -y httpd && \
    yum clean all

# Adjust permissions
RUN chown -R apache:apache /var/www && \
    chown -R apache:apache /etc/httpd && \
    chown -R apache:apache /var/log/httpd && \
    chown -R apache:apache /run/httpd

# Customize the default web page
RUN echo '<html><body><h1>Welcome to my website running on Amazon Linux 2023 with Apache!</h1></body></html>' > /var/www/html/index.html
RUN echo 'ok' > /var/www/html/healthcheck/index.html
# Expose port 80 to the host
EXPOSE 80

# Use the non-root user to run the web service
USER apache

# Start Apache in the foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
