select baze64, ts, a.* from sch.TICKET  a
cross apply (select convert(varbinary(max), a.ts) as '*' for xml path('')) T (baze64)
where baze64 like '%+%'