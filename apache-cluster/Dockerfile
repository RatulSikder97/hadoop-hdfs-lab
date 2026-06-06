# Ensures python3 is available in the official apache/hadoop image (needed for the
# Python MapReduce / Hadoop Streaming job). Installs it only if it is missing, and
# auto-detects the image's package manager (microdnf/dnf/yum or apt).
FROM apache/hadoop:3.4.1

# Package installs need root; the image normally runs as the non-root hadoop user.
USER root
RUN if command -v python3 >/dev/null 2>&1; then \
        echo "python3 already present: $(python3 --version)"; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf install -y python3 && microdnf clean all; \
    elif command -v dnf >/dev/null 2>&1; then \
        dnf install -y python3 && dnf clean all; \
    elif command -v yum >/dev/null 2>&1; then \
        yum install -y python3 && yum clean all; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update && apt-get install -y python3 && rm -rf /var/lib/apt/lists/*; \
    else \
        echo "No known package manager found in base image" >&2; exit 1; \
    fi \
 && python3 --version

# Return to the non-root user the Hadoop daemons expect.
USER hadoop
