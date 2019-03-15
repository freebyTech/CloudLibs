using System.Reflection;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Formatters;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.SpaServices.Webpack;
using freebyTech.Common.ExtensionMethods;
using freebyTech.Common.Web.ExtensionMethods;
using freebyTech.Common.Web.Logging.LoggerTypes;
using Swashbuckle.AspNetCore.Swagger;
using System.IO;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using Microsoft.ApplicationInsights.Extensibility;
using freebyTech.Common.Web.Logging.Initializers.AppInsights;
using okta_dotnetcore_react_example.Data;
using okta_dotnetcore_react_example.Options;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Options;
using Serilog;

namespace okta_dotnetcore_react_example
{
    /// <summary>
    /// Startup class for tivBudget.Api application.
    /// </summary>
    public class Startup
    {
        /// <summary>
        /// Startup class constructor
        /// </summary>
        public Startup()
        {
            ApplicationAssembly = Assembly.GetExecutingAssembly();
            ApplicationInfo = ApplicationAssembly.GetName();
            ApiVersion = $"v{ApplicationInfo.Version.Major}.{ApplicationInfo.Version.Minor}";
        }

        /// <summary>
        /// The Application Assembly
        /// </summary>
        public Assembly ApplicationAssembly { get; }

        /// <summary>
        /// The AssemblyName of the Application
        /// </summary>
        public AssemblyName ApplicationInfo { get; private set; }

        /// <summary>
        /// The ApiVersion as defined for Swagger display
        /// </summary>
        public string ApiVersion { get; private set; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            // TelemetryConfiguration.Active.TelemetryInitializers.Add(new ContextInitializer(ApplicationInfo.Name));

            var otkaSTS = Program.Configuration.GetValue("OKTA_CLIENT_OKTADOMAIN", "");
            Log.Information($"STS Operations will be going against {otkaSTS}");

            services.AddAuthentication(sharedOptions =>
            {
                sharedOptions.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                sharedOptions.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.Authority = $"{otkaSTS}oauth2/default";
                options.Audience = "api://default";
            });

            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1)
            .AddJsonOptions(options =>
            {
                // Stop parent child reference issues with entities.
                options.SerializerSettings.ReferenceLoopHandling = ReferenceLoopHandling.Ignore;
                options.SerializerSettings.NullValueHandling = NullValueHandling.Ignore;
            });

            // Register the Swagger generator, defining 1 or more Swagger documents
            // services.AddSwaggerGen(c =>
            // {
            //     c.SwaggerDoc(ApiVersion, new Info { Title = ApplicationInfo.Name, Version = ApplicationInfo.Version.ToString() });
            //     c.IncludeXmlComments(Path.Combine(Program.ExecutionEnvironment.ServiceRootPath, $"{ApplicationInfo.Name}.xml"));
            // });

            services.AddSerilogFrameworkAgent();
            services.AddApiLoggingServices(ApplicationAssembly, "freebytech-sandbox", ApiLogVerbosity.LogMinimalRequest);

            // Build out DB Connection string.
            services.Configure<DbOptions>(Program.Configuration.GetSection("DB"));

            var sp = services.BuildServiceProvider();
            var dbOptions = sp.GetService<IOptions<DbOptions>>();

            Log.Information($"DB Operations will be going against {dbOptions.Value.ServerName}");

            var dbConnectionString = DbOptions.BuildConnectionString(dbOptions.Value.ServerName, dbOptions.Value.UserName, dbOptions.Value.UserPassword, "ConferenceDb");
            services.AddDbContext<ApiContext>(options => options.UseSqlServer(dbConnectionString));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseWebpackDevMiddleware(new WebpackDevMiddlewareOptions
                {
                    HotModuleReplacement = true,
                    ReactHotModuleReplacement = true
                });
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
            }

            app.UseStaticFiles();

            app.UseAuthentication();

            app.UseStandardApiMiddleware();

            // Enable middleware to serve generated Swagger as a JSON endpoint.
            // app.UseSwagger();

            // // Enable middleware to serve swagger-ui (HTML, JS, CSS, etc.), 
            // // specifying the Swagger JSON endpoint.
            // app.UseSwaggerUI(c =>
            // {
            //     c.SwaggerEndpoint($"/swagger/{ApiVersion}/swagger.json", ApplicationInfo.Name);
            // });

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                name: "default",
                template: "Home/{action=Index}/{id?}");

                routes.MapRoute(
                    name: "api",
                    template: "api/{controller=Default}/{action=Index}/{id?}"
                );

                routes.MapSpaFallbackRoute(
                    name: "spa-fallback",
                    defaults: new
                    {
                        controller = "Home",
                        action = "Index"
                    }
                );
            });
            InitializeDatabase(app);
        }
        private void InitializeDatabase(IApplicationBuilder app)
        {
            using (var scope = app.ApplicationServices.GetService<IServiceScopeFactory>().CreateScope())
            {
                scope.ServiceProvider.GetRequiredService<ApiContext>().Database.Migrate();
            }
        }
    }
}
