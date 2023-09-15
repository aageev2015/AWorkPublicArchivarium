ALTER PROCEDURE dbo.sproc_GetFilesTest

AS
SET NOCOUNT ON
BEGIN
DECLARE @fso INTEGER -- File system object
DECLARE @fldr INTEGER -- File system folder
DECLARE @file INTEGER -- File system file
DECLARE @filename NVARCHAR(200) -- File name

-- Create file system object
EXEC sp_OACreate 'scripting.filesystemobject', @fso OUTPUT

-- Create folder object from input parameter
EXEC sp_OAMethod @fso, 'GetFolder("c:\permal\documents")', @fldr OUTPUT

-- Test
SELECT @fso -- Produces integer on execution
SELECT @fldr -- Produces integer on execution

/* HOW DO I DO THIS?
-- Get list of document filenames


For Each file In fldr.Files

@FileName = @file.Name
INSERT INTO tblDocuments(DocumentName)
VALUES(@FileName)
Next
*/

END