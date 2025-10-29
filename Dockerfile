# Use official Nginx image
FROM nginx:alpine

# Copy your static site
COPY ./mysite /usr/share/nginx/html

# Copy custom Nginx config
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Expose HTTP and HTTPS
EXPOSE 80 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
