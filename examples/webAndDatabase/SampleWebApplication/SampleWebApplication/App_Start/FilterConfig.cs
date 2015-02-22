// --------------------------------------------------------------------------------------------------------------------
// <copyright file="FilterConfig.cs" company="Objectivity">
//   Copyright (C) 2014 All Rights Reserved
// </copyright>
// <summary>
//   Filter config.
// </summary>
// --------------------------------------------------------------------------------------------------------------------

using System;
using System.Web.Mvc;

namespace SampleWebApplication
{
    public static class FilterConfig
    {
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            if (filters == null)
            {
                throw new ArgumentNullException("filters");
            }

            filters.Add(new HandleErrorAttribute());
        }
    }
}
