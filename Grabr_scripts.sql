create schema grabr

create database grabr
use grabr

create table [users](
	UserID varchar(3) primary key,
	UserType Varchar (1) check (UserType in ('T','S')),
	FullName varchar(50),
	--dob date,
	Email varchar(65),
	ContactNo char(13),
	Country varchar(60),
	--City varchar(60),
	[Address] Text,
	[Password] Varchar(8)
)

create table shopper(
	UserID varchar(3) Primary key,
	Total_orders int
)

create table traveller(
	UserID varchar(3) Primary key,
	Total_trips int,
	Rating int check (Rating in (1,2,3,4,5))
)

create table [Order](  ---> shopper will order
	OrderId int primary key,
	shopID varchar(3),
	travID varchar(3), 
	offerID int,
	ProductID int,
	shipping_cost int,
	total_cost int,
	orderStatus varchar(15) check (orderStatus in ('Completed', 'In Progress', 'Pending')),
	PaymentMade varchar(15) check (PaymentMade in ('Paid','Not Paid'))
)

create table Product(
	ProductID int primary key,
	Product_Name varchar(60),
	ProductCost int
)

create table offer( -- before accepting the offer --> Traveller will accept the offer
	offerID int Primary key,
	TravID varchar(3) , 
	OrderID int ,
	tripID int ,
	shipping_cost int,
	offerStatus varchar(15) check (offerStatus in ('Accepted','Rejected', 'Pending')),
	PaymentRecieved varchar(15) check (PaymentRecieved in (NULL, 'Recieved', 'Pending', 'Sent'))
)

create table trip(
	tripID int primary key,
	travID varchar(3),
	Country varchar(60), --- destination country
	Arrival_date varchar(10),
	TotalRevenue int,
	tripstatus varchar(15) check (tripStatus in ('Finished', 'To Be Made')),
)

go
create table rating(
	TravID varchar(3) foreign key(TravID) references traveller(UserID),
	ShopID varchar(3) foreign key(ShopID) references Shopper(UserID),
	OrderID int foreign key(OrderID) references [Order](OrderID),
	Stars int check (stars in (1,2,3,4,5))
	Primary Key (TravID , ShopID , OrderID)
)
go
create table bankdetails(
	UserID varchar(3) foreign key(UserID) references [users](UserID) primary key,
	AccountNo varchar(13), 
	AccountHolder varchar(50),
	CardType varchar(7) check(CardType in ('Visa', 'Debit', 'Credit'))
)


alter table [shopper] add constraint FK_userID_shop foreign key(userID) references users(userID) on update cascade
alter table [traveller] add constraint FK_userID_trav foreign key(userID) references users(userID) on update cascade

alter table [Order] add constraint FK_travID_order foreign key(travID) references traveller(userID)  
alter table [Order] add constraint FK_shopID_order foreign key(shopID) references shopper(userID)   ------ not working with update statement
alter table [Order] add constraint FK_ProductID_order foreign key(ProductID) references Product(ProductID) --on update cascade
alter table [Order] add constraint FK_OfferID_order foreign key(OfferID) references Offer(OfferID) -- on update cascade

alter table [Offer] add constraint FK_travID_offer foreign key(travID) references traveller(userID) -- not working with update constraint
alter table [Offer] add constraint FK_orderID_offer foreign key(orderID) references [order](orderID)    ----- not working with update constraint
alter table [Offer] add constraint FK_tripID_offer foreign key(tripID) references trip(tripID)  on update cascade

alter table [Trip] add constraint FK_travID_trip foreign key(travID) references traveller(userID)  ---- not working with update constraint


Insert into users values (1, 'S','Azan Waqar', 'azan@gmail.com', '03423343424','Pakistan', 'Johar townn 212-A','12345678')
Insert into users values (2, 'T','Eemaan Amir', 'eemaan@gmail.com', '03423123424','Canada', 'Toronto', '12345678')

Insert into Shopper values (1, 2)
Insert into Traveller values (2,2,5)


Insert into [Product] values(1, 'Apple AirPods', 250)

Insert into [Order] values( 1, 1, 2 , NULL, 1, 100,1600, 'Completed', 'Paid')

Insert into [trip] values(1,2,'Pakistan','4/20/2021',0, 'Finished')

Insert into [offer] values(1,2,1,1,100,'Accepted','Recieved')

Update [Order]
set OfferID = 1 
where OrderID = 1

go

