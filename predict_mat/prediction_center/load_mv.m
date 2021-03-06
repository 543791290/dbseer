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

function [mvGrouped mvUngrouped] = load_mv(header, monitor, avglat, prclat, IndividualCounts, dM, groupingStrategy, tranTypes)
overallTime = tic;

mvGrouped = struct();
mvUngrouped = struct();

mvUngrouped.prclat = prclat;
mvGrouped.prclat = prclat;

% mvUngrouped.tranTypes = tranTypes;
% mvGrouped.tranTypes = tranTypes;

if nargin > 6
    [monitor_grouped avglat_grouped IndividualCounts_grouped dM_grouped] = applyGroupingPolicy(groupingStrategy, monitor, avglat, IndividualCounts, dM);
else
    monitor_grouped = monitor;
    avglat_grouped = avglat;
    IndividualCounts_grouped = IndividualCounts;
    dM_grouped = dM;
end

%%% For ungrouped mv
mvUngrouped.cpu_usr = monitor(:,header.metadata.cpu_usr);     % here we ignore hyperthreading, i.e. we take all CPUs from dstat data.
mvUngrouped.cpu_sys = monitor(:,header.metadata.cpu_sys);
mvUngrouped.cpu_idl = monitor(:,header.metadata.cpu_idl);
mvUngrouped.numOfTransType = size(IndividualCounts,2);
mvUngrouped.clientTransLatency = avglat;
mvUngrouped.numberOfObservations = size(monitor, 1);

mvUngrouped.CoreVariance = var(mvUngrouped.cpu_usr,0,2);
[mvUngrouped.AvgCpuUser mvUngrouped.AvgCpuSys mvUngrouped.AvgCpuIdle mvUngrouped.AvgCpuWai mvUngrouped.AvgCpuHiq mvUngrouped.AvgCpuSiq] = CpuAggregate2(monitor(:,:), header);

mvUngrouped.osAsynchronousIO = monitor(:,header.columns.aio);
mvUngrouped.osNumberOfContextSwitches = monitor(:,header.columns.csw);
if exist('extra') == 1
    mvUngrouped.osNumberOfSectorReads = sum(monitor(:,extra.disk),2)./1024./1024; %MB
    mvUngrouped.osNumberOfSectorWrites = sum(monitor(:,header.extra.disk+1),2)./1024./1024; %MB
else
    mvUngrouped.osNumberOfSectorReads = monitor(:,header.columns.dsk_read)./1024./1024; %MB
    mvUngrouped.osNumberOfSectorWrites = monitor(:,header.columns.dsk_writ)./1024./1024; %MB
end
mvUngrouped.osAllocatedFileHandlers = monitor(:,header.columns.filesystem_files);
mvUngrouped.osAllocatedINodes = monitor(:,header.columns.filesystem_inodes);
mvUngrouped.osCountOfInterruptsServicedSinceBootTime = monitor(:,header.columns.int);
fn = fieldnames(header.metadata.interrupts);
mvUngrouped.osNumberOfInterrupt = length(fn);
for i=1:length(fn)
    eval(['mvUngrouped.osInterruptCount' num2str(i) '= monitor(:,header.metadata.interrupts.' fn{i} ');']);
end
if exist('extra') == 1
    mvUngrouped.osNumberOfReadsIssued = sum(monitor(:,extra.io),2)./1024./1024; %MB
    mvUngrouped.osNumberOfWritesCompleted = sum(monitor(:,extra.io+1),2)./1024./1024; %MB
else
    mvUngrouped.osNumberOfReadsIssued = monitor(:,header.columns.io_read)./1024./1024; %MB
    mvUngrouped.osNumberOfWritesCompleted = monitor(:,header.columns.io_writ)./1024./1024; %MB
end
mvUngrouped.osNumberOfSwapInSinceLastBoot = monitor(:,header.columns.paging_in);
mvUngrouped.osNumberOfSwapOutSinceLastBoot = monitor(:,header.columns.paging_out);
mvUngrouped.osNumberOfProcessesCreated = monitor(:,header.columns.procs_new);
mvUngrouped.osNumberOfProcessesCurrentlyRunning = monitor(:,header.columns.procs_run);
if exist('extra') == 1
    mvUngrouped.osDiskUtilization = sum(monitor(:,extra.util),2);
else
    mvUngrouped.osDiskUtilization = monitor(:,header.columns.util);
