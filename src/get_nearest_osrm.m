%**************************************************************************
% get_nearest_osrm.m
% function [            ...
% out_near              ...
% ] = get_nearest_osrm( ...
%     in_coord          ...
%     )
%**************************************************************************

function [            ...
out_near              ...
] = get_nearest_osrm( ...
    in_coord          ...
    )

global CONFIG

fmt     = CONFIG.LATLONFMT;
host    = CONFIG.OSRMHOST;
port    = CONFIG.OSRMPORT;
timeout = CONFIG.HTTPTIMEOUT;
retries = CONFIG.HTTPRETRIES;

N = size(in_coord, 1);
urlbase = ['http://' host ':' port '/nearest?loc='];
out_near = cell(N, 1);

for n = 1:N
lat = num2str(in_coord(n, 1), fmt);
lon = num2str(in_coord(n, 2), fmt);
url = [urlbase lat ',' lon];
attempt = retries;

while (true)
    [outputjson, status] = urlread(url, 'Timeout', timeout);
    if (status), break; end
    attempt = attempt - 1;
    if (attempt > 0), continue; end
	error('Failed to retrieve distance from OSRM server');
end      
  
response = loadjson(outputjson);
out_near(n) = {response.name};
end
end
%**************************************************************************