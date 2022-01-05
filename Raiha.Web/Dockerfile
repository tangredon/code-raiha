FROM public.ecr.aws/lambda/dotnet:6 AS base

FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim as build
COPY ["Raiha.Web.csproj", "Raiha.Web/"]
RUN dotnet restore "Raiha.Web/Raiha.Web.csproj"

WORKDIR "/Raiha.Web"
COPY . .
RUN dotnet build "Raiha.Web.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "Raiha.Web.csproj" \
            --configuration Release \ 
            --runtime linux-x64 \
            --self-contained false \ 
            --output /app/publish \
            -p:PublishReadyToRun=true  

FROM base AS final
WORKDIR /var/task
COPY --from=publish /app/publish .