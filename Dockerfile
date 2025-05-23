FROM openjdk:latest
COPY out/artifacts/hayat_api_jar/ /hayat-api
WORKDIR /hayat-api
CMD ["java", "-Dlog4j2.debug=true", "-cp", "hayat-api.jar", "uz.hayatbank.api.Launcher"]
LABEL authors="DjekkGabber"
