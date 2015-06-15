%**************************************************************************
% get_distance_osrm.m
% function [             ...
% out_table              ...
% ] = get_distance_osrm( ...
%     in_origin,         ...
%     in_destination     ...
%     )
%**************************************************************************

function [             ...
out_table              ...
] = get_distance_osrm( ...
    in_origin,         ...
    in_destination     ...
    )

global CONFIG

disthost = CONFIG.OSRMHOST;
distport = CONFIG.OSRMPORT;
maxelem  = CONFIG.OSRMDISTMAXELEM;

preamble = ['http://' disthost ':' distport '/table?'];
out_table = [];

for n = 1:size(in_origin, 1)
elem = 0;
url = [preamble 'loc=' in_origin{n}];
row = [];
for m = 1:size(in_destination, 1)
url = [url '&' 'loc=' in_destination{m}];
elem = elem + 1;
if (elem < maxelem), continue; end
row = [row, request_distance(url)];
elem = 0;
end
if (elem > 0), row = [row, request_distance(url)]; end
out_table = [out_table; row];
end
end

%--------------------------------------------------------------------------
% function [            ...
% out_row               ...
% ] = request_distance( ...
%     in_url            ...
%     )
%--------------------------------------------------------------------------

function [            ...
out_row               ...
] = request_distance( ...
    in_url            ...
    )

global CONFIG

timeout = CONFIG.HTTPTIMEOUT;
retries = CONFIG.HTTPRETRIES;
timing  = CONFIG.OSRMTIMING;

attempt = retries;
cooldown = true;

while (true)
    [outputjson, status] = urlread(in_url, 'Timeout', timeout);
    if (status), break; end
    attempt = attempt - 1;
    if (attempt > 0), continue; end
    if (cooldown)
        warning('Waiting for OSRM server...');
        delay_counter(timing);
        attempt = retries;
        cooldown = false;
        continue;
    end
	error('Failed to retrieve distance from OSRM server');
end

outputjson = [outputjson(1:strfind(outputjson, ']')) ']}'];
info = loadjson(outputjson);
out_row = round(info.distance_table(1, 2:end) ./ 10);
end
%**************************************************************************