FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /app

ARG BUILD_VERSION

ENV NODE_VERSION 8.12.0
ENV NODE_FULL_NAME node-v8.12.0-linux-x64
ENV NODE_DOWNLOAD_SHA 3df19b748ee2b6dfe3a03448ebc6186a3a86aeab557018d77a0f7f3314594ef6
RUN curl -SL "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_FULL_NAME}.tar.gz" --output nodejs.tar.gz \
    && echo "$NODE_DOWNLOAD_SHA nodejs.tar.gz" | sha256sum -c - \
    && tar -xzf "nodejs.tar.gz" -C /usr/local --strip-components=1 \
    && rm nodejs.tar.gz \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# install typescript and ? globally js build
#RUN npm install -g typescript

# copy csproj and restore as distinct layers so we break cache as little as possible
COPY ./*.csproj ./sandboxapp-build-src/
WORKDIR /app/sandboxapp-build-src
RUN dotnet restore

# copy everything else and build app
COPY ./. .

ENV BUILD_VERSION=${BUILD_VERSION}

RUN dotnet publish -c Release -o /app/sandboxapp-pub

FROM microsoft/dotnet:2.1-aspnetcore-runtime
WORKDIR /app
COPY --from=build /app/sandboxapp-pub ./
ENTRYPOINT ["dotnet", "okta-dotnetcore-react-example.dll"]