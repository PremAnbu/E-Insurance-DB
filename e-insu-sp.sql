use [E-Insurance]
drop table Customers
drop table Agents
drop table Employees
drop table Admins
--Store Procedures:
alter proc SP_RegisterAdmin
    @FullName NVARCHAR(MAX),
    @EmailId NVARCHAR(255),
    @Password NVARCHAR(MAX),
    @Role NVARCHAR(20)
AS
BEGIN
    INSERT INTO Admins (AdminName, EmailId, Password, Role)
    VALUES (@FullName, @EmailId, @Password, @Role);
END;
alter proc SP_AddEmployee
    @FullName NVARCHAR(MAX),
    @EmailId NVARCHAR(255),
    @Password NVARCHAR(MAX),
    @Role NVARCHAR(20)
AS
BEGIN
    INSERT INTO Employees (EmployeeName, EmailId, Password, Role)
    VALUES (@FullName, @EmailId, @Password, @Role);
end
alter proc SP_AddAgent
    @FullName NVARCHAR(MAX),
    @EmailId NVARCHAR(255),
    @Password NVARCHAR(MAX),
	@Location Nvarchar(255),
    @Role NVARCHAR(20)
AS
BEGIN
    INSERT INTO Agents (AgentName, EmailId, Password,Location,Role)
    VALUES (@FullName, @EmailId, @Password,@Location,@Role);
end
alter proc SP_AddCustomer
@FullName Nvarchar(max) ,
@EmailId NVARCHAR(255) ,
@Password NVARCHAR(255),
@Role NVARCHAR(20)
as
begin
Insert into Customers(Name,EmailId,Password,Role)
values(@FullName,@EmailId,@Password,@Role)
end
alter proc AdminLogin_sp
@Email Nvarchar(255)
as
begin
SELECT * FROM Admins WHERE EmailId=@Email
end
alter proc EmployeeLogin_sp
@Email Nvarchar(255)
as
begin
SELECT * FROM Employees WHERE EmailId=@Email
end
create proc AgentLogin_sp
@Email Nvarchar(255)
as
begin
SELECT * FROM Agents WHERE EmailId=@Email
end
create proc CustomerLogin_sp
@Email Nvarchar(255)
as
begin
SELECT * FROM Customers WHERE EmailId=@Email
end
CREATE or alter PROCEDURE SP_InsertPolicy
    @PolicyNumber VARCHAR(50),
    @PolicyName VARCHAR(MAX),
    @PolicyDescription VARCHAR(MAX),
    @PolicyType VARCHAR(MAX),
    @ClaimSettlementRatio VARCHAR(10),
    @EntryAge INT,
    @AnnualPremiumRange DECIMAL(18,2)
AS
BEGIN
    INSERT INTO AllPolicies (
        PolicyNumber, 
        PolicyName, 
        PolicyDescription, 
        PolicyType, 
        ClaimSettlementRatio, 
        EntryAge, 
        AnnualPremiumRange,
        Status
    )
    VALUES (
        @PolicyNumber, 
        @PolicyName, 
        @PolicyDescription, 
        @PolicyType, 
        @ClaimSettlementRatio, 
        @EntryAge, 
        @AnnualPremiumRange,
        'Pending'
    );
END;
CREATE or alter TRIGGER tgr_Policy_AfterInsert
ON Policies
AFTER INSERT
AS
BEGIN
    UPDATE AllPolicies
    SET Status = 'Active'
    WHERE PolicyId IN (SELECT PolicyId FROM inserted);
