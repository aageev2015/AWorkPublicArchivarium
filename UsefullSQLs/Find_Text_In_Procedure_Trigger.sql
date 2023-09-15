select id,name from sysobjects o
where xtype in ('P', 'TR')
and OBJECT_DEFINITION(id) like '%str_GeoX%'