Create procedure [save_new_user] --sign up
@UserID varchar(3) ,
@UserType Varchar (1),
@FullName varchar(50),
@Email varchar(65),
@ContactNo char(13),
@Country varchar(60),
@Address Text,
@Password Varchar(8),
@AccountNo varchar(13),
@AccountHolder varchar(50),
@CardType varchar(7)
--@output_flag int output
as
begin
	if(@UserType= 't')
	begin
		set @UserType = 'T'
	end
	else
	begin
		set @UserType = 'S'
	end
	INSERT INTO [users](UserID,UserType,FullName,Email,ContactNo,Country,[Address],[Password]) values(@UserID,@UserType,@FullName,@Email,@ContactNo,@Country,@Address,@Password)
	INSERT INTO [bankdetails](UserID , AccountNo , AccountHolder ,CardType) values (@UserID , @AccountNo , @AccountHolder, @CardType)
end


go

create procedure NewLogin -->> login 
@UserID varchar(3) ,
@Password Varchar(8),
@myout int output,
@output_UserType varchar(1) output
as
begin
	if exists(Select UserID from users where UserID = @UserID and [Password] = @Password) 
	begin
	set @myout = 1

	set @output_UserType = (select UserType from users where UserID = @UserID)

	end
	else
	begin
	set @myout = 0
	end
end

go

--Shopper Functions
--> Place Order 
go
Create procedure [placeorder]
@UserID varchar(3),
@Country varchar(60),
@ProductName varchar(50),
@ProductPrice int
as
begin
	declare @count int
	declare @count2 int
	if(exists(Select * from Product where Product.Product_Name = @ProductName and Product.ProductCost = @ProductPrice))
	begin
		set @count = (select count(*) from [Order]) 
		declare @PID int
		set @PID = (select ProductID from Product where Product.Product_Name = @ProductName and Product.ProductCost = @ProductPrice ) 
		Insert into [Order] values( @count+1, @UserID, NULL , NULL, @PID, NULL, @ProductPrice, 'Pending', 'Not Paid')
	end
	else
	begin 
		set @count = (select count(*) from [Order])
		set @count2 = (select count(*) from Product)  
		insert into product (ProductID , Product_Name, ProductCost) values(@count2+1 , @ProductName , @ProductPrice)
		Insert into [Order] values( @count+1, @UserID, NULL , NULL, @count2+1, NULL, @ProductPrice, 'Pending', 'Not Paid')
	end
end

--> Accept Offer
go
Create procedure [acceptoffer]  --> Shopper will accept the offer
@OfferID int ,
@OrderID int
as
begin
	Update [Order]
	set offerID = @OfferID ,
	TravID = (Select TravID from [Offer] where OfferID = @OfferID) ,
	shipping_cost = (Select shipping_cost from offer where OfferID = @OfferID),
	Total_cost = Total_cost + (Select shipping_cost from offer where OfferID = @OfferID),
	[orderStatus] = 'In Progress'
	where OrderID = @OrderID

	Update [Offer]
	set OrderID = @OrderID,
	offerStatus = 'Accepted',
	PaymentRecieved = 'Pending'
	where offerID = @OfferID

	Update [Trip]
	set TotalRevenue = TotalRevenue + (Select Shipping_cost from offer where OfferID = @OfferID)
	where tripID = (Select TripID from [Offer] where OfferID = @OfferID)

	Update [Offer]
	set offerStatus = 'Rejected'
	where orderID = @OrderID and offerID != @OfferID 
	
end

--> Order Recieved
go
create procedure [orderRecieved]
@OrderID int
as
begin
	UPDATE [ORDER]
	set orderStatus = 'Completed'
	where OrderID = @OrderID
end

--> Make Payment
go
create procedure [makePayment]
@OrderID int
as
begin
	Update  [Order]
	set PaymentMade = 'Paid'
	where OrderID = @OrderID

	Update [Offer]
	set PaymentRecieved = 'Sent'
	where OrderID = @OrderID
end


--> Give Ratings
go
create procedure [giveRating]
@OrderID int,
@Stars int
as
begin
	declare @TravID varchar(3)
	declare @ShopID varchar(3)
	set @TravID = (Select TravID from [Order] where OrderID = @OrderID )
	set @ShopID = (Select ShopID from [Order] where OrderID = @OrderID )
	Insert into Rating values (@TravID, @ShopID , @OrderID , @Stars)
	declare @starAvg int
	Set @StarAvg = (Select AVG(Stars) from Rating where TravID = @TravID)
	Update [Traveller]
	set Rating = @StarAvg
	where UserID = @TravID
end

---> Send ID's of last two orders

go
create procedure [lasttwoOrders]
@ShopID varchar(3),
@output_InProgressID int output,
@output_secondRecentID int output
as
begin
	IF(exists(Select * from [Order] where ShopID =@ShopID and Orderstatus IN ('In Progress', 'Pending')))
	begin
		set @output_InProgressID = (Select OrderID from [Order] where ShopID =@ShopID and Orderstatus IN ('In Progress', 'Pending'))	
	end
	else
	begin
		set @output_InProgressID =-1
	end

	if(exists(Select * from [Order] where ShopID =@ShopID and Orderstatus = 'Completed'))
	begin
		set @output_secondRecentID = (Select MAX(OrderID) from [Order] where ShopID =@ShopID and Orderstatus = 'Completed')
	end
	else 
	begin
		set @output_secondRecentID =-1
	end