end
mvUngrouped.osFreeSwapSpace = monitor(:,header.columns.swap_free);
mvUngrouped.osUsedSwapSpace = monitor(:,header.columns.swap_used);
mvUngrouped.osNumberOfAllocatedPage = monitor(:,header.columns.virtual_alloc);
mvUngrouped.osNumberOfFreePages = monitor(:,header.columns.virtual_free);
mvUngrouped.osNumberOfMajorPageFaults = monitor(:,header.columns.virtual_majpf);
mvUngrouped.osNumberOfMinorPageFaults = monitor(:,header.columns.virtual_minpf);
mvUngrouped.osNetworkSendKB=sum(monitor(:,header.metadata.net_send),2) ./1024;
mvUngrouped.osNetworkRecvKB=sum(monitor(:,header.metadata.net_recv),2) ./1024;

mvUngrouped.clientTotalSubmittedTrans=sum(IndividualCounts(:,:), 2);
mvUngrouped.clientIndividualSubmittedTrans=IndividualCounts;


%Init
if strcmpi(header.dbms, 'mysql')
	if isfield(header.columns, 'mysql_cpu')
		mvUngrouped.dbmsMeasuredCPU = monitor(:, header.columns.mysql_cpu);
	end
    mvUngrouped.dbmsChangedRows = sum(dM(:,[header.columns.Innodb_rows_deleted header.columns.Innodb_rows_updated header.columns.Innodb_rows_inserted]),2);
    mvUngrouped.dbmsCumChangedRows=cumsum(mvUngrouped.dbmsChangedRows);
    mvUngrouped.dbmsCumFlushedPages = monitor(:, header.columns.Innodb_buffer_pool_pages_flushed);
    mvUngrouped.dbmsFlushedPages = DoSmooth(dM(:, header.columns.Innodb_buffer_pool_pages_flushed), 10);
    %mvUngrouped.dbmsFlushedPages = dM(:, header.columns.Innodb_buffer_pool_pages_flushed);
    mvUngrouped.dbmsCurrentDirtyPages = monitor(:, header.columns.Innodb_buffer_pool_pages_dirty);
    mvUngrouped.dbmsDirtyPages = dM(:, header.columns.Innodb_buffer_pool_pages_dirty);
    mvUngrouped.dbmsDataPages = monitor(:, header.columns.Innodb_buffer_pool_pages_data);
    mvUngrouped.dbmsFreePages = monitor(:, header.columns.Innodb_buffer_pool_pages_free);
    mvUngrouped.dbmsTotalPages = monitor(:, header.columns.Innodb_buffer_pool_pages_total); 
    mvUngrouped.dbmsThreadsRunning = monitor(:, header.columns.Threads_running); 
    mvUngrouped.dbmsTotalWritesMB=dM(:,header.columns.Innodb_data_written)./1024./1024; %MB
    mvUngrouped.dbmsLogWritesMB=dM(:,header.columns.Innodb_os_log_written)./1024./1024; %MB
    mvUngrouped.dbmsNumberOfPhysicalLogWrites=dM(:,header.columns.Innodb_log_writes);
    mvUngrouped.dbmsNumberOfDataReads=dM(:,header.columns.Innodb_data_reads);
    mvUngrouped.dbmsNumberOfDataWrites=dM(:,header.columns.Innodb_data_writes);
    
    mvUngrouped.dbmsNumberOfLogWriteRequests=dM(:,header.columns.Innodb_log_write_requests);
    mvUngrouped.dbmsNumberOfFysncLogWrites=dM(:,header.columns.Innodb_os_log_fsyncs);
    mvUngrouped.dbmsNumberOfPendingLogWrites=dM(:,header.columns.Innodb_os_log_pending_writes);
    mvUngrouped.dbmsNumberOfPendingLogFsyncs=dM(:,header.columns.Innodb_os_log_pending_fsyncs);

    mvUngrouped.dbmsNumberOfNextRowReadRequests=dM(:,header.columns.Handler_read_rnd_next);
    mvUngrouped.dbmsNumberOfRowInsertRequests=dM(:,header.columns.Handler_write);
    mvUngrouped.dbmsNumberOfFirstEntryReadRequests=dM(:,header.columns.Handler_read_first);
    mvUngrouped.dbmsNumberOfKeyBasedReadRequests=dM(:,header.columns.Handler_read_key);
    mvUngrouped.dbmsNumberOfNextKeyBasedReadRequests=dM(:,header.columns.Handler_read_next);
    mvUngrouped.dbmsNumberOfPrevKeyBasedReadRequests=dM(:,header.columns.Handler_read_prev);
    mvUngrouped.dbmsNumberOfRowReadRequests=dM(:,header.columns.Handler_read_rnd);
    
    mvUngrouped.dbmsPageWritesMB=dM(:,header.columns.Innodb_pages_written).*2.*16./1024; % to account for double write buffering
    mvUngrouped.dbmsDoublePageWritesMB=dM(:,header.columns.Innodb_dblwr_pages_written).*2.*16./1024; % to account for double write buffering
    mvUngrouped.dbmsDoubleWritesOperations=dM(:,header.columns.Innodb_dblwr_writes);

    mvUngrouped.dbmsNumberOfPendingWrites=dM(:,header.columns.Innodb_data_pending_writes);
    mvUngrouped.dbmsNumberOfPendingReads=dM(:,header.columns.Innodb_data_pending_reads);
    
    mvUngrouped.dbmsBufferPoolWrites = dM(:,header.columns.Innodb_buffer_pool_write_requests);
    mvUngrouped.dbmsRandomReadAheads = dM(:,header.columns.Innodb_buffer_pool_read_ahead_rnd);
    mvUngrouped.dbmsSequentialReadAheads = dM(:,header.columns.Innodb_buffer_pool_read_ahead_seq);
    mvUngrouped.dbmsNumberOfLogicalReadRequests = dM(:,header.columns.Innodb_buffer_pool_read_requests);
    mvUngrouped.dbmsNumberOfLogicalReadsFromDisk = dM(:,header.columns.Innodb_buffer_pool_reads);
    mvUngrouped.dbmsNumberOfWaitsForFlush = dM(:,header.columns.Innodb_buffer_pool_wait_free);

    % stats on how many and what type of SQL statements were run
    mvUngrouped.dbmsCommittedCommands=dM(:,header.columns.Com_commit);
    mvUngrouped.dbmsRolledbackCommands=dM(:,header.columns.Com_rollback);
    mvUngrouped.dbmsRollbackHandler=dM(:,header.columns.Handler_rollback);
    
    % latency stats
    % mvUngrouped.measuredCPU=monitor(:,header.columns.mysqld_cpu)+monitor(:,header.columns.mysqld_children_cpu);
    % mvUngrouped.measuredWritesMB=monitor(:,header.columns.mysqld_bytes_written) / 1024 / 1024;
    % mvUngrouped.measuredReadsMB=monitor(:,header.columns.mysqld_bytes_read) / 1024 / 1024;

    lock_smoothing = 1;
    mvUngrouped.dbmsCurrentLockWaits=DoSmooth(monitor(:,header.columns.Innodb_row_lock_current_waits), lock_smoothing);
    mvUngrouped.dbmsLockWaits=DoSmooth(dM(:,header.columns.Innodb_row_lock_waits), lock_smoothing);
    mvUngrouped.dbmsLockWaitTime=DoSmooth(dM(:,header.columns.Innodb_row_lock_time), lock_smoothing) / 1000; % to turn it into seconds!
    %mvUngrouped.dbmsCurrentLockWaits=monitor(:,header.columns.Innodb_row_lock_current_waits);
    %mvUngrouped.dbmsLockWaits=dM(:,header.columns.Innodb_row_lock_waits);
    %mvUngrouped.dbmsLockWaitTime=dM(:,header.columns.Innodb_row_lock_time) / 1000; % to turn it into seconds!
    % if exist('OCTAVE_VERSION')
    %     save('dbmsCurrentLockWaits_Octave.mat', '-v6', '-struct', 'mvUngrouped', 'dbmsCurrentLockWaits');
    %     save('dbmsLockWaits_Octave.mat', '-v6', '-struct', 'mvUngrouped', 'dbmsLockWaits');
    %     save('dbmsLockWaitTime_Octave.mat', '-v6', '-struct', 'mvUngrouped', 'dbmsLockWaitTime');
    % else
    %     save('dbmsCurrentLockWaits_Matlab', '-v6', '-struct', 'mvUngrouped', 'dbmsCurrentLockWaits');
    %     save('dbmsLockWaits_Matlab', '-v6', '-struct', 'mvUngrouped', 'dbmsLockWaits');
    %     save('dbmsLockWaitTime_Matlab', '-v6', '-struct', 'mvUngrouped', 'dbmsLockWaitTime');
    % end

    mvUngrouped.dbmsReadRequests = dM(:, header.columns.Innodb_buffer_pool_read_requests);
    mvUngrouped.dbmsReads = dM(:, header.columns.Innodb_buffer_pool_reads);
    mvUngrouped.dbmsPhysicalReadsMB = dM(:,[header.columns.Innodb_data_read])./1024./1024;

    if isfield(header.columns, 'Innodb_page_size')
        mvUngrouped.dbmsPageSize = max(monitor(:, header.columns.Innodb_page_size));
    end
    if isfield(header.columns, 'Innodb_buffer_pool_size')
        mvUngrouped.dbmsBufferPoolSize = max(monitor(:, header.columns.Innodb_buffer_pool_size));
    end
    if isfield(header.columns, 'Innodb_log_file_size')
        mvUngrouped.dbmsLogFileSize = max(monitor(:, header.columns.Innodb_log_file_size));
    end

