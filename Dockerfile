# ---------- Build stage ----------
# Dockerfile <PUT THIS IN PROJECT ROOT>
# Full JDK + Maven, used only to compile and package the jar.
FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /app
# Copy the Maven wrapper and pom first so dependency resolution is
# cached in its own Docker layer -- it only re-runs when pom.xml
# actually changes, not on every source edit.
COPY .mvn/ .mvn/
COPY mvnw mvnw.cmd pom.xml ./
RUN chmod +x mvnw && ./mvnw -B dependency:go-offline

# Now copy the rest of the source and build the jar.
COPY src ./src
RUN ./mvnw -B clean package -DskipTests

# ---------- Runtime stage ----------
# JRE only -- no compiler, no Maven, much smaller final image.
FROM eclipse-temurin:25-jre AS runtime

WORKDIR /app

# Run as a non-root user rather than the container default root.
RUN useradd --system --create-home appuser
USER appuser

# Copy only the built jar out of the build stage.
COPY --from=build /app/target/*.jar app.jar

# Render injects $PORT at runtime; application.properties already
# reads server.port=${PORT:8080}, so no extra config needed here --
# just make sure the app actually binds to that env var, which it does.
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]