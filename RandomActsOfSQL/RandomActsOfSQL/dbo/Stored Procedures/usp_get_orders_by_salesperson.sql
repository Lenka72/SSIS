

-- ================================================
-- Author:		Elaena Bakman		 
-- Create date: 05/27/2018
-- Description:	This will pull Sales Data by
-- SalesPerson form WideWorldImporters
-- Update:		
-- ================================================

CREATE PROCEDURE [dbo].[usp_get_orders_by_salesperson] (
        @SalesPersonName NVARCHAR(50) = NULL)
AS
BEGIN
        SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        SELECT          P.FullName
                       ,O.OrderId
                       ,C.CustomerName
                       ,O.OrderDate
                       ,O.ExpectedDeliveryDate
                       ,OL.OrderLineID
                       ,OL.StockItemID
                       ,OL.Description
                       ,OL.Quantity
                       ,OL.UnitPrice
                       ,OL.TaxRate
                       ,SUM(    OL.UnitPRice * OL.Quantity) OVER (PARTITION BY O.OrderId) AS OrderSubtotal
                       ,(SUM(    OL.UnitPRice * OL.Quantity) OVER (PARTITION BY O.OrderId) / 100) * OL.TaxRate AS OrderTax
        FROM            WideWorldImporters.Sales.Orders O
        INNER   JOIN    WideWorldImporters.Sales.OrderLines OL
        ON OL.OrderID = O.OrderID
        INNER   JOIN    WideWorldImporters.Application.People P
        ON P.PersonID = O.SalespersonPersonID
        INNER   JOIN    WideWorldImporters.Sales.Customers C
        ON C.CustomerID = O.CustomerID
        WHERE           P.FullName = ISNULL( @SalesPersonName, P.FullName)
		ORDER BY O.OrderDate;
END;