elseif strcmpi(header.dbms, 'psql')
    mvUngrouped.dbmsFlushedPages = DoSmooth(dM(:, header.columns.buffers_clean)+dM(:, header.columns.buffers_backend), 10);
    %mvUngrouped.dbmsFlushedPages = dM(:, header.columns.buffers_clean)+dM(:, header.columns.buffers_backend);
    mvUngrouped.dbmsLogWritesMB=dM(:,header.columns.buffers_checkpoint).*8192./1024./1024; %MB
    mvUngrouped.dbmsPageWritesMB=(dM(:,header.columns.buffers_clean)+dM(:,header.columns.buffers_backend)).*2.*8./1024; % to account for double write buffering
    mvUngrouped.dbmsCommittedCommands=dM(:,header.columns.xact_commit);
    mvUngrouped.dbmsRolledbackCommands=dM(:,header.columns.xact_rollback);
    mvUngrouped.measuredCPU=monitor(:,header.columns.postgres_cpu) + monitor(:,header.columns.postgres_children_cpu);
    mvUngrouped.measuredWritesMB=monitor(:,header.columns.postgres_bytes_written) / 1024 / 1024;
    mvUngrouped.measuredReadsMB=monitor(:,header.columns.postgres_bytes_read) / 1024 / 1024;
    mvUngrouped.dbmsReadRequests = dM(:, header.columns.blks_read) + dM(:, header.columns.blks_hit);
    mvUngrouped.dbmsReads = dM(:, header.columns.blks_read);
