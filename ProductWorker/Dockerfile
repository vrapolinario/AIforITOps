FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ProductWorker/ProductWorker.csproj", "ProductWorker/"]
RUN dotnet restore "ProductWorker/ProductWorker.csproj"
COPY . .
WORKDIR "/src/ProductWorker"
RUN dotnet publish "ProductWorker.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ProductWorker.dll"]
