% Copyright 2013 Barzan Mozafari
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function [aggMatrix suggestion] = aggregateMonitor(filename, addHeader)
%this function changes the number of columns (removes the system date and 3
%load averages.
%this function averages the stats of all the 16 cores
%this function takes the diff for those variables that are accumulative
%originally
%WARNING: The diff will make any constant attribute zero! which should be
%ok for now��

%header = '"epoch","year","load_1m","load_5m","load_15m","cpu_usr","cpu_sys","cpu_total","cpu_wai","cpu_hiq","cpu_siq","memory_used","memory_buff","memory_cach","memory_free","net_recv","net_send","dsk_read","dsk_writ","io_read","io_writ","async_aio","swap_used","swap_free","paging_in","paging_out","virtual_majpf","virtual_minpf","virtual_alloc","virtual_free","filesystem_files","filesystem_inodes","interupts_19","interupts_23","interupts_33","interupts_79","interupts_80","interupts_81","interupts_82","interupts_83","interupts_84","interupts_85","interupts_86","system_int","system_csw","procs_run","procs_blk","procs_new","sda_util","Aborted_clients","Aborted_connects","Binlog_cache_disk_use","Binlog_cache_use","Bytes_received","Bytes_sent","Com_admin_commands","Com_assign_to_keycache","Com_alter_db","Com_alter_db_upgrade","Com_alter_event","Com_alter_function","Com_alter_procedure","Com_alter_server","Com_alter_table","Com_alter_tablespace","Com_analyze","Com_backup_table","Com_begin","Com_binlog","Com_call_procedure","Com_change_db","Com_change_master","Com_check","Com_checksum","Com_commit","Com_create_db","Com_create_event","Com_create_function","Com_create_index","Com_create_procedure","Com_create_server","Com_create_table","Com_create_trigger","Com_create_udf","Com_create_user","Com_create_view","Com_dealloc_sql","Com_delete","Com_delete_multi","Com_do","Com_drop_db","Com_drop_event","Com_drop_function","Com_drop_index","Com_drop_procedure","Com_drop_server","Com_drop_table","Com_drop_trigger","Com_drop_user","Com_drop_view","Com_empty_query","Com_execute_sql","Com_flush","Com_grant","Com_ha_close","Com_ha_open","Com_ha_read","Com_help","Com_insert","Com_insert_select","Com_install_plugin","Com_kill","Com_load","Com_load_master_data","Com_load_master_table","Com_lock_tables","Com_optimize","Com_preload_keys","Com_prepare_sql","Com_purge","Com_purge_before_date","Com_release_savepoint","Com_rename_table","Com_rename_user","Com_repair","Com_replace","Com_replace_select","Com_reset","Com_restore_table","Com_revoke","Com_revoke_all","Com_rollback","Com_rollback_to_savepoint","Com_savepoint","Com_select","Com_set_option","Com_show_authors","Com_show_binlog_events","Com_show_binlogs","Com_show_charsets","Com_show_collations","Com_show_column_types","Com_show_contributors","Com_show_create_db","Com_show_create_event","Com_show_create_func","Com_show_create_proc","Com_show_create_table","Com_show_create_trigger","Com_show_databases","Com_show_engine_logs","Com_show_engine_mutex","Com_show_engine_status","Com_show_events","Com_show_errors","Com_show_fields","Com_show_function_status","Com_show_grants","Com_show_keys","Com_show_master_status","Com_show_new_master","Com_show_open_tables","Com_show_plugins","Com_show_privileges","Com_show_procedure_status","Com_show_processlist","Com_show_profile","Com_show_profiles","Com_show_slave_hosts","Com_show_slave_status","Com_show_status","Com_show_storage_engines","Com_show_table_status","Com_show_tables","Com_show_triggers","Com_show_variables","Com_show_warnings","Com_slave_start","Com_slave_stop","Com_stmt_close","Com_stmt_execute","Com_stmt_fetch","Com_stmt_prepare","Com_stmt_reprepare","Com_stmt_reset","Com_stmt_send_long_data","Com_truncate","Com_uninstall_plugin","Com_unlock_tables","Com_update","Com_update_multi","Com_xa_commit","Com_xa_end","Com_xa_prepare","Com_xa_recover","Com_xa_rollback","Com_xa_start","CompressionOFF","Connections","Created_tmp_disk_tables","Created_tmp_files","Created_tmp_tables","Delayed_errors","Delayed_insert_threads","Delayed_writes","Flush_commands","Handler_commit","Handler_delete","Handler_discover","Handler_prepare","Handler_read_first","Handler_read_key","Handler_read_next","Handler_read_prev","Handler_read_rnd","Handler_read_rnd_next","Handler_rollback","Handler_savepoint","Handler_savepoint_rollback","Handler_update","Handler_write","Innodb_buffer_pool_pages_data","Innodb_buffer_pool_pages_dirty","Innodb_buffer_pool_pages_flushed","Innodb_buffer_pool_pages_free","Innodb_buffer_pool_pages_misc","Innodb_buffer_pool_pages_total","Innodb_buffer_pool_read_ahead_rnd","Innodb_buffer_pool_read_ahead_seq","Innodb_buffer_pool_read_requests","Innodb_buffer_pool_reads","Innodb_buffer_pool_wait_free","Innodb_buffer_pool_write_requests","Innodb_data_fsyncs","Innodb_data_pending_fsyncs","Innodb_data_pending_reads","Innodb_data_pending_writes","Innodb_data_read","Innodb_data_reads","Innodb_data_writes","Innodb_data_written","Innodb_dblwr_pages_written","Innodb_dblwr_writes","Innodb_have_atomic_builtinsON","Innodb_log_waits","Innodb_log_write_requests","Innodb_log_writes","Innodb_os_log_fsyncs","Innodb_os_log_pending_fsyncs","Innodb_os_log_pending_writes","Innodb_os_log_written","Innodb_page_size","Innodb_pages_created","Innodb_pages_read","Innodb_pages_written","Innodb_row_lock_current_waits","Innodb_row_lock_time","Innodb_row_lock_time_avg","Innodb_row_lock_time_max","Innodb_row_lock_waits","Innodb_rows_deleted","Innodb_rows_inserted","Innodb_rows_read","Innodb_rows_updated","Key_blocks_not_flushed","Key_blocks_unused","Key_blocks_used","Key_read_requests","Key_reads","Key_write_requests","Key_writes","Last_query_cost.","Max_used_connections","Not_flushed_delayed_rows","Open_files","Open_streams","Open_table_definitions","Open_tables","Opened_files","Opened_table_definitions","Opened_tables","Prepared_stmt_count","Qcache_free_blocks","Qcache_free_memory","Qcache_hits","Qcache_inserts","Qcache_lowmem_prunes","Qcache_not_cached","Qcache_queries_in_cache","Qcache_total_blocks","Queries","Questions","Rpl_statusNULL","Select_full_join","Select_full_range_join","Select_range","Select_range_check","Select_scan","Slave_open_temp_tables","Slave_retried_transactions","Slave_runningOFF","Slow_launch_threads","Slow_queries","Sort_merge_passes","Sort_range","Sort_rows","Sort_scan","Ssl_accept_renegotiates","Ssl_accepts","Ssl_callback_cache_hits","Ssl_cipher","Ssl_cipher_list","Ssl_client_connects","Ssl_connect_renegotiates","Ssl_ctx_verify_depth","Ssl_ctx_verify_mode","Ssl_default_timeout","Ssl_finished_accepts","Ssl_finished_connects","Ssl_session_cache_hits","Ssl_session_cache_misses","Ssl_session_cache_modeNONE","Ssl_session_cache_overflows","Ssl_session_cache_size","Ssl_session_cache_timeouts","Ssl_sessions_reused","Ssl_used_session_cache_entries","Ssl_verify_depth","Ssl_verify_mode","Ssl_version","Table_locks_immediate","Table_locks_waited","Tc_log_max_pages_used","Tc_log_page_size","Tc_log_page_waits","Threads_cached","Threads_connected","Threads_created","Threads_running","Uptime","Uptime_since_flush_status","Data_memory","Index_memory","REDO","ndbnodecount","DATA_MEMORY","DISK_OPERATIONS","DISK_RECORDS","FILE_BUFFERS","JOBBUFFER","RESERVED","TRANSPORT_BUFFERS"';

header_index;

filtered_header = '"Tran1","Tran2","Tran3","Tran4","Tran5","Latency1","Latency2","Latency3","Latency4","Latency5","cpu_usr","cpu_sys","cpu_total","cpu_wai","cpu_hiq","cpu_siq","memory_used","memory_buff","memory_cach","memory_free","net_recv","net_send","dsk_read","dsk_writ","io_read","io_writ","swap_used","swap_free","paging_in","paging_out","virtual_majpf","virtual_minpf","virtual_alloc","virtual_free","filesystem_files","filesystem_inodes","interupts_33","interupts_79","interupts_80","interupts_81","interupts_82","interupts_83","interupts_84","interupts_85","interupts_86","system_int","system_csw","procs_run","procs_blk","procs_new","sda_util","Bytes_received","Bytes_sent","Com_commit","Com_delete","Com_insert","Com_rollback","Com_select","Com_update","Created_tmp_tables","Handler_commit","Handler_delete","Handler_read_key","Handler_read_next","Handler_read_prev","Handler_rollback","Handler_update","Handler_write","Innodb_buffer_pool_pages_data","Innodb_buffer_pool_pages_dirty","Innodb_buffer_pool_pages_flushed","Innodb_buffer_pool_pages_free","Innodb_buffer_pool_pages_misc","Innodb_buffer_pool_read_requests","Innodb_buffer_pool_reads","Innodb_buffer_pool_write_requests","Innodb_data_fsyncs","Innodb_data_pending_reads","Innodb_data_read","Innodb_data_reads","Innodb_data_writes","Innodb_data_written","Innodb_dblwr_pages_written","Innodb_dblwr_writes","Innodb_log_write_requests","Innodb_log_writes","Innodb_os_log_fsyncs","Innodb_os_log_written","Innodb_pages_created","Innodb_pages_read","Innodb_pages_written","Innodb_row_lock_current_waits","Innodb_row_lock_time","Innodb_row_lock_time_avg","Innodb_row_lock_time_max","Innodb_row_lock_waits","Innodb_rows_deleted","Innodb_rows_inserted","Innodb_rows_read","Innodb_rows_updated","Open_tables","Opened_tables","Queries","Questions","Select_range","Slow_queries","Table_locks_immediate","Threads_running","Uptime","Uptime_since_flush_status"';

featureset = [cpu_usr cpu_sys cpu_total cpu_wai cpu_hiq cpu_siq memory_used memory_buff memory_cach memory_free net_recv net_send dsk_read dsk_writ io_read io_writ swap_used swap_free paging_in paging_out virtual_majpf virtual_minpf virtual_alloc virtual_free filesystem_files filesystem_inodes interupts_33 interupts_79 interupts_80 interupts_81 interupts_82 interupts_83 interupts_84 interupts_85 interupts_86 system_int system_csw procs_run procs_blk procs_new sda_util Bytes_received Bytes_sent Com_commit Com_delete Com_insert Com_rollback Com_select Com_update Created_tmp_tables Handler_commit Handler_delete Handler_read_key Handler_read_next Handler_read_prev Handler_rollback Handler_update Handler_write Innodb_buffer_pool_pages_data Innodb_buffer_pool_pages_dirty Innodb_buffer_pool_pages_flushed Innodb_buffer_pool_pages_free Innodb_buffer_pool_pages_misc Innodb_buffer_pool_read_requests Innodb_buffer_pool_reads Innodb_buffer_pool_write_requests Innodb_data_fsyncs Innodb_data_pending_reads Innodb_data_read Innodb_data_reads Innodb_data_writes Innodb_data_written Innodb_dblwr_pages_written Innodb_dblwr_writes Innodb_log_write_requests Innodb_log_writes Innodb_os_log_fsyncs Innodb_os_log_written Innodb_pages_created Innodb_pages_read Innodb_pages_written Innodb_row_lock_current_waits Innodb_row_lock_time Innodb_row_lock_time_avg Innodb_row_lock_time_max Innodb_row_lock_waits Innodb_rows_deleted Innodb_rows_inserted Innodb_rows_read Innodb_rows_updated Open_tables Opened_tables Queries Questions Select_range Slow_queries Table_locks_immediate Threads_running Uptime Uptime_since_flush_status];

M = bload(filename, 7);
cpu0  = M(:, 6:11);
cpu1  = M(:, 12:17);
cpu2  = M(:, 18:23);
cpu3  = M(:, 24:29);
cpu4  = M(:, 30:35);
cpu5  = M(:, 36:41);
cpu6  = M(:, 42:47);
cpu7  = M(:, 48:53);
cpu8  = M(:, 54:59);
cpu9  = M(:, 60:65);
cpu10 = M(:, 66:71);
cpu11 = M(:, 72:77);
cpu12 = M(:, 78:83);
cpu13 = M(:, 84:89);
cpu14 = M(:, 90:95);
cpu15 = M(:, 96:101);
cpuAvg = cpu0 + cpu1 + cpu2 + cpu3 + cpu4 + cpu5 + cpu6 + cpu7 + cpu8 + cpu9 + cpu10 + cpu11 + cpu12 + cpu13 + cpu14 + cpu15;
       
cpuAvg = cpuAvg / 16.0;

aggMatrixRaw = [M(:,1:5) cpuAvg(:,1:2) 100.0-cpuAvg(:,3:3) cpuAvg(:,4:6) M(:, 102: 442)];

aggMatrixRaw = aggMatrixRaw(:,featureset);

aggMatrix = diff_if_necessary(aggMatrixRaw);
suggestion = diffSuggestion(aggMatrixRaw);

if (addHeader)
    system(horzcat('echo ', filtered_header, ' > ', filename,'.csv'));
    dlmwrite(horzcat(filename,'.csv'), aggMatrix, 'delimiter',',','-append');
else    
    dlmwrite(horzcat(filename,'.csv'), aggMatrix, 'delimiter',',');  
end

end
