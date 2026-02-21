# WFSAccountAutomation

WFS Account Automation Scripts

## Setup Guide

0. Create a `.env` file by copying the `.env.example` file and filling in the values.

1. Install [sqlcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install).

2. Connect to the database using the following command:

   ```powershell
   sqlcmd -S <server> -d <database> -U <username> -P <password>
   ```

3. Run the following command to create the Users table:

   ```sqlcmd
   :r ./db/schema.sql
   ```

   - You can drop the table and trigger by running the following command if you wish to start fresh:

     ```sqlcmd
     :r ./db/drop.sql
     ```

4. Run the following command to verify the table was created.
   You should see the `Users` table and
   the `trg_UpdateDateLastModified` trigger in the results.

   ```sqlcmd
   :r ./db/read.sql
   ```

5. Run the following command to test the database functionality.
   You should see the output of the test script in the console.

   ```powershell
   pwsh test-db.ps1
   ```
