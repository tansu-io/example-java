FROM debian:bookworm
RUN apt-get update
RUN apt-get install -y bats
COPY --from=quay.io/minio/minio /usr/bin/mc /bin/
