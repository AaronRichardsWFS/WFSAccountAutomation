# WFSAccountAutomation

WFS Account Automation Scripts

## Setup Guide

1. Install [sqlcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install).

2. Connect to the database using the following command:

   ```powershell
   sqlcmd -S <server> -d <database> -U <username> -P <password>
   ```

3. Run the following command to create the Users table:

   ```sqlcmd
   :r ./db/schema.sql
   ```

4. Run the following command to verify the table was created.
   You should see the Users table in the results.

   ```sqlcmd
   :r ./db/read.sql
   ```

## Utility SQL Scripts

### Drop Users Table

```sqlcmd
:r ./db/drop.sql
```
