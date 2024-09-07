FROM --platform=linux/amd64 ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    unzip \
    dos2unix \
    openjdk-11-jdk \
    git \
    build-essential \
    python3 \
    python3-pip \
    file \
    adb \
    wget \
    software-properties-common

# Define build argument for PAT
ARG GITHUB_TOKEN

# PAT for the repo with the CloudXR repo
ARG GITHUB_SDK_TOKEN

# Install Android SDK
RUN mkdir -p /sdk
RUN curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip
RUN unzip sdk-tools.zip -d /sdk && rm sdk-tools.zip
RUN yes | /sdk/cmdline-tools/bin/sdkmanager --sdk_root=/sdk --licenses
RUN /sdk/cmdline-tools/bin/sdkmanager --sdk_root=/sdk "platform-tools" "platforms;android-33" "build-tools;28.0.3"

# Install Android NDK
RUN /sdk/cmdline-tools/bin/sdkmanager --sdk_root=/sdk "ndk;21.4.7075529"

# Install Google Oboe SDK
RUN mkdir -p /oboe
RUN wget -O /oboe/oboe-1.5.0.aar https://github.com/google/oboe/releases/download/1.5.0/oboe-1.5.0.aar

# Install OVR Mobile SDK
RUN mkdir -p /ovr-sdk
RUN wget -O /ovr-sdk/ovr-mobile-sdk.zip https://securecdn.oculus.com/binaries/download/?id=4260475480682092

########################## DOWNLOAD THE SDK FROM THE GITHUB LATEST RELEASE #################

# Fetch release metadata, extract asset ID, and download asset
# Copy the script into the Docker image
COPY download_github_release.sh /usr/local/bin/download_github_release.sh

# Make the script executable
RUN chmod +x /usr/local/bin/download_github_release.sh

# Set environment variables
ENV GITHUB_PAT=${GITHUB_TOKEN}
ENV GITHUB_SDK_PAT=${GITHUB_SDK_TOKEN}

ENV GITHUB_API_URL=https://api.github.com/repos/peted70/CloudXR-SDK/releases/latest

ENV SDK_FILENAME=''

# Run the script
RUN /usr/local/bin/download_github_release.sh

########################## COPY THE SDK FROM THE HOST ######################################
# Copy and unzip source code from build context
#COPY CloudXR-SDK_4_0_0.zip /CloudXR-SDK_4_0_0.zip
#############################################################################################

# Verify the file size
RUN ls -lh /${SDK_FILENAME}

# Attempt to unzip the file
RUN mkdir -p /${SDK_FILENAME%.*} && unzip /${SDK_FILENAME} -d /${SDK_FILENAME%.*}

# List the contents of the directory to ensure it's unzipped correctly
RUN ls -lh /${SDK_FILENAME%.*}

# Set environment variables for Android SDK
ENV ANDROID_SDK_ROOT=/sdk
ENV PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"

# Copy OVR Mobile SDK ZIP and rename it
RUN cp /ovr-sdk/ovr-mobile-sdk.zip /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/app/libs/ovr_sdk.zip

# Copy Google Oboe SDK AAR file
RUN cp /oboe/oboe-1.5.0.aar /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/app/libs/

# Copy CloudXR SDK client package
RUN cp /${SDK_FILENAME%.*}/Client/Lib/Android/CloudXR.aar /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/app/libs/

# Create a user to avoid running as root
RUN useradd -ms /bin/bash vscode
USER vscode
WORKDIR /workspace

# Switch to root user to set permissions
USER root

# Set permissions for the SDK directory
RUN chown -R vscode:vscode /sdk

# Convert gradlew line endings
RUN dos2unix /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/gradlew && \
    chmod +x /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/gradlew

# Ensure Gradle and workspace directories have the correct permissions
RUN mkdir -p /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/.gradle && \
chown -R vscode:vscode /${SDK_FILENAME%.*}

# Use sed to replace the line in the build_sdk.gradle file
RUN sed -i 's|def C_SHARED_INCLUDE = file("${project.rootDir}/../../shared")|def C_SHARED_INCLUDE = file("${project.rootDir}/../../Shared")|' /${SDK_FILENAME%.*}/Client/Sample/Android/OculusVR/app/build_sdk.gradle

# Switch back to the vscode user or the intended user
USER vscode

# Default command
CMD ["/bin/bash"]
