%**************************************************************************
% point_info.m
% function [      ...
% out_text        ...
% ] = point_info( ...
%     ~,          ...
%     in_eventobj ...
%     )
%**************************************************************************

function [      ...
out_text        ...
] = point_info( ...
    ~,          ...
    in_eventobj ...
    )

global PROFILESTRING

locprof    = PROFILESTRING.INFOLOCATION;
nameprof   = PROFILESTRING.INFONAME;
addrprof   = PROFILESTRING.INFOADDRESS;
totalprof  = PROFILESTRING.INFOTOTAL;
baseprof   = PROFILESTRING.INFOBASES;
demandprof = PROFILESTRING.INFODEMAND;
callsprof  = PROFILESTRING.INFOCALLS;
unknprof   = PROFILESTRING.INFOUNKNOWN;

target = get(in_eventobj, 'Target');

switch lower(get(target, 'Tag'))
case 'location'
    data = get(target, 'UserData');
    
    namestr  = [nameprof  ': ' data{2}];
    vicstr   = [addrprof  ': ' data{4}];
    totalstr = [totalprof ': ' num2str(data{7}, '%.0f')];
    
    out_text = [{locprof}; {namestr}; {vicstr}; {totalstr}];
case 'bases'
    out_text = baseprof;
case 'demand'
    out_text = demandprof;
case 'calls'
	out_text = callsprof;
otherwise
    out_text = unknprof;
end
end
%**************************************************************************