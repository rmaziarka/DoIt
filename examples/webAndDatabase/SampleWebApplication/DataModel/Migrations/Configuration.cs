namespace DataModel.Migrations
{
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;

    internal sealed class Configuration : DbMigrationsConfiguration<DataModel.MyContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
        }

        protected override void Seed(DataModel.MyContext context)
        {
            //  This method will be called after migrating to the latest version.
            context.Orders.AddOrUpdate(o => o.OrderID, new Order { OrderName = "OrderFromDatabase" });
        }
    }
}
