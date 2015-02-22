// --------------------------------------------------------------------------------------------------------------------
// <copyright file="HomeController.cs" company="Objectivity">
//   Copyright (C) 2014 All Rights Reserved
// </copyright>
// <summary>
//   Home controller.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

namespace SampleWebApplication.Controllers
{
    using DataModel;
    using System.Reflection;
    using System.Web.Mvc;

    public class HomeController : Controller
    {
        #region Public Methods and Operators

        public ActionResult About()
        {
            this.ViewBag.Message = "Your application description page.";

            return this.View();
        }

        public ActionResult Contact()
        {
            this.ViewBag.Message = "Your contact page.";

            return this.View();
        }

        public ActionResult Index()
        {
            ViewBag.Version = Assembly.GetAssembly(this.GetType()).GetName().Version.ToString();

            using (var context = new MyContext())
            {
                ViewBag.Order = context.Orders.Find(1);
            } 

            return this.View();
        }

        #endregion
    }
}