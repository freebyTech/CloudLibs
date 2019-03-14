using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.SpaServices.Webpack;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using okta_dotnetcore_react_example.Data;
using okta_dotnetcore_react_example.Options;

namespace okta_dotnetcore_react_example
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddAuthentication(sharedOptions =>
            {
                sharedOptions.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                sharedOptions.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                // TODO: Really need to come from environment variables like mail and DB, to be twelve-factor.
                options.Authority = "https://dev-541900.okta.com/oauth2/default";
                options.Audience = "api://default";
            });
            services.AddMvc();

            // Build out DB Connection string.
            services.Configure<DbOptions>(Configuration.GetSection("DB"));

            var sp = services.BuildServiceProvider();
            var dbOptions = sp.GetService<IOptions<DbOptions>>();

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
            });
            });
        }
    }
}