END;
create or alter PROCEDURE SP_CalculatePremium
    @PolicyId INT,
    @CoverageAmount DECIMAL(18, 2),
    @Tenure INT,
    @PremiumType NVARCHAR(50),
    @Premium DECIMAL(18, 2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Age INT;
    DECLARE @BaseRate DECIMAL(18, 2);
    DECLARE @FrequencyMultiplier DECIMAL(18, 2);
    DECLARE @IncomeDiscount DECIMAL(18, 2);
    DECLARE @PolicyType VARCHAR(50);
    DECLARE @AnnualIncome DECIMAL(15, 2);
    DECLARE @DateOfBirth DATE;
    SET @Premium = 0;
    SELECT 
       @AnnualIncome = pp.AnnualIncome,
       @DateOfBirth = pp.DateOfBirth,
       @PolicyType = p.PolicyType
    FROM CustomerDetails pp
    JOIN AllPolicies p ON pp.PolicyId = p.PolicyId
    WHERE pp.PolicyId = @PolicyId;
    SET @Age = DATEDIFF(YEAR, @DateOfBirth, GETDATE()) - 
               CASE 
                   WHEN DATEADD(YEAR, DATEDIFF(YEAR, @DateOfBirth, GETDATE()), @DateOfBirth) > GETDATE() THEN 1 
                   ELSE 0 
               END;
    DECLARE @AgeGroup NVARCHAR(50);
    IF @Age BETWEEN 0 AND 18
        SET @AgeGroup = '0-18';
    ELSE IF @Age BETWEEN 19 AND 24
        SET @AgeGroup = '19-24';
    ELSE IF @Age BETWEEN 25 AND 35
        SET @AgeGroup = '25-35';
    ELSE IF @Age BETWEEN 36 AND 45
        SET @AgeGroup = '36-45';
    ELSE IF @Age BETWEEN 46 AND 55
        SET @AgeGroup = '46-55';
    ELSE IF @Age > 55
        SET @AgeGroup = '56+';
    ELSE
    BEGIN
        RAISERROR('Invalid age calculated.', 16, 1);
        RETURN;
    END
    SELECT @BaseRate = Rate
    FROM PremiumRates
    WHERE PolicyType = @PolicyType AND AgeGroup = @AgeGroup;
    IF @BaseRate IS NULL
    BEGIN
        RAISERROR('Rate not found for the given PolicyType and AgeGroup.', 16, 1);
        RETURN;
    END
    IF @PremiumType = 'Annual'
        SET @FrequencyMultiplier = 1.00;
    ELSE IF @PremiumType = 'Half-Yearly'
        SET @FrequencyMultiplier = 0.52; 
    ELSE IF @PremiumType = 'Quarterly'
        SET @FrequencyMultiplier = 0.26;
    ELSE IF @PremiumType = 'Monthly'
        SET @FrequencyMultiplier = 0.09; 
    ELSE
    BEGIN
        RAISERROR('Invalid premium type provided.', 16, 1);
        RETURN;
    END
    IF @AnnualIncome < 300000
        SET @IncomeDiscount = 0.90; 
    ELSE IF @AnnualIncome >= 300000 AND @AnnualIncome < 500000
        SET @IncomeDiscount = 0.95; 
    ELSE
        SET @IncomeDiscount = 1.00; 

    SET @Premium = @BaseRate * @CoverageAmount / 1000 * @FrequencyMultiplier * @Tenure * @IncomeDiscount;
    IF @Premium <= 0
    BEGIN
        RAISERROR('Premium calculation resulted in an invalid value.', 16, 1);
        RETURN;
    END
END;

create or ALTER PROCEDURE SP_AddCustomerDetails
    @CustomerId INT,
    @PolicyId INT,
    @AgentId INT,
    @AnnualIncome DECIMAL(15,2),
    @FirstName NVARCHAR(MAX),
    @LastName NVARCHAR(MAX),
    @Gender NVARCHAR(20),
    @DateofBirth DATE,
    @MobileNumber BIGINT,
    @Address NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO CustomerDetails(
        CustomerId, PolicyId, AgentId, AnnualIncome, FirstName, LastName, 
        Gender, DateofBirth, MobileNumber, Address
    )
    VALUES (
        @CustomerId, @PolicyId, @AgentId, @AnnualIncome, @FirstName, @LastName, 
        @Gender, @DateofBirth, @MobileNumber, @Address
    )
END;
create or alter PROCEDURE SP_getCustomerPolicies
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.*
    FROM Policies p
    JOIN PolicyPurchase c ON p.PolicyId = c.PolicyId
    WHERE c.CustomerId = @CustomerId;
END;

CREATE TABLE PremiumRates (
    RateId INT PRIMARY KEY IDENTITY(1,1),
    PolicyType VARCHAR(50) NOT NULL,
    AgeGroup VARCHAR(50) NOT NULL,
    Rate DECIMAL(18, 2) NOT NULL
);
drop table PremiumRates

create or alter PROCEDURE SP_AddPremiumRate
    @PolicyType VARCHAR(50),
    @AgeGroup VARCHAR(50),
    @Rate DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO PremiumRates (PolicyType, AgeGroup, Rate)
    VALUES (@PolicyType, @AgeGroup, @Rate);
    SELECT SCOPE_IDENTITY() AS RateId;
END;

	
CREATE or alter TRIGGER trg_AfterPaymentInsert
ON Payments
AFTER INSERT
AS
BEGIN
    UPDATE Payments SET Status = 'Successful' WHERE PaymentId IN (SELECT PaymentId FROM inserted)
      AND PremiumAmount > 0
END;

drop proc SP_InsertPayment

create or ALTER PROCEDURE SP_InsertPayment
    @PaymentDate DATE,
    @PaymentMethod NVARCHAR(50),
    @PurchaseId INT,
    @CustomerId INT,
    @PaymentId INT OUTPUT
AS
BEGIN
    DECLARE @Status VARCHAR(20) = 'Pending';
    DECLARE @PremiumAmount DECIMAL(10, 2);

    SELECT @PremiumAmount = PremiumAmount
    FROM PolicyPurchases
    WHERE PurchaseId = @PurchaseId;

    IF @PremiumAmount IS NULL
    BEGIN
        RAISERROR('Premium amount not found for the given PolicyId.', 16, 1);
        RETURN;
    END

    INSERT INTO Payments (PaymentDate, PremiumAmount, Status, PaymentMethod, CustomerId, PurchaseId)
    VALUES (@PaymentDate, @PremiumAmount, @Status, @PaymentMethod, @CustomerId, @PurchaseId);

    SET @PaymentId = SCOPE_IDENTITY();
END;

create or alter proc SP_getPayments
@CustomerId int
as
begin
select * from Payments where CustomerId=@CustomerId
end

create or alter proc SP_getPolicyPayment
@PaymentId int,@CustomerId int, @PolicyId int
as
begin
SELECT 
        p.PaymentId,
        p.PaymentDate,
        p.Status,
        p.PaymentMethod,
        p.PremiumAmount,
        p.PurchaseId,
		p.CustomerId,
        cd.FirstName,
        cd.LastName,
        cd.Gender,
        cd.DateOfBirth,
        cd.MobileNumber,
        cd.Address,
        cd.AnnualIncome,
		cd.AgentId,
		cd.PolicyId
FROM 
        Payments p
    INNER JOIN 
        CustomerDetails cd ON p.CustomerId = cd.CustomerId
    INNER JOIN 
        PolicyPurchases pp ON p.PurchaseId = pp.PurchaseId
    WHERE 
        p.PaymentId = @PaymentId and cd.PolicyId=@PolicyId AND p.CustomerId = @CustomerId
end

EXEC dbo.SP_getPolicyPayment @PaymentId = 2,@PolicyId=1, @CustomerId = 1;


create or alter PROCEDURE SP_InsertPolicyPurchase
    @PolicyId INT,
    @CustomerId INT,
    @CoverageAmount DECIMAL(18, 2),
    @Tenure INT,
    @PremiumType NVARCHAR(50),
    @PremiumAmount DECIMAL(18, 2)
AS
BEGIN
	Declare @AgentId int;
	Declare @PolicyType nvarchar(max);
	select @PolicyType=PoliCyType
	from AllPolicies
	where PolicyId=@PolicyId
	select @AgentId=AgentId 
	from CustomerDetails 
	where CustomerId=@CustomerId;
    IF @CoverageAmount IS NULL OR @Tenure IS NULL OR @PremiumType IS NULL OR @PremiumAmount IS NULL
    BEGIN
        RAISERROR('Premium calculation data not found for the given PolicyId.', 16, 1);
        RETURN;
    END
    INSERT INTO PolicyPurchases (
        PolicyId, 
		PolicyType,
        CustomerId,
		AgentId,
        CoverageAmount, 
        Tenure, 
        PremiumType, 
		PremiumAmount,
        Status,
        PurchaseDate
    )
    VALUES (
        @PolicyId,
		@PolicyType,
        @CustomerId, 
		@AgentId,
        @CoverageAmount, 
        @Tenure, 
        @PremiumType,
		@PremiumAmount,
        'Active', 
        GETDATE()
    );
END;
create or alter proc SP_getAllPolicies
as
begin
select * from AllPolicies
end

create or alter proc SP_getCustomerPolicies
@CustomerId int
as
begin
select * from PolicyPurchases where CustomerId=@CustomerId and Status='Active'
end

create or alter proc SP_PolicyCancellation
@CustomerId int,
@PolicyId int
as
begin
update PolicyPurchases set Status='Cancelled' where CustomerId=@CustomerId and PolicyId=@PolicyId
end

CREATE or alter PROCEDURE SP_AddCommissionRate
@PolicyType NVARCHAR(50),
@Rate int
AS
BEGIN
	SET NOCOUNT ON;
    INSERT INTO CommissionRates(PolicyType,CommissionRate)
    VALUES (@PolicyType, @Rate);
    SELECT SCOPE_IDENTITY() AS RateId;
END

create or alter PROCEDURE SP_CalculateCommission
    @PolicyPurchaseId INT
AS
BEGIN
    DECLARE @PremiumAmount DECIMAL(18, 2);
    DECLARE @PolicyType NVARCHAR(50);
    DECLARE @CommissionRate DECIMAL(5, 2);
    DECLARE @CommissionAmount DECIMAL(18, 2);
	Declare @AgentId int
    SELECT @PremiumAmount=PremiumAmount,
	       @PolicyType=PolicyType,
		   @AgentId=AgentId
    FROM PolicyPurchases
    WHERE PurchaseId = @PolicyPurchaseId;

    SELECT @CommissionRate = CommissionRate
    FROM CommissionRates
    WHERE PolicyType = @PolicyType 
    IF @CommissionRate IS NULL
    BEGIN
        RAISERROR('Commission rate not found for the given PolicyType.', 16, 1);
        RETURN;
    END
    SET @CommissionAmount = @PremiumAmount * (@CommissionRate / 100)
    INSERT INTO Commissions (
        PolicyPurchaseId, 
        AgentId, 
        CommissionAmount, 
        CalculationDate
    )
    VALUES (
        @PolicyPurchaseId, 
        @AgentId, 
        @CommissionAmount, 
        GETDATE()
    );
END;

create or alter proc SP_getAgentCommission
@AgentId int
As
begin
select * from Commissions where AgentId=@AgentId
end

create or alter proc SP_getAgentPolicies
@AgentId int
as
begin
select * from PolicyPurchases where AgentId=@AgentId
end
EXEC SP_getAgentPolicies @AgentId = 1;

create or alter proc SP_getAllAgents
as
begin
select * from Agents
end
