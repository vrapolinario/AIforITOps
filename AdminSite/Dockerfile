FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["AdminSite/AdminSite.csproj", "AdminSite/"]
RUN dotnet restore "AdminSite/AdminSite.csproj"
COPY . .
WORKDIR "/src/AdminSite"
RUN dotnet publish "AdminSite.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AdminSite.dll"]
