FROM mcr.microsoft.com/azure-cli:latest

RUN apk add postgresql-client coreutils

RUN cd /tmp && \
    curl -L https://aka.ms/downloadazcopy-v10-linux -o azcopy-linux.tar.gz && \
    tar xzf azcopy-linux.tar.gz && \
    cp azcopy_*/azcopy /usr/local/bin && \
    rm -rf azcopy*

COPY backup.sh /backup.sh

RUN chmod +x /backup.sh

ENTRYPOINT /backup.sh
