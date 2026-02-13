
USE LCA
--SELECT *   FROM [LCA].[dboReaders].[VW_MRP_ReportLastest] order by RowL
--ALTER INDEX [IX_ComponentLibrary_DatabaseUnitID_4910F] ON dbo.ComponentLibrary REBUILD
SELECT
    r.session_id,
    s.login_name,
    s.host_name,
    c.client_net_address, -- Dirección IP del cliente
    r.status,
    r.start_time,
    r.command,
    r.database_id,
    DB_NAME(r.database_id) AS database_name,
    --r.wait_type,
    r.wait_time,
    --r.last_wait_type,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    r.row_count,
    st.text AS sql_text
    --qp.query_plan
FROM sys.dm_exec_requests AS r
INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id
INNER JOIN sys.dm_exec_connections AS c ON r.session_id = c.session_id -- Unir con conexiones para obtener la IP
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
WHERE r.session_id != @@SPID -- Excluir la sesión actual
ORDER BY r.session_id;



--SELECT "Tbl1005"."Fecha" "Col1010","Tbl1005"."MO" "Col1011" FROM "lca"."dboReaders"."vw_PivotSerigrafia" "Tbl1005" WITH (NOLOCK) ORDER BY "Col1011" ASC


