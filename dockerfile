FROM tomcat:11.0.10-jdk21-temurin-noble

# Set maintainer label (optional but good practice)
LABEL maintainer="satyam.pandey@example.com"

# Remove default ROOT app (optional, keeps container clean)
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Create a user for running the application
RUN useradd -m flight-service

# Copy your JAR file into the webapps directory
COPY ./target/flight-service*.jar /usr/local/tomcat/webapps/

# Expose the default Tomcat port
EXPOSE 8080

# Set the user to 'mbooking' for security
USER flight-service

# Default command to run Tomcat
CMD ["catalina.sh", "run"]