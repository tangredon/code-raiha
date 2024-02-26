FROM public.ecr.aws/lambda/dotnet:8 AS base

FROM mcr.microsoft.com/dotnet/sdk:8.0-bullseye-slim as build
COPY ["Raiha.csproj", "Raiha/"]
RUN dotnet restore "Raiha/Raiha.csproj"

WORKDIR "/Raiha"
COPY . .
RUN dotnet build "Raiha.csproj" --configuration Release --output /app/build

FROM build AS publish
RUN dotnet publish "Raiha.csproj" \
            --configuration Release \ 
            --runtime linux-x64 \
            --self-contained false \ 
            --output /app/publish \
            -p:PublishReadyToRun=true  

FROM base AS final
COPY --from=publish /app/publish ${LAMBDA_TASK_ROOT}
CMD ["Raiha::Raiha.LambdaEntryPoint::FunctionHandlerAsync"]