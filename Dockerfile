FROM mcr.microsoft.com/windows/servercore:ltsc2019

# setup chocolatey
ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
RUN choco config set cachelocation C:\chococache

# install prereqs for openedge and vsts agent
RUN choco install \
jdk8 \
git \
dotnet4.5.2 \
vcredist2010 \
vcredist2015 \
--confirm \
&& rmdir /S /Q C:\chococache

# install ant without prereqs as we don't need jre
RUN choco install \
ant \
--confirm \
--ignore-dependencies \
&& rmdir /S /Q C:\chococache

# set the working directory
RUN mkdir C:\BuildAgent
WORKDIR C:/BuildAgent

# install agent
RUN powershell -Command Invoke-WebRequest https://vstsagentpackage.azureedge.net/agent/2.144.0/vsts-agent-win-x64-2.144.0.zip -OutFile C:\BuildAgent\agent.zip ; \
    Expand-Archive C:\BuildAgent\agent.zip -DestinationPath C:\BuildAgent\ ; \
    Remove-Item "C:\BuildAgent\agent.zip"

# copy cut down version of openedge from HFS file server
RUN powershell -Command Invoke-WebRequest http://10.0.75.1/oe1172.zip -OutFile $env:TEMP\oe.zip;  \
    Expand-Archive $env:TEMP\oe.zip -DestinationPath C:\Progress\OpenEdge ; \
    Remove-Item "$env:TEMP\oe.zip"
ENV DLC="C:\\Progress\\OpenEdge"

# copy our start scripts
COPY ./Start.* ./

# add the progress license
COPY progress_1172.cfg C:/Progress/OpenEdge/progress.cfg

# set the env vars for our VSTS settings
ENV VSTS_ACCOUNT=vsts_account_name
ENV VSTS_AGENT=OpenEdgeBuilder
ENV VSTS_TOKEN=vsts_access_token
ENV VSTS_POOL=vsts_pool_for_onpremise

CMD ["Start.cmd"]