else
    error(['Sorry, we currently do not support the ' header.dbms ' DBMS']);
end


%%% For grouped
mvGrouped.cpu_usr = monitor_grouped(:,header.metadata.cpu_usr);     % here we ignore hyperthreading, i.e. we take all CPUs from dstat data.
mvGrouped.cpu_sys = monitor_grouped(:,header.metadata.cpu_sys);
mvGrouped.cpu_idl = monitor_grouped(:,header.metadata.cpu_idl);
mvGrouped.numOfTransType = size(IndividualCounts_grouped,2);
mvGrouped.clientTransLatency = avglat_grouped;
mvGrouped.numberOfObservations = size(monitor_grouped, 1);

mvGrouped.CoreVariance = var(mvGrouped.cpu_usr,0,2);
[mvGrouped.AvgCpuUser mvGrouped.AvgCpuSys mvGrouped.AvgCpuIdle mvGrouped.AvgCpuWai mvGrouped.AvgCpuHiq mvGrouped.AvgCpuSiq] = CpuAggregate2(monitor_grouped(:,:), header);


mvGrouped.osAsynchronousIO = monitor_grouped(:,header.columns.aio);
mvGrouped.osNumberOfContextSwitches = monitor_grouped(:,header.columns.csw);

if exist('extra') == 1
    mvGrouped.osNumberOfSectorReads = sum(monitor_grouped(:,extra.disk),2)./1024./1024; %MB
    mvGrouped.osNumberOfSectorWrites = sum(monitor_grouped(:,header.extra.disk+1),2)./1024./1024; %MB
else
    mvGrouped.osNumberOfSectorReads = monitor_grouped(:,header.columns.dsk_read)./1024./1024; %MB
    mvGrouped.osNumberOfSectorWrites = monitor_grouped(:,header.columns.dsk_writ)./1024./1024; %MB
end