end


--> Get Order Status
go
Create procedure getOrderStatus
@OrderID int,
@output_orderStatus varchar(15) output
as
begin
	set @output_orderStatus = (Select OrderStatus from [Order] where OrderID =@OrderID)
end

--> GET Order Details procedure

go
Create procedure [getOrderDetails]
@OrderID int,
@output_ProductName varchar(60) output,
@output_ProductCost int output,
@output_totalCost int output,
@output_OrderStatus varchar(15) output,
@output_PaymentStatus varchar(15) output
as
begin
	set @output_ProductName = (Select [Product_Name] from [Product] where ProductID = (Select  ProductID from [Order] where OrderID = @OrderID))
	set @output_ProductCost = (Select [ProductCost] from [Product] where ProductID = (Select  ProductID from [Order] where OrderID = @OrderID))
	set @output_totalCost = (Select  total_cost from [Order] where OrderID = @OrderID)
	set @output_OrderStatus = (Select orderStatus from [Order] where OrderID = @OrderID)
	set @output_PaymentStatus = (select PaymentMade from [Order] where OrderID = @OrderID)
end

-->GET Offer Details

go
create procedure [getOfferDetails]
@OfferID int,
@output_travellerName varchar(50) output,
@output_rating int output,
@output_Date date output , 
@output_shippingCost int output
as
begin
	set @output_travellerName = (Select [FullName] from [users] where UserID = (Select TravID from [Offer] where OfferID = @OfferID))
	set @output_rating = (Select [Rating] from traveller where UserID = (Select TravID from [Offer] where OfferID = @OfferID))
	set @output_Date = (Select [Arrival_date] from trip where tripID = (Select TripID from [Offer] where OfferID = @OfferID))
	set @output_shippingCost = (Select shipping_cost from [Offer] where OfferID = @OfferID)
end


-->GET first 2 offers
go
create procedure [firsttwooffers]
@OrderID int ,
@output_OfferID1 int output, 
@output_OfferID2 int output
as 
begin
	if(exists(Select * from [Offer] where OrderID = @OrderID))
	begin
		set @output_OfferID1 = (Select OfferID from [Offer] where OrderID = @OrderID)
	end
	else
	begin
		set @output_OfferID1 =-1
		set @output_OfferID2 =-1
	end
	if(exists(Select * from [Offer] where OrderID = @OrderID and OfferID != @output_OfferID1))
	begin
		set @output_OfferID2 = (Select OfferID from [Offer] where OrderID = @OrderID)
	end
	else
	begin
		set @output_OfferID2 =-1
	end
end

--> Get Accepted Offer on Order
go
Create procedure [getAcceptedOfferID]
@OrderID int ,
@output_OfferID int output
as
begin
	set @output_OfferID = (Select OfferID from [Order] where OrderID = @OrderID)
end	

--> Has Rating been already given
go
create procedure [ratingGiven]
@OrderID int,
@flag int output
as
begin
	if(exists(Select * from Rating where OrderID = @OrderID))
	begin
		set @flag = 1;
	end
	else
	begin
		set @flag =0;
	end
end


-----------------------------------------------------------------------------------------------------------------------------------
--Traveller Functions

--> Plan Trip

go
create procedure [planTrip]
@TravID varchar(3),
@Country varchar(60),
@Arrival_date varchar(10)
as
begin
	declare @count int 
	set @count = (Select Count(*) from Trip )
	Insert into Trip values (@count+1 , @TravID , @Country , @Arrival_date , 0, 'To Be Made')
end

-->Finish Trip
go
Create procedure [finishTrip]
@TripID int
as
begin
	UPDATE [Trip]
	set tripstatus = 'Finished'
	where TripID = @TripID
end

--> Make Offer
Select * from offer
go
create procedure [makeOffer]
@TripID int, 
@OrderID int,
@shipping_cost int 
as
begin
	declare @TravID varchar(3)
	set @TravID = (Select TravID from [Trip] where TripID = @TripID)
	declare @count int
	set @count = (Select Count(*) from Offer)
	Insert into [Offer] values (@count+1 , @TravID , @OrderID, @tripID, @shipping_cost,'Pending', NULL)
end

--> Confirm Payment
go
create procedure [confirmPayment]
@OrderID int
as
begin
	Update [Offer]
	set PaymentRecieved = 'Recieved'
	where OrderID = @OrderID
end

--> ID'S of last 2 trips

