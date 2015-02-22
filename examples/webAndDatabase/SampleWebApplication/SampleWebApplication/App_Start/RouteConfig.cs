// --------------------------------------------------------------------------------------------------------------------
// <copyright file="RouteConfig.cs" company="Objectivity">
//   Copyright (C) 2014 All Rights Reserved
// </copyright>
// <summary>
//   Route config.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

using System.Web.Mvc;
using System.Web.Routing;

namespace SampleWebApplication
{
    public static class RouteConfig
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            int x = 1;
            int y = 2;

            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

            routes.MapRoute(
                name: "Default",
                url: "{controller}/{action}/{id}",
                defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional });
        }
    }
}
