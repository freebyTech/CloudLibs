using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Okta.Sdk;
using Okta.Sdk.Configuration;
using okta_dotnetcore_react_example.Models;

namespace okta_dotnetcore_react_example.Controllers
{
    [Route("api/[controller]")]
    public class UsersController : Controller
    {
        [HttpPost]
        public async Task<IActionResult> Post([FromBody]Registration reg)
        {

            var oktaClient = new OktaClient();
            try
            {
                var user = await oktaClient.Users.CreateUserAsync(
                    new CreateUserWithPasswordOptions
                    {
                        Profile = new UserProfile
                        {
                            FirstName = reg.FirstName,
                            LastName = reg.LastName,
                            Email = reg.Email,
                            Login = reg.Email
                        },
                        Password = reg.Password,
                        Activate = true
                    }
                );
            }
            catch (Exception ex)
            {
                return BadRequest(new RegistrationResponse() { Message = ex.Message });
            }
            return Ok(new RegistrationResponse() { Message = "User Created" });

        }
    }
}