go
create procedure [lasttwoTrips]
@TravID varchar(3),
@output_InProgressID int output,
@output_secondRecentID int output
as
begin
	IF(exists(Select * from [Trip] where TravID =@TravID and tripstatus = 'To Be Made'))
	begin
		set @output_InProgressID = (Select TripID from [Trip] where TravID =@TravID and tripstatus = 'To Be Made')
	end
	else
	begin
		set @output_InProgressID =-1
	end

	if(exists(Select * from [Trip] where TravID =@TravID and tripstatus = 'Finished'))
	begin
		set @output_secondRecentID = (Select MAX(TripID) from [Trip] where TravID =@TravID and tripstatus = 'Finished')
	end
	else 
	begin
		set @output_secondRecentID =-1
	end
end

--> Get Trip Details Procedure
Select * from Trip
go
create Procedure [getTripDetails]
@TripID int ,
@output_Country varchar(60) output,
@output_Arrival_date varchar(10) output,
@output_TotalRevenue int output, 
@output_tripstatus varchar(15) output
as
begin
	set @output_Country = (Select country from [Trip] where tripID = @TripID)
	set @output_Arrival_date = (Select Arrival_date from [Trip] where tripID = @TripID)
	set @output_TotalRevenue = (Select TotalRevenue from [Trip] where tripID = @TripID)
	set @output_tripstatus = (Select tripstatus from [Trip] where tripID = @TripID)

	
end

--> GET MY Accepted OFFer
go
create procedure [getmyAcceptedOffer]
@TripID int ,
@output_OfferID int output
as
begin
	IF(exists(Select * from [Offer] where tripID =@TripID and offerStatus IN ('Accepted','Pending')))
	begin
		set @output_OfferID= (Select OfferID from [Offer] where tripID =@TripID and offerStatus IN ('Accepted','Pending'))
	end
	else
	begin
		set @output_OfferID = -1
	end
end

Select * from [Offer]

--> Get Details of My Accepted Offer
go
create procedure [myofferDetails]
@OfferID int,
@output_shopName varchar(50) output,
@output_offerstatus varchar(15) output , 
@output_cost int output
as
begin
	set @output_shopName = (Select [FullName] from [Users] where UserID = (Select ShopID from [Order] where OfferID = @OfferID))
	set @output_offerstatus =(Select offerstatus from [offer] where OfferID = @OfferID)
	set @output_cost = (Select shipping_cost from [offer] where OfferID = @OfferID) 
end

--> Get Top 2 orders from Destination Country
Select * from Users

Select * from [Order]

go
create procedure [toptwoOrders]
@TripID int,
@output_OrderID1 int output,
@output_OrderID2 int output
as
begin
	if(exists(Select * from [Order] where orderStatus = 'Pending' and ShopID = (Select ShopID from [Users] where Country = (Select Country from [Trip] where TripID = @TripID) )))
	begin
		set @output_OrderID1 = (Select MAX(OrderID) from [Order] where orderStatus = 'Pending' and ShopID = (Select ShopID from [Users] where Country = (Select Country from [Trip] where TripID = @TripID)))
		
		if(exists(Select * from [Order] where orderStatus = 'Pending' and ShopID = (Select ShopID from [Users] where Country = (Select Country from [Trip] where TripID = @TripID)) and OrderID != @output_OrderID1))
		begin
			set @output_OrderID2 = (Select MAX(OrderID) from [Order] where ShopID = (Select ShopID from [Users] where Country = (Select Country from [Trip] where TripID = @TripID)) and OrderID != @output_OrderID1 and orderStatus = 'Pending') 
		end
		else
		begin
			set @output_OrderID2 = -1
		end
	end	
	else
	begin
		set @output_OrderID1 = -1
		set @output_OrderID2 = -1
	end
end

Declare @O1 int
Declare @O2 int 
set @O1 = 0
set @O2 = 0

exec [toptwoOrders]
@TripID = 2,
@output_OrderID1 = @O1 output,
@output_OrderID2 = @O2 output

Select @O1 as OrderID1
Select @O2 as OrderID2

---> CHeck Money sent
go
create procedure [getPaymentStatus]
@OfferID int,
@output_flag int output
as
begin
	if((Select PaymentRecieved from [Offer] where OfferID = @OfferID)='Sent')
	begin
		set @output_flag =1;
	end
	else
	begin
		set @output_flag = 0;
	end
end


-->Recieve Payment
go
create procedure [recievepayment]
@OfferID int
as 
begin
	Update [Offer]
	set PaymentRecieved = 'Recieved'
	where OfferID = @OfferID
end

Select * from users
Select * from shopper
Select * from  traveller
Select * from  [Order]
Select * from [offer]
Select * from trip
Select * from product


drop table users
drop table shopper
drop table traveller
drop table [Order]
drop table [offer]
drop table trip
drop table product

