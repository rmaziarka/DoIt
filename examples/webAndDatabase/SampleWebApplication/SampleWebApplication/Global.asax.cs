// --------------------------------------------------------------------------------------------------------------------
// <copyright file="Global.asax.cs" company="Objectivity">
//   Copyright (C) 2014 All Rights Reserved
// </copyright>
// <summary>
//   Global asax.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace SampleWebApplication
{
    public class MvcApplication : HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }
    }
}