mvGrouped.osAllocatedFileHandlers = monitor_grouped(:,header.columns.filesystem_files);
mvGrouped.osAllocatedINodes = monitor_grouped(:,header.columns.filesystem_inodes);
mvGrouped.osCountOfInterruptsServicedSinceBootTime = monitor_grouped(:,header.columns.int);
fn = fieldnames(header.metadata.interrupts);
mvGrouped.osNumberOfInterrupt = length(fn);
for i=1:length(fn)
    eval(['mvGrouped.osInterruptCount' num2str(i) '= monitor_grouped(:,header.metadata.interrupts.' fn{i} ');']);
end

if exist('extra') == 1
    mvGrouped.osNumberOfReadsIssued = sum(monitor_grouped(:,extra.io),2)./1024./1024; %MB
    mvGrouped.osNumberOfWritesCompleted = sum(monitor_grouped(:,extra.io+1),2)./1024./1024; %MB
else
    mvGrouped.osNumberOfReadsIssued = monitor_grouped(:,header.columns.io_read)./1024./1024; %MB
    mvGrouped.osNumberOfWritesCompleted = monitor_grouped(:,header.columns.io_writ)./1024./1024; %MB
end

mvGrouped.osNumberOfSwapInSinceLastBoot = monitor_grouped(:,header.columns.paging_in);
mvGrouped.osNumberOfSwapOutSinceLastBoot = monitor_grouped(:,header.columns.paging_out);
mvGrouped.osNumberOfProcessesCreated = monitor_grouped(:,header.columns.procs_new);
mvGrouped.osNumberOfProcessesCurrentlyRunning = monitor_grouped(:,header.columns.procs_run);

if exist('extra') == 1
    mvGrouped.osDiskUtilization = sum(monitor_grouped(:,extra.util),2);
else
    mvGrouped.osDiskUtilization = monitor_grouped(:,header.columns.util);
end
mvGrouped.osFreeSwapSpace = monitor_grouped(:,header.columns.swap_free);
mvGrouped.osUsedSwapSpace = monitor_grouped(:,header.columns.swap_used);
mvGrouped.osNumberOfAllocatedPage = monitor_grouped(:,header.columns.virtual_alloc);
mvGrouped.osNumberOfFreePages = monitor_grouped(:,header.columns.virtual_free);
mvGrouped.osNumberOfMajorPageFaults = monitor_grouped(:,header.columns.virtual_majpf);
mvGrouped.osNumberOfMinorPageFaults = monitor_grouped(:,header.columns.virtual_minpf);
mvGrouped.osNetworkSendKB=monitor_grouped(:,header.metadata.net_send) ./1024;
mvGrouped.osNetworkRecvKB=monitor_grouped(:,header.metadata.net_recv)./1024;

mvGrouped.clientTotalSubmittedTrans=sum(IndividualCounts_grouped(:,:), 2);
mvGrouped.clientIndividualSubmittedTrans=IndividualCounts_grouped;

