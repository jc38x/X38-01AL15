%**************************************************************************
% lp_dsm.m
% function [     ...
% out_ok,        ...
% out_bases,     ...
% out_total      ...
% ] = lp_dsm(    ...
%     in_costos, ...
%	  in_pesos,  ...
%	  in_p,      ...
%	  in_pj,     ...
%	  in_r1,     ...
%	  in_r2,     ...
%	  in_a,      ...
%	  in_entero  ...
%	  )
%**************************************************************************

function [     ...
out_ok,        ...
out_bases,     ...
out_total      ...
] = lp_dsm(    ...
    in_costos, ...
	in_pesos,  ...
	in_p,      ...
	in_pj,     ...
	in_r1,     ...
	in_r2,     ...
	in_a,      ...
	in_entero  ...
	)
% Constantes --------------------------------------------------------------
db = size(in_costos, 1);    % numero de bases
dd = size(in_costos, 2);    % numero de puntos de demanda
c1 = in_costos <= in_r1;    % cobertura en r1
c2 = in_costos <= in_r2;    % cobertura en r2    
a  = in_a .* sum(in_pesos); % porcentaje alfa de la demanda

% Funcion objetivo: maximizar demanda cubierta 2 veces --------------------
% (1) numero de ambulancias en cada base
% (2) puntos de demanda cubiertos al menos 1 vez
% (3) puntos de demanda cubiertos 2 veces
f = [
    zeros(1, db), ... % yi  (no importa) (1)
    zeros(1, dd), ... % x1i (no importa) (2)
       -in_pesos  ... % x2i              (3)
];

% Restricciones (desigualdades) -------------------------------------------
% (1) todos los puntos de demanda estan cubiertos al menos 1 vez en r2
% (2) cubierto 1 vez con 1+ ambulancias, cubierto 2 veces con 2+
% (3) si esta cubierto 2 veces en r1 esta cubierto al menos 1 vez en r1
% (4) porcentaje alfa esta cubierto al menos 1 vez en r1
%    yi             x1i            x2i
A = [
            -c2.', zeros(dd, dd), zeros(dd, dd); % <= -1 (1)
            -c1.',   eye(dd, dd),   eye(dd, dd); % <=  0 (2)
	zeros(dd, db),  -eye(dd, dd),   eye(dd, dd); % <=  0 (3)
	zeros( 1, db),     -in_pesos, zeros( 1, dd); % <= -a (4)
];

b = [
	-1 * ones(dd, 1); % <= -1 (1)
        zeros(dd, 1); % <=  0 (2)
        zeros(dd, 1); % <=  0 (3)
                  -a; % <= -a (4)
];

% Restricciones (igualdades) ----------------------------------------------
% (1) suma de todas las ambulancias es igual al maximo de ambulancias
%      yi           x1i           x2i
Aeq = [ones(1, db), zeros(1, dd), zeros(1, dd)]; % = p (1)
beq =  in_p;                                     % = p (1)

% Cotas -------------------------------------------------------------------
% yi  : [0, pj] maximo de ambulancias permitidas por base
% x1i : [0,  1]
% x2i : [0,  1]
%     yi            x1i           x2i
lb = [zeros(1, db), zeros(1, dd), zeros(1, dd)];
ub = [       in_pj,  ones(1, dd),  ones(1, dd)];

% Aplicar LP --------------------------------------------------------------
if (in_entero) % ILP
    [
    p_grupo,   ...
    out_total, ...
    p_exit     ...
	] = intlinprog(f, 1:numel(f), A, b, Aeq, beq, lb, ub);
else          % LP
	[
	p_grupo,   ...
	out_total, ...
	p_exit     ...
	] =    linprog(f,             A, b, Aeq, beq, lb, ub);
end

% Resultados --------------------------------------------------------------
if (p_exit < 1)
    out_ok    =  false;
    out_bases =  [];
    out_total =  0;
else
    out_ok    =  true;
    out_bases =  p_grupo(1:db);
    out_total = -out_total;
end
end
%**************************************************************************