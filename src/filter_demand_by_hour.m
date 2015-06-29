%**************************************************************************
% filter_demand_by_hour.m
% function [                 ...
% out_sel                    ...
% ] = filter_demand_by_hour( ...
%     in_demand,             ...
%     in_from,               ...
%     in_to                  ...
%     )
%**************************************************************************

function [                 ...
out_sel                    ...
] = filter_demand_by_hour( ...
    in_demand,             ...
    in_from,               ...
    in_to                  ...
    )

out_sel = false(size(in_demand));
f = hournum(in_from);
q = hournum(in_to);

for k = 1:size(in_demand, 1)
    try
    t = hournum(in_demand{k});
    out_sel(k) = (t >= f) && (t <= q);
    catch
    warning(['Unexpected hour format: ' in_demand{k}]);
    end
end

% Convertir string de hora a numero ---------------------------------------
function h = hournum(str)
    h = str2double(str(1:2));
    if (isnan(h)), error('HH ?'); end
    h = int32(round(h));
    if (h > 12), error('HH > 12'); end
    ap = str(10);
    if (strcmpi(ap, 'a')),     if (h >= 12), h = 0;      end
    elseif (strcmpi(ap, 'p')), if (h ~= 12), h = h + 12; end
    else error('AM/PM ?');
    end
end
end
%**************************************************************************