%Init
if strcmpi(header.dbms, 'mysql')
    mvGrouped.dbmsChangedRows = sum(dM_grouped(:,[header.columns.Innodb_rows_deleted header.columns.Innodb_rows_updated header.columns.Innodb_rows_inserted]),2);
    mvGrouped.dbmsCumChangedRows=cumsum(mvGrouped.dbmsChangedRows);
    mvGrouped.dbmsCumFlushedPages = monitor_grouped(:, header.columns.Innodb_buffer_pool_pages_flushed);
    mvGrouped.dbmsFlushedPages = DoSmooth(dM_grouped(:, header.columns.Innodb_buffer_pool_pages_flushed), 10);
    %mvGrouped.dbmsFlushedPages = dM_grouped(:, header.columns.Innodb_buffer_pool_pages_flushed);
    mvGrouped.dbmsCurrentDirtyPages = monitor_grouped(:, header.columns.Innodb_buffer_pool_pages_dirty);
    mvGrouped.dbmsDirtyPages = dM_grouped(:, header.columns.Innodb_buffer_pool_pages_dirty);
    mvGrouped.dbmsDataPages = monitor_grouped(:, header.columns.Innodb_buffer_pool_pages_data);
    mvGrouped.dbmsFreePages = monitor_grouped(:, header.columns.Innodb_buffer_pool_pages_free);
    mvGrouped.dbmsTotalPages = monitor_grouped(:, header.columns.Innodb_buffer_pool_pages_total); 
    mvGrouped.dbmsThreadsRunning = monitor_grouped(:, header.columns.Threads_running); 
    mvGrouped.dbmsTotalWritesMB=dM_grouped(:,header.columns.Innodb_data_written)./1024./1024; %MB
    mvGrouped.dbmsLogWritesMB=dM_grouped(:,header.columns.Innodb_os_log_written)./1024./1024; %MB
    mvGrouped.dbmsNumberOfPhysicalLogWrites=dM_grouped(:,header.columns.Innodb_log_writes);
    mvGrouped.dbmsNumberOfDataReads=dM_grouped(:,header.columns.Innodb_data_reads);
    mvGrouped.dbmsNumberOfDataWrites=dM_grouped(:,header.columns.Innodb_data_writes);
    
    mvGrouped.dbmsNumberOfLogWriteRequests=dM_grouped(:,header.columns.Innodb_log_write_requests);
    mvGrouped.dbmsNumberOfFysncLogWrites=dM_grouped(:,header.columns.Innodb_os_log_fsyncs);
    mvGrouped.dbmsNumberOfPendingLogWrites=dM_grouped(:,header.columns.Innodb_os_log_pending_writes);
    mvGrouped.dbmsNumberOfPendingLogFsyncs=dM_grouped(:,header.columns.Innodb_os_log_pending_fsyncs);

    mvGrouped.dbmsNumberOfNextRowReadRequests=dM_grouped(:,header.columns.Handler_read_rnd_next);
    mvGrouped.dbmsNumberOfRowInsertRequests=dM_grouped(:,header.columns.Handler_write);
    mvGrouped.dbmsNumberOfFirstEntryReadRequests=dM_grouped(:,header.columns.Handler_read_first);
    mvGrouped.dbmsNumberOfKeyBasedReadRequests=dM_grouped(:,header.columns.Handler_read_key);
    mvGrouped.dbmsNumberOfNextKeyBasedReadRequests=dM_grouped(:,header.columns.Handler_read_next);
    mvGrouped.dbmsNumberOfPrevKeyBasedReadRequests=dM_grouped(:,header.columns.Handler_read_prev);
    mvGrouped.dbmsNumberOfRowReadRequests=dM_grouped(:,header.columns.Handler_read_rnd);
    
    mvGrouped.dbmsPageWritesMB=dM_grouped(:,header.columns.Innodb_pages_written).*2.*16./1024; % to account for double write buffering
    mvGrouped.dbmsDoublePageWritesMB=dM_grouped(:,header.columns.Innodb_dblwr_pages_written).*2.*16./1024; % to account for double write buffering
    mvGrouped.dbmsDoubleWritesOperations=dM_grouped(:,header.columns.Innodb_dblwr_writes);

    mvGrouped.dbmsNumberOfPendingWrites=dM_grouped(:,header.columns.Innodb_data_pending_writes);
    mvGrouped.dbmsNumberOfPendingReads=dM_grouped(:,header.columns.Innodb_data_pending_reads);
    
    mvGrouped.dbmsBufferPoolWrites = dM_grouped(:,header.columns.Innodb_buffer_pool_write_requests);
    mvGrouped.dbmsRandomReadAheads = dM_grouped(:,header.columns.Innodb_buffer_pool_read_ahead_rnd);
    mvGrouped.dbmsSequentialReadAheads = dM_grouped(:,header.columns.Innodb_buffer_pool_read_ahead_seq);
    mvGrouped.dbmsNumberOfLogicalReadRequests = dM_grouped(:,header.columns.Innodb_buffer_pool_read_requests);
    mvGrouped.dbmsNumberOfLogicalReadsFromDisk = dM_grouped(:,header.columns.Innodb_buffer_pool_reads);
    mvGrouped.dbmsNumberOfWaitsForFlush = dM_grouped(:,header.columns.Innodb_buffer_pool_wait_free);

    % stats on how many and what type of SQL statements were run
    mvGrouped.dbmsCommittedCommands=dM_grouped(:,header.columns.Com_commit);
    mvGrouped.dbmsRolledbackCommands=dM_grouped(:,header.columns.Com_rollback);
    mvGrouped.dbmsRollbackHandler=dM_grouped(:,header.columns.Handler_rollback);
    
    % latency stats
    % mvGrouped.measuredCPU=monitor_grouped(:,header.columns.mysqld_cpu)+monitor_grouped(:,header.columns.mysqld_children_cpu);
    % mvGrouped.measuredWritesMB=monitor_grouped(:,header.columns.mysqld_bytes_written) / 1024 / 1024;
    % mvGrouped.measuredReadsMB=monitor_grouped(:,header.columns.mysqld_bytes_read) / 1024 / 1024;

    lock_smoothing = 1;
    mvGrouped.dbmsCurrentLockWaits=DoSmooth(monitor_grouped(:,header.columns.Innodb_row_lock_current_waits), lock_smoothing);
    mvGrouped.dbmsLockWaits=DoSmooth(dM_grouped(:,header.columns.Innodb_row_lock_waits), lock_smoothing);
    mvGrouped.dbmsLockWaitTime=DoSmooth(dM_grouped(:,header.columns.Innodb_row_lock_time), lock_smoothing) / 1000; % to turn it into seconds!
    %mvGrouped.dbmsCurrentLockWaits=monitor_grouped(:,header.columns.Innodb_row_lock_current_waits);
    %mvGrouped.dbmsLockWaits=dM_grouped(:,header.columns.Innodb_row_lock_waits);
    %mvGrouped.dbmsLockWaitTime=dM_grouped(:,header.columns.Innodb_row_lock_time) / 1000; % to turn it into seconds!
    % if exist('OCTAVE_VERSION')
    %     save('dbmsCurrentLockWaits_Octave.mat', '-v6', '-struct', 'mvGrouped', 'dbmsCurrentLockWaits');
    %     save('dbmsLockWaits_Octave.mat', '-v6', '-struct', 'mvGrouped', 'dbmsLockWaits');
    %     save('dbmsLockWaitTime_Octave.mat', '-v6', '-struct', 'mvGrouped', 'dbmsLockWaitTime');
    % else
    %     save('dbmsCurrentLockWaits_Matlab', '-v6', '-struct', 'mvGrouped', 'dbmsCurrentLockWaits');
    %     save('dbmsLockWaits_Matlab', '-v6', '-struct', 'mvGrouped', 'dbmsLockWaits');
    %     save('dbmsLockWaitTime_Matlab', '-v6', '-struct', 'mvGrouped', 'dbmsLockWaitTime');
    % end

    mvGrouped.dbmsReadRequests = dM_grouped(:, header.columns.Innodb_buffer_pool_read_requests);
    mvGrouped.dbmsReads = dM_grouped(:, header.columns.Innodb_buffer_pool_reads);
    mvGrouped.dbmsPhysicalReadsMB = dM_grouped(:,[header.columns.Innodb_data_read])./1024./1024;

