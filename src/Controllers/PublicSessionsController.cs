using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using okta_dotnetcore_react_example.Data;
using okta_dotnetcore_react_example.Models;

namespace okta_dotnetcore_react_example.Controllers
{
    [Route("/api/[controller]")]
    public class PublicSessionsController : Controller
    {
        private readonly ApiContext context;
        public PublicSessionsController(ApiContext context)
        {
            this.context = context;
        }

        [HttpGet]
        public IActionResult GetAllPublicSessions()
        {
            var sessions = context.Sessions.ToList();
            return Ok(sessions);
        }
    }
}