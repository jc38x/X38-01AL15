%**************************************************************************
% get_distance_google.m
% function [               ...
% out_table                ...
% ] = get_distance_google( ...
%     in_origin,           ...
%     in_destination       ...
%     )
%**************************************************************************

function [               ...
out_table                ...
] = get_distance_google( ...
    in_origin,           ...
    in_destination       ...
    )

global CONFIG

maxelem = CONFIG.GOOGLEDISTMAXELEM;

preamble = 'https://maps.googleapis.com/maps/api/distancematrix/json?';
out_table = [];

for n = 1:size(in_origin, 1)
elem = 0;
burl = [preamble 'origins=' in_origin{n}];
row = [];    
for m = 1:size(in_destination, 1)
if (elem < 1), url = [burl '&' 'destinations=']; else url = [url '|']; end
url = [url in_destination{m}];
elem = elem + 1;
if (elem < maxelem), continue; end
row = [row, request_distance(url, elem)];
elem = 0;
end
if (elem > 0), row = [row, request_distance(url, elem)]; end
out_table = [out_table; row];
end
end

%--------------------------------------------------------------------------
% function [            ...
% out_row               ...
% ] = request_distance( ...
%     in_url,           ...
%     in_elem           ...
%     )
%--------------------------------------------------------------------------

function [            ...
out_row               ...
] = request_distance( ...
    in_url,           ...
    in_elem           ...
    )

global CONFIG;
global STATE

timeout  = CONFIG.HTTPTIMEOUT;
retries  = CONFIG.HTTPRETRIES;
timing   = CONFIG.GOOGLEDISTTIMING;
keyindex = STATE.DISTKEYINDEX;

keyring = apikeyring();
getdistance = true;
waitforkey = true;
unkerrtries = retries;

while (getdistance)
    key = ['key=' keyring{keyindex}];
    req = [in_url '&' key];
    attempt = retries;

    while (true)
        [outputjson, status] = urlread(req, 'Timeout', timeout);
        if (status), break; end
        attempt = attempt - 1;
        if (attempt > 0), continue; end
        error('Failed to retrieve distance from Google servers');
    end
    
    response = loadjson(outputjson);
    switch (response.status)
    case 'OK'
        getdistance = false;
        waitforkey = true;
    case 'OVER_QUERY_LIMIT'
        if (waitforkey)
            waitforkey = false;
            warning('Exceeded elements per second limit? waiting...');
            delay_counter(timing);
            continue;
        end
        keyindex = keyindex + 1;
        if (keyindex > size(keyring, 1))
            error('Google Distance Matrix Api all keys used');
        end
        warning('Google Distance Matrix Api key change');
    case 'UNKNOWN_ERROR'
        unkerrtries = unkerrtries - 1;
        if (unkerrtries > 0), continue; end
        error('Google Distance Matrix Api UNKNOWN_ERROR');
	otherwise
        error(['Google Distance Matrix Api ' response.status]);
    end
end

STATE.DISTKEYINDEX = keyindex;

szr = size(response.rows, 1);
out_row = -1 * ones(1, in_elem);
if (szr < 1), return; end

for k = 1:in_elem
    if (strcmpi(response.rows{1}.elements{k}.status, 'OK'))
        out_row(k) = response.rows{1}.elements{k}.duration.value;
    end
end
end
%**************************************************************************