elseif strcmpi(header.dbms, 'psql')
    mvGrouped.dbmsFlushedPages = DoSmooth(dM_grouped(:, header.columns.buffers_clean)+dM_grouped(:, header.columns.buffers_backend), 10);
    %mvGrouped.dbmsFlushedPages = dM_grouped(:, header.columns.buffers_clean)+dM_grouped(:, header.columns.buffers_backend);
    mvGrouped.dbmsLogWritesMB=dM_grouped(:,header.columns.buffers_checkpoint).*8192./1024./1024; %MB
    mvGrouped.dbmsPageWritesMB=(dM_grouped(:,header.columns.buffers_clean)+dM_grouped(:,header.columns.buffers_backend)).*2.*8./1024; % to account for double write buffering
    mvGrouped.dbmsCommittedCommands=dM_grouped(:,header.columns.xact_commit);
    mvGrouped.dbmsRolledbackCommands=dM_grouped(:,header.columns.xact_rollback);
    mvGrouped.measuredCPU=monitor_grouped(:,header.columns.postgres_cpu) + monitor_grouped(:,header.columns.postgres_children_cpu);
    mvGrouped.measuredWritesMB=monitor_grouped(:,header.columns.postgres_bytes_written) / 1024 / 1024;
    mvGrouped.measuredReadsMB=monitor_grouped(:,header.columns.postgres_bytes_read) / 1024 / 1024;
    mvGrouped.dbmsReadRequests = dM_grouped(:, header.columns.blks_read) + dM_grouped(:, header.columns.blks_hit);
    mvGrouped.dbmsReads = dM_grouped(:, header.columns.blks_read);
else
    error(['Sorry, we currently do not support the ' header.dbms ' DBMS']);
end

elapsed = toc(overallTime);
fprintf(1,'load_modeling_variables time = %f\n', elapsed);

end

