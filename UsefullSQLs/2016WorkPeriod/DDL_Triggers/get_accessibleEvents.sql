WITH EventsReports (name, PARENT_TYPE, type, level, sort) AS
(
    SELECT CONVERT (varchar (255), '0.' + type_name), PARENT_TYPE, type, 1, CONVERT (varchar (255), type_name)
    FROM sys.trigger_event_types 
    WHERE PARENT_TYPE IS NULL
    UNION ALL
    SELECT CONVERT (varchar (255), convert(varchar(255), level) + '.' + CONVERT (varchar (255), e.type_name)),
        e.parent_type, e.type, level + 1,
	   CONVERT (varchar (255), RTRIM (sort) + '.' + e.type_name)
    FROM sys.trigger_event_types as e
    INNER JOIN EventsReports d ON e.parent_type = d.type
)
SELECT PARENT_TYPE, type, name, sort
FROM EventsReports
--where [name] like '% object%'
ORDER BY sort;