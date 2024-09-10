# Containers for Building and Developing CloudXR Client Applications

This repo is designed to serve two purposes:

- To build the NVidia CloudXR Oculus VR Client application for receiving the stereoscopic frames from a CloudXR Server
- To provide a development container to allow extending the client application

## Build

A build will run automatically when changes are pushed to `main`. Alternatively, you can trigger the workflow manually.

The build will build a Docker container configured with an Android development environment as specified [here](https://docs.nvidia.com/cloudxr-sdk/usr_guide/cxr_ovr_client.html).

It will build the android project and create a release which can be downloaded from the github release page.

## Setup

There is a little bit of configuration to take care of as I have chosen to reference the NVidia CloudXR SDK from a private repo. If you want to use this solution you would need to create a private Github repo with just the CloudXR SDK zip file in it. 

`Note: This has been done as NVidia put the SDK behind a sign up so you would need to go through that process, download the SDK and upload it to your private Github repo as a release.`

There are some environment variables that are needed:

```bash
GITHUB_TOKEN=<PAT token with read content access to the release on this Github repo>
GITHUB_SDK_TOKEN=<PAT token with read content access to the release on a Github repo with the NVidia CloudXR SDK set as the latest release>
GITHUB_SDK_REPO=<The name of the repo which has the NVidia CloudXR SDK set as the latest release>
GITHUB_SDK_REPO_OWNER=<The repo owner>
```

In order to use the automated Github build pipeline you need to set these values in the `secrets and variables` settings in this Github repo (or your fork).

In order to create the dev container you can hardcode these values into the devcontainer.json (I haven't found a better way yet).