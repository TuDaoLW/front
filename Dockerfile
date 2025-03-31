# Use a lightweight web server like nginx
FROM nginx:alpine

# Copy the built app to the nginx web root
COPY dist /usr/share/nginx/html

# Copy the config.js file to the nginx web root
COPY public/config.js /usr/share/nginx/html/config.js

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]