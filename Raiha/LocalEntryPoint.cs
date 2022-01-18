using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace Raiha;

/// <summary>
/// The Main function can be used to run the ASP.NET Core application locally using the Kestrel web server.
/// </summary>
public class LocalEntryPoint
{
    public static void Main(string[] args)
    {
        CreateHostBuilder(args).Build().Run();
    }

    public static IHostBuilder CreateHostBuilder(string[] args) =>
        Host.CreateDefaultBuilder(args)
            .ConfigureWebHostDefaults(webBuilder =>
            {
                webBuilder.UseStartup<Startup>();
            });
}