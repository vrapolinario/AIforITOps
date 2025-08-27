FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["StoreFront/StoreFront.csproj", "StoreFront/"]
RUN dotnet restore "StoreFront/StoreFront.csproj"
COPY . .
WORKDIR "/src/StoreFront"
RUN dotnet publish "StoreFront.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "StoreFront.dll"]
