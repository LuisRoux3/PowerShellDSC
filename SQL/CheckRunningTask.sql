SELECT
	percent_complete,start_time,
	estimated_completion_time,
	start_time,
	dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time,
	CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
	+ CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
    + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go
--	select  *
  FROM sys.dm_exec_requests
  where percent_complete > 0
  --WHERE session_id = 85

/*
    Took from:
    https://social.msdn.microsoft.com/Forums/sqlserver/en-US/2c8eca51-6259-4a51-bf42-8bfe1c688a58/i-want-estimatedcompletiontime-value-in-seconds?forum=sqldatabaseengine
*/