# Use the .NET sample image as the base image
FROM mcr.microsoft.com/dotnet/samples

# Specify the default command to run when the container starts
CMD ["dotnet", "--info"]

