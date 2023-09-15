/*
1 enable clr

2
alter PROCEDURE [dbo].[USER_LOG]
	@SEVERITY INT = 1,
	@SOURCE VARCHAR(50),
	@MSG VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON
	
--	EXEC USER_LOG_CONSOLE @SEVERITY, @SOURCE, @MSG
--	EXEC USER_LOG_DATABASE @SEVERITY, @SOURCE, @MSG
--	EXEC USER_LOG_DB_LOG @SEVERITY, @SOURCE, @MSG
	exec USER_LOG_FILE_LOG @SEVERITY, @SOURCE, @MSG
END

*/
alter PROCEDURE USER_LOG_FILE_LOG
 (
	@SEVERITY INT = 1,
	@SOURCE VARCHAR(50),
	@MSG VARCHAR(255)
--
)
AS
	DECLARE  @objFileSystem int
			,@objTextStream int,
			@objErrorObject int,
			@strErrorMessage Varchar(1000),
			@Command varchar(1000),
			@hr int,
			@FileAndPath NVARCHAR(500)  ='c:\temp\'+db_name()+'.log',
			@String varchar(max) = 
					convert(varchar(30), getdate()) + ', ' + convert(nvarchar(15), @SEVERITY) + ', ' + isnull(@Source,'<No Source>') + char(13)
				+	isnull(@MSG, '<NULL>') + char(13)+ char(13)

	set nocount on
	select @strErrorMessage='opening the File System Object'
	EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT
	
	if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
	if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'OpenTextFile'
		, @objTextStream OUT, @FileAndPath,8,True, -1
	if @HR=0 Select @objErrorObject=@objTextStream, 
		@strErrorMessage='writing to the file "'+@FileAndPath+'"'
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Write', Null, @String
	if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'
	if @hr<>0
		BEGIN
		DECLARE 
			@Source_OA varchar(255),
			@Description Varchar(255),
			@Helpfile Varchar(255),
			@HelpID int
		
			EXECUTE sp_OAGetErrorInfo  @objErrorObject,@Source_OA output,@Description output,@Helpfile output,@HelpID output
			SELECT @strErrorMessage='Error whilst '
				+coalesce(@strErrorMessage,'doing something')
				+', '+coalesce(@Description,'')
			RAISERROR (@strErrorMessage,16,1)
		END
	EXECUTE  sp_OADestroy @objTextStream
	EXECUTE sp_OADestroy @objFileSystem 