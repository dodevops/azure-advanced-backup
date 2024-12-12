FROM mcr.microsoft.com/azure-cli:cbl-mariner2.0

RUN yum install -y postgresql-libs coreutils jq tar

RUN cd /tmp && \
    curl -L https://aka.ms/downloadazcopy-v10-linux -o azcopy-linux.tar.gz && \
    tar xzf azcopy-linux.tar.gz && \
    cp azcopy_*/azcopy /usr/local/bin && \
    rm -rf azcopy*

COPY backup.sh /backup.sh

RUN chmod +x /backup.sh

ENTRYPOINT /backup.sh
