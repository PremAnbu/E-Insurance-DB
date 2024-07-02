use [E-Insurance]
CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY,
	FullName Nvarchar(max) Not null,
    EmailId NVARCHAR(255) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL
);
CREATE TABLE Admins (
    Id INT PRIMARY KEY IDENTITY(1,1),
    AdminName NVARCHAR(100) NOT NULL,
	EmailId NVARCHAR(255) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL
);
select * from Admins
select * from Agents
exec SP_rename 'Agents.AgentName','FullName','COLUMN'
CREATE TABLE Agents (
    Id INT PRIMARY KEY IDENTITY(1,1),
    AgentName NVARCHAR(100) NOT NULL,
	EmailId NVARCHAR(255) NOT NULL UNIQUE,
	Location Nvarchar(255) not null,
    Password NVARCHAR(255) NOT NULL,
	Role NVARCHAR(20) NOT NULL
);
CREATE TABLE Employees (
    Id INT PRIMARY KEY IDENTITY(1,1),
    EmployeeName NVARCHAR(100) NOT NULL,
	EmailId NVARCHAR(255) NOT NULL UNIQUE,
    Password NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) NOT NULL
);
select * from Customers
create table Customers(
Id int primary key IDENTITY(1,1),
Name Nvarchar(max),
EmailId NVARCHAR(255) NOT NULL UNIQUE,
Password NVARCHAR(255) NOT NULL,
Role NVARCHAR(20) NOT NULL
);
CREATE TABLE AllPolicies(
    PolicyId INT PRIMARY KEY IDENTITY(1,1),
    PolicyNumber VARCHAR(50) NOT NULL UNIQUE,
    PolicyName VARCHAR(MAX) NOT NULL,
    PolicyDescription VARCHAR(MAX) NOT NULL,
    PolicyType VARCHAR(MAX) NOT NULL,
    ClaimSettlementRatio VARCHAR(10) NOT NULL,
    EntryAge INT NOT NULL,
    AnnualPremiumRange DECIMAL(18,2),
    Status VARCHAR(20) DEFAULT 'Pending'
);
select * from AllPolicies
select * from CustomerDetails
delete from CustomerDetails where DetailsId in(15,16)
CREATE TABLE CustomerDetails(
    DetailsId INT PRIMARY KEY IDENTITY(1,1),
    CustomerId INT NOT NULL,
    PolicyId INT NOT NULL,
    AgentId INT NOT NULL,
    AnnualIncome DECIMAL(15,2),
    FirstName NVARCHAR(MAX) NOT NULL,
    LastName NVARCHAR(MAX) NOT NULL,
    Gender NVARCHAR(20) NOT NULL,
    DateOfBirth DATE NOT NULL,
    MobileNumber BIGINT NOT NULL,
    Address NVARCHAR(MAX) NOT NULL,
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
    FOREIGN KEY (PolicyId) REFERENCES AllPolicies(PolicyId),
    FOREIGN KEY (AgentId) REFERENCES Agents(Id)
);
CREATE TABLE PremiumRates (
    RateId INT PRIMARY KEY IDENTITY(1,1),
    PolicyType VARCHAR(50) NOT NULL,
    AgeGroup VARCHAR(50) NOT NULL,
    Rate DECIMAL(18, 2) NOT NULL
);
select * from PremiumRates
select * from Payments
delete from Payments where PaymentId in(17)
drop table Payments
create TABLE Payments (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    PaymentDate DATE NOT NULL,
    Status VARCHAR(20) DEFAULT 'Pending',
	PaymentMethod NVARCHAR(50),
	PremiumAmount DECIMAL(10, 2) NOT NULL,
	CustomerId int not null foreign key references Customers(Id),	
    PurchaseId INT NOT NULL FOREIGN KEY REFERENCES PolicyPurchases(PurchaseId)
);
select * from PolicyPurchases
update PolicyPurchases set Status='Active'  where PurchaseId in(1)
delete from PolicyPurchases where PurchaseId in(16,17)
CREATE TABLE PolicyPurchases (
    PurchaseId INT IDENTITY(1,1) PRIMARY KEY, 
    PolicyId INT NOT NULL FOREIGN KEY REFERENCES AllPolicies(PolicyId),
	PolicyType Nvarchar(max) not null,
    CustomerId INT NOT NULL FOREIGN KEY REFERENCES Customers(Id),
	AgentId INT NOT NULL FOREIGN KEY REFERENCES Agents(Id),
    CoverageAmount DECIMAL(18, 2) NOT NULL, 
    Tenure INT NOT NULL, 
    PremiumType NVARCHAR(50) NOT NULL,
	PremiumAmount decimal(18,2) not null,
    Status VARCHAR(20) DEFAULT 'Active',
    PurchaseDate DATE DEFAULT GETDATE() 
);
select * from CommissionRates
CREATE TABLE CommissionRates (
    CommissionRateId INT PRIMARY KEY IDENTITY(1,1),
    PolicyType NVARCHAR(50) NOT NULL,
    CommissionRate DECIMAL(5, 2) NOT NULL -- as percentage
);
select * from Commissions
CREATE TABLE Commissions (
    CommissionId INT PRIMARY KEY IDENTITY(1,1),
    PolicyPurchaseId INT NOT NULL FOREIGN KEY REFERENCES PolicyPurchases(PurchaseId),
    AgentId INT NOT NULL foreign key references Agents(Id),
    CommissionAmount DECIMAL(18, 2) NOT NULL,
    CalculationDate DATE DEFAULT GETDATE()
);