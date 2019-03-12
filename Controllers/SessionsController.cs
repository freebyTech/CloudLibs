using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using okta_dotnetcore_react_example.Data;
using okta_dotnetcore_react_example.Models;

namespace okta_dotnetcore_react_example.Controllers
{
    [Authorize]
    [Route("/api/[controller]")]
    public class SessionsController : Controller
    {
        private readonly ApiContext context;
        public SessionsController(ApiContext context)
        {
            this.context = context;
        }

        [HttpPost]
        public IActionResult AddSession([FromBody] Session session)
        {
            session.UserId = User.Claims.SingleOrDefault(u => u.Type == "uid")?.Value;
            context.Add<Session>(session);
            context.SaveChanges();
            return Created($"api/sessions/{session.SessionId}", session);
        }
    }
}