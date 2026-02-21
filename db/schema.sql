CREATE TABLE Users (
  UniqueID VARCHAR(100) PRIMARY KEY,
  FirstName VARCHAR(100) NOT NULL,
  LastName VARCHAR(100) NOT NULL,
  Type VARCHAR(50) NOT NULL,
  Status VARCHAR(50) NOT NULL,
  VPN BIT NOT NULL DEFAULT 0, -- A user does not have VPN access by default
  ADUsername VARCHAR(100),
  DateCreated DATETIME NOT NULL DEFAULT GETDATE(),
  DateLastModified DATETIME NOT NULL DEFAULT GETDATE(),
  Password VARCHAR(255)
);
GO

-- Update the DateLastModified column when the Users table is updated
CREATE TRIGGER trg_UpdateDateLastModified
ON Users
AFTER UPDATE
AS
BEGIN
  UPDATE Users
  SET DateLastModified = GETDATE()
  WHERE UniqueID IN (SELECT UniqueID FROM inserted);
END;
GO
