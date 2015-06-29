%**************************************************************************
% filter_demand_by_data.m
% function [                 ...
% out_sel                    ...
% ] = filter_demand_by_date( ...
%     in_demand,             ...
%     in_from,               ...
%     in_to                  ...
%     )
%**************************************************************************

function [                 ...
out_sel                    ...
] = filter_demand_by_date( ...
    in_demand,             ...
    in_from,               ...
    in_to                  ...
    )

d = 'mm/dd/yyyy';
f = datenum(in_from, d);
q = datenum(in_to, d);
out_sel = false(size(in_demand));

for k = 1:size(in_demand, 1)
    try        
    t = datenum(in_demand{k}, d);
    out_sel(k) = (t >= f) && (t <= q);
    catch
    warning(['Unexpected date format: ' in_demand{k}]);
    end
end
end
%**************************************************************************