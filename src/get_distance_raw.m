%**************************************************************************
% get_distance_raw.m
% function [            ...
% out_table             ...
% ] = get_raw_distance( ...
%     in_fromcoord,     ...
%     in_tocoord        ...
%     )
%**************************************************************************

function [            ...
out_table             ...
] = get_distance_raw( ...
    in_fromcoord,     ...
    in_tocoord        ...
    )
R    = 6371000;
szf  = size(in_fromcoord, 1);
szt  = size(in_tocoord, 1);
radf = repelem(deg2rad(in_fromcoord), szt, 1);
radt = repmat(deg2rad(in_tocoord), szf, 1);

o1 = radf(:, 1);
o2 = radt(:, 1);
do = radt(:, 1) - radf(:, 1);
dl = radt(:, 2) - radf(:, 2);
a  = (sin(do ./ 2) .^ 2) + (cos(o1) .* cos(o2) .* (sin(dl ./ 2) .^ 2));
c  = 2 .* atan2(sqrt(a), sqrt(1 - a));
d  = R .* c;

out_table = reshape(d, szt, szf).';
end
%**************************************************************************