SELECT dbo.regexReplace( firstname, '[^a-z]', '', 1, 1 ) FROM account;



The more efficient method is:

DECLARE @regex integer;
SET @regex = dbo.regexObj( '[^a-z]', 1, 1 );
SELECT dbo.regexObjReplace( @regex, firstname, '' ) FROM account;



CREATE FUNCTION dbo.regexObj
(
@regexp varchar(1000),
@globalReplace bit = 0,
@ignoreCase bit = 0
)
RETURNS integer AS
BEGIN
DECLARE @hr integer
DECLARE @objRegExp integer

EXECUTE @hr = sp_OACreate 'VBScript.RegExp', @objRegExp OUTPUT
IF @hr <> 0 BEGIN
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Pattern', @regexp
IF @hr <> 0 BEGIN
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Global', @globalReplace
IF @hr <> 0 BEGIN
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'IgnoreCase', @ignoreCase
IF @hr <> 0 BEGIN
RETURN NULL
END

RETURN @objRegExp
END
GO


CREATE FUNCTION dbo.regexObjFind
(
@objRegExp integer,
@source varchar(5000)
)
RETURNS bit AS
BEGIN
DECLARE @hr integer
DECLARE @results bit

EXECUTE @hr = sp_OAMethod @objRegExp, 'Test', @results OUTPUT, @source
IF @hr <> 0 BEGIN
RETURN NULL
END

RETURN @results
END
GO


CREATE FUNCTION dbo.regexObjReplace
(
@objRegExp integer,
@source varchar(5000),
@replace varchar(1000)
)
RETURNS varchar(1000) AS
BEGIN
DECLARE @hr integer
DECLARE @result varchar(5000)

EXECUTE @hr = sp_OAMethod @objRegExp, 'Replace', @result OUTPUT, @source, @replace
IF @hr <> 0 BEGIN
RETURN NULL
END

RETURN @result
END
GO


CREATE FUNCTION dbo.regexFind
(
@source varchar(5000),
@regexp varchar(1000),
@ignoreCase bit = 0
)
RETURNS bit AS
BEGIN
DECLARE @hr integer
DECLARE @objRegExp integer
DECLARE @results bit

SET @results = 0

EXECUTE @hr = sp_OACreate 'VBScript.RegExp', @objRegExp OUTPUT
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Pattern', @regexp
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Global', false
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'IgnoreCase', @ignoreCase
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END 
EXECUTE @hr = sp_OAMethod @objRegExp, 'Test', @results OUTPUT, @source
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OADestroy @objRegExp
IF @hr <> 0 BEGIN
RETURN NULL
END

RETURN @results
END
GO


CREATE FUNCTION dbo.regexReplace
(
@source varchar(5000),
@regexp varchar(1000),
@replace varchar(1000),
@globalReplace bit = 0,
@ignoreCase bit = 0
)
RETURNS varchar(1000) AS
BEGIN
DECLARE @hr integer
DECLARE @objRegExp integer
DECLARE @result varchar(5000)

EXECUTE @hr = sp_OACreate 'VBScript.RegExp', @objRegExp OUTPUT
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Pattern', @regexp
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'Global', @globalReplace
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OASetProperty @objRegExp, 'IgnoreCase', @ignoreCase
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END 
EXECUTE @hr = sp_OAMethod @objRegExp, 'Replace', @result OUTPUT, @source, @replace
IF @hr <> 0 BEGIN
EXEC @hr = sp_OADestroy @objRegExp
RETURN NULL
END
EXECUTE @hr = sp_OADestroy @objRegExp
IF @hr <> 0 BEGIN
RETURN NULL
END

RETURN @result
END
GO