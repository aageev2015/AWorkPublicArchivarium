select day(Modifiedon),
	month(Modifiedon),
	year(Modifiedon),count(*) from tbl_plgscServicehistory
group by day(Modifiedon),
	month(Modifiedon),
	year(Modifiedon)
order by year(Modifiedon) desc,
	month(Modifiedon) desc,
	 day(Modifiedon) desc