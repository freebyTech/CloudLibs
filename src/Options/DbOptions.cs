namespace okta_dotnetcore_react_example.Options
{
    /// <summary>
    /// Class representing the DB Options environment variables to setup applications DB connection.
    /// </summary>
    public class DbOptions
    {
        public string ServerName { get; set; }
        public string UserName { get; set; }
        public string UserPassword { get; set; }

        public static string BuildConnectionString(string servername, string userName, string userPassword, string initialDb)
        {
            return ($"Data Source={servername};User ID={userName};Password={userPassword};Database={initialDb};Pooling=False;");
        }
    }
}