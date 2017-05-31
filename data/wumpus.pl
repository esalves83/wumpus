%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Simulador Prolog do Jogo Mundo de Wumpus                                      %
%                                                                                  %
%    Autor: Eduardo da Silva Alves (esalves@usp.br)                                %
%    Data: 28/05/2017															   %
%                                                                                  %
%    Baseado na implementação de Nicolas Hernandez e Gwenael LE ROUX,              %
%    Université de Nantes, disponível em: 										   %
%    http://e.nicolas.hernandez.free.fr/archives/doku.php?id=misc:software:wumpus  %
%															                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTAS (FAQ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Ações do agente:
%
% 1. forward,      % movimenta agente para frente
% 2. turnright,    % virar à direita 90º / sentido horário
% 3. turnleft,     % virar à esquerda 90º / sentido anti-horário
% 4. grab,         % agarrar/pegar
% 5. shoot,        % atirar flecha
% 6. die,          % o agente morre caso esteja em uma sala que contem Wumpus ou poço
% 7. climb,        % sair da caverna quando estiver na sala [1,1]
%
% Configuração dos cenários:
%
% 1. Tamanho: 16 salas dispostas em formato de matriz 4x4
% 2. Tipo: fig62, scenario_1 or scenario_2
%
% fig62:
%   ouro: [2,3]
%   poços: [3,1], [3,3], [3,4]
%   wumpus: [1,3]
%
% scenario_1:
%   ouro: [4,3]
%   poços: [3,3], [4,4], [3,1]
%   wumpus: [3,2]
%
% scenario_2:
%   ouro: [3,3]
%   poços: [4,1], [4,2]
%   wumpus: [1,3]
%
% Consultas principais:
%   step.
%   -> executa um passo completo na base de conhecimento (percepção-inferência-ação)
%
%   make_percept_sentence(Percept).
%   -> lista com as percepções do jogodor em cada sala [Stench,Bleeze,Glitter,Bump,Scream]
%
%   tell_KB(Percept).
%   -> atualiza base de conhecimento do jogo dependendo das percepções obtidas

%   ask_KB(Action).
%   -> inferência com relação à ação a ser tomada com base no conhecimento do agente sobre o mundo e das
%      percepções obtidas no instante atual
%
%   apply(Action).
%   -> execução da ação
%
% Pontuação:
%   * Assumindo apenas 1 Wumpus e 1 baú de ouro
%   * -10000 pontos se agente morrer
%   * +1000 pontos se sair da caverna com ouro
%   * +500 pontos se conseguir sair da caverna
%   * +50 pontos se conseguir matar o Wumpus
%   * -1 ponto para cada ação realizada
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executa um passo completo
%
step :-
	agent_healthy,					% Agente está vivo
	agent_in_cave,					% Agente no interior da caverna
	
	is_nb_visited,					% Incrementa o nº de salas visitadas
	
	agent_location(L),				% Insere a sala em que está o agente
	retractall(is_visited(L)),		% como visitada na base de conhecimento do jogo
	assert(is_visited(L)),			
	
	agent_score(S),
	New_S is S - 1,					% -1 na pontuação geral
	retractall(agent_score(_)),
    assert(agent_score(New_S)),
	
	%----------------------------------
	make_percept_sentence(Percept),	% Consulta percepção do agente [Stench,Bleeze,Glitter,Bump,Scream]
	%----------------------------------
	tell_KB(Percept),				% Atualiza base de conhecimento
									% Infere possíveis posições do Wumpus e poços
	%----------------------------------
	ask_KB(Action),					% Infere ação a ser realizada
	%----------------------------------
	apply(Action),					% Executa ação inferida
	%----------------------------------
	
	time(T),						% Atualiza o nº do passo 
	New_T is T+1,
	retractall(time(_)),
	assert(time(New_T)).	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algumas declarações
%
:- dynamic([
	short_goal/1,			% objetivo atual do agente (apenas para acompanhar a execução de cada passo
	time/1,					% nº do passo
	nb_visited/1,			% marca nº de salas visitadas
	score_climb_with_gold/1,% guardar pontuação sair da caverna com ouro
	score_grab/1,			% guardar pontuação para sair da caverna sem o ouro
	score_wumpus_dead/1,	% guardar pontuação caso mate o Wumpus
	score_agent_dead/1,		% guardar pontuação em caso do agente morrer
	land_extent/1,			% tamanho máximo do tabuleiro
	wumpus_location/1,		% posição [x,y] do Wumpus
	wumpus_healthy/0,		% Wumpus vivo/morto
	gold_location/1,		% posição [x,y] do ouro
	pit_location/1,			% posições [x,y] dos poços
	agent_location/1,		% posição [x,y] do agente
	agent_orientation/1,	% orientação (leste,oeste,norte,sul) do agente
	agent_healthy/0,		% agente vivo/morto
	agent_hold/0,			% agente pegou o ouro
	agent_arrows/1,			% nº de flechas disponíveis
	agent_goal/1,			% objetivo do agente
	agent_score/1,			% pontuação total do agente
	agent_in_cave/0,		% agente na caverna	
	is_wumpus/2,			% conhecimento do agente sobre a posição do Wumpus
	is_pit/2,				% conhecimento do agente sobre a posição dos poços
	is_gold/1,				% conhecimento do agente sobre a posição do ouro
	is_wall/1,				% conhecimento do agente sobre a posição das paredes
	is_dead/0,				% conhecimento do agente sobre a saúde do Wumpus
	is_visited/1]).			% conhecimento do agente sobre quais salas foram visitadas

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Criação dos mapas
%	
initialize_land(fig62):-
	retractall(land_extent(_)),	
	retractall(wumpus_location(_)),
	retractall(wumpus_healthy),
	retractall(gold_location(_)),
	retractall(pit_location(_)),
	assert(land_extent(5)),
	assert(wumpus_location([1,3])),
	assert(wumpus_healthy),
	assert(gold_location([2,3])),
	assert(pit_location([3,1])),
	assert(pit_location([3,3])),
	assert(pit_location([4,4])).
	
initialize_land(scenario_1):-
	retractall(land_extent(_)),	
	retractall(wumpus_location(_)),
	retractall(wumpus_healthy),
	retractall(gold_location(_)),
	retractall(pit_location(_)),
	assert(land_extent(5)),
	assert(wumpus_location([3,2])),
	assert(wumpus_healthy),
	assert(gold_location([4,3])),
	assert(pit_location([3,3])),
	assert(pit_location([4,4])),
	assert(pit_location([3,1])).
	
initialize_land(scenario_2):-
	retractall(land_extent(_)),	
	retractall(wumpus_location(_)),
	retractall(wumpus_healthy),
	retractall(gold_location(_)),
	retractall(pit_location(_)),
	assert(land_extent(5)),
	assert(wumpus_location([1,3])),
	assert(wumpus_healthy),
	assert(gold_location([3,3])),
	assert(pit_location([4,1])),
	assert(pit_location([4,2])).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inicialização do agente
%
initialize_agent(fig62):-	
	retractall(agent_location(_)),
	retractall(agent_orientation(_)),
	retractall(agent_healthy),
	retractall(agent_hold),
	retractall(agent_arrows(_)),
	retractall(agent_goal(_)),
	retractall(agent_score(_)),
	retractall(is_wumpus(_,_)),
	retractall(is_pit(_,_)),
	retractall(is_gold(_)),
	retractall(is_wall(_)),
	retractall(is_dead),
	retractall(is_visited(_)),
	assert(agent_location([1,1])),
	assert(agent_orientation(0)),
	assert(agent_healthy),
	assert(agent_arrows(1)),
	assert(agent_goal(find_out)),
	assert(agent_score(0)),	
	assert(agent_in_cave).
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inicialização do jogo
%
initialize_general :-
	initialize_land(scenario_1),					% Cenário que será utilizado
	initialize_agent(fig62),
	retractall(time(_)),
	assert(time(0)),
	retractall(nb_visited(_)),
	assert(nb_visited(0)),
	retractall(score_agent_dead(_)),
	assert(score_agent_dead(10000)),
	retractall(score_climb_with_gold(_)),
	assert(score_climb_with_gold(1000)),
	retractall(score_grab(_)),
	assert(score_grab(500)),
	retractall(score_wumpus_dead(_)),
	assert(score_wumpus_dead(50)),
	retractall(is_situation(_,_,_,_,_)),
	retractall(short_goal(_)).

degree(east) :- agent_orientation(0).
degree(north) :- agent_orientation(90).
degree(west) :- agent_orientation(180).
degree(south) :- agent_orientation(270).	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Percepções
%
make_percept_sentence([Stench,Bleeze,Glitter,Bump,Scream]) :-
	stenchy(Stench),
	bleezy(Bleeze),
	glittering(Glitter),
	bumped(Bump),
	heardscream(Scream).

stenchy(yes) :-
	wumpus_location(L1),
	agent_location(L2),
	adjacent(L1,L2),
	!.
stenchy(no).

bleezy(yes) :- 
	pit_location(L1),
	agent_location(L2), 
	adjacent(L1,L2),
	!.
bleezy(no).

glittering(yes) :-
	agent_location(L),
	gold_location(L),
	!.
glittering(no).

bumped(yes) :-			% Agente percebe uma parede quando bater
	agent_location(L),
	wall(L),
	!.
bumped(no).

heardscream(yes) :-
	no(wumpus_healthy), 
	!.
heardscream(no).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Informa a base de conhecimento do agente sobre as informações do mundo
%
tell_KB([_,_,_,yes,_]) :- 
	add_wall_KB(yes),!.

tell_KB([Stench,Bleeze,Glitter,_,Scream]) :-
	add_wumpus_KB(Stench),
	add_pit_KB(Bleeze),
	add_gold_KB(Glitter),
	add_scream_KB(Scream).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atualiza o conhecimento do agente sobre a localização do Wumpus
%
add_wumpus_KB(no) :-
	agent_location(L1),
	assume_wumpus(no,L1), 		% Na posição atual do agente não existe Wumpus
	location_toward(L1,0,L2),	% Nas posições adjacentes...
	assume_wumpus(no,L2),		% também não há
	location_toward(L1,90,L3),	
	assume_wumpus(no,L3),
	location_toward(L1,180,L4),	
	assume_wumpus(no,L4),
	location_toward(L1,270,L5),	
	assume_wumpus(no,L5),
	!.
add_wumpus_KB(yes) :-	
	agent_location(L1),			% Agente não tem certeza sobre a posição do Wumpus
	location_toward(L1,0,L2),	% É possível que exista Wumpus em qualquer sala adjacente
	assume_wumpus(yes,L2),		
	location_toward(L1,90,L3),	
	assume_wumpus(yes,L3),
	location_toward(L1,180,L4),	
	assume_wumpus(yes,L4),
	location_toward(L1,270,L5),	
	assume_wumpus(yes,L5).
	
assume_wumpus(no,L) :-
	retractall(is_wumpus(_,L)),
	assert(is_wumpus(no,L)),
	!.
	
assume_wumpus(yes,L) :- 		% Antes não existia Wumpus nesta posição,
	is_wumpus(no,L),			% então Wumpus não pode estar aqui agora ...
	!.							% ... Exceto se ele puder se mover 
	
assume_wumpus(yes,L) :- 		
	wall(L),					% Wumpus não pode estar em uma parede			
	retractall(is_wumpus(_,L)),
	assert(is_wumpus(no,L)),
	!.
	
assume_wumpus(yes,L) :- 
	wumpus_healthy,				% então...
	retractall(is_wumpus(_,L)),
	assert(is_wumpus(yes,L)),	% ... insere na base possível posição do Wumpus
	!.
	
assume_wumpus(yes,L) :-
	retractall(is_wumpus(_,L)),
	assert(is_wumpus(no,L)).	% caso Wumpus esteja morto	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atualiza o conhecimento do agente sobre a localização dos poços
%	
add_pit_KB(no) :-
	agent_location(L1),
	assume_pit(no,L1), 			% Agente não está em um poço 
	location_toward(L1,0,L2),	% E não existe poço em nenhuma sala adjacente
	assume_pit(no,L2), 		
	location_toward(L1,90,L3),	
	assume_pit(no,L3),
	location_toward(L1,180,L4),	
	assume_pit(no,L4),
	location_toward(L1,270,L5),	
	assume_pit(no,L5),
	!.
add_pit_KB(yes) :-	
	agent_location(L1),			% Não há certeza sobre a localização dos poços
	location_toward(L1,0,L2),	% É possível existir um poço
	assume_pit(yes,L2),		    % em cada sala adjacente
	location_toward(L1,90,L3),	
	assume_pit(yes,L3),
	location_toward(L1,180,L4),	
	assume_pit(yes,L4),
	location_toward(L1,270,L5),	
	assume_pit(yes,L5).
	
assume_pit(no,L) :-
	retractall(is_pit(_,L)),
	assert(is_pit(no,L)),
	!.
	
assume_pit(yes,L) :- 			% Antes não havia poço nesta sala
	is_pit(no,L),				% então não pode existir agora
	!.
	
assume_pit(yes,L) :- 
	wall(L),					% Não há poços nas paredes
	retractall(is_pit(_,L)),
	assert(is_pit(no,L)),
	!.
	
assume_pit(yes,L) :- 
	retractall(is_pit(_,L)),
	assert(is_pit(yes,L)).	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atualiza o conhecimento do agente sobre a localização do ouro
%
add_gold_KB(yes) :-
	agent_location(L),
	retractall(is_gold(L)),
	assert(is_gold(L)),
	!.
add_gold_KB(no).		

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atualiza o conhecimento do agente sobre a localização das paredes
%
add_wall_KB(yes) :-			% aqui há uma parede
	agent_location(L),		% porque acabo de bater nela ...	
	retractall(is_wall(L)),	
	assert(is_wall(L)),
	!.					
add_wall_KB(no).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atualiza o conhecimento do agente sobre a saúde do Wumpus
%		
add_scream_KB(yes) :-
	retractall(is_dead),
	assert(is_dead),
	!.
add_scream_KB(no).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Infere da base de conhecimento a ação a ser executada
%
ask_KB(Action) :- make_action_query(_,Action).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prioridade das estratégias utilizadas
% 1. Agente reativo (retorna casa bata na parede, morrer, atirar, pegar e sair da caverna)
% 2. Procurar ouro (preferência por lugares seguros que ainda não foram visitados)
% 3. Matar Wumpus (caso não haja mais lugares seguros)
% 4. Sair da caverna (caso encontre ouro o não esteja motivado)
%
make_action_query(_,Action) :- act(strategy_reflex,Action),!.
make_action_query(_,Action) :- act(strategy_find_out,Action),!.
make_action_query(_,Action) :- act(strategy_kill_wumpus,Action),!.
make_action_query(_,Action) :- act(strategy_find_out_hurry,Action),!.
make_action_query(_,Action) :- act(strategy_go_out,Action),!.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: agente reativo
%
act(strategy_reflex,rebound) :-		% retorna para a última posição
	agent_location(L),
	is_wall(L),
	is_short_goal(rebound),!.
	
act(strategy_reflex,die) :- 		% morre se estiver na posição que contem Wumpus
	agent_healthy,
	wumpus_healthy,
	agent_location(L),
	wumpus_location(L),
	is_short_goal(die_wumpus),
	!.
	
act(strategy_reflex,die) :- 		% morre se estiver na posição que contem poço
	agent_healthy,
	agent_location(L),
	pit_location(L),
	is_short_goal(die_pit),
	!.

act(strategy_reflex,shoot) :-		% Atirar no Wumpus se o agente achar  
	agent_arrows(1),				% que ele está na mesma coluna...
	agent_location([X,Y]),			% e se o agente estiver de frente para o Wumpus...
	location_ahead([X,NY]),			% ele atira!
	is_wumpus(yes,[X,WY]),		
	dist(NY,WY,R1),					
	dist(Y,WY,R2),					
	inf_equal(R1,R2),				
	is_short_goal(shoot_forward_in_the_same_X),
	!.
	
act(strategy_reflex,shoot) :-		% Idem para o caso em que o agente e o Wumpus  
	agent_arrows(1),				% estão na mesma linha
	agent_location([X,Y]),
	location_ahead([NX,Y]),
	is_wumpus(yes,[WX,Y]),
	dist(NX,WX,R1),			
	dist(X,WX,R2),
	inf_equal(R1,R2),
	is_short_goal(shoot_forward_in_the_same_Y),
	!.	
	
act(strategy_reflex,grab) :-		% Agente agarra o ouro se estiver na mesma sala que o baú
	agent_location(L),		
	is_gold(L),			
	is_short_goal(grab_gold),	
	!.
	
act(strategy_reflex,climb) :-		% Agente sai da caverna com o ouro
	agent_location([1,1]),	
	agent_hold,		
	is_short_goal(nothing_more),	
	!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: procurar o ouro
% Busca primeiro posições seguras que não foram visitadas em alguma sala adjacente	
%
act(strategy_find_out,forward) :-			
	agent_goal(find_out),
	agent_courage,
	good(_),						% Existe uma sala segura não visitada...
	location_ahead(L),				% esta sala está em frente ao agente
	good(L),			
	no(is_wall(L)),
	is_short_goal(find_out_forward_good_good),
	!.
	
act(strategy_find_out,turnright) :-
	agent_goal(find_out),
	agent_courage,
	good(_),						% Existe uma sala segura não visitada
	agent_orientation(O),			% esta sala está à direita do agente	
	Planned_O is abs(O-90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	good(Planned_L),
	no(is_wall(Planned_L)),
	is_short_goal(find_out_turnright_good_good),
	!.
	
act(strategy_find_out,turnleft) :-			
	agent_goal(find_out),
	agent_courage,
	good(_),						% Existe uma sala segura não visitada
	agent_orientation(O),			% esta sala está à esquerda do agente
	Planned_O is (O+90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	good(Planned_L),
	no(is_wall(Planned_L)),
	is_short_goal(find_out_turnleft_good_good),
	!.	
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: procurar o ouro
% Ainda existem salas seguras, mas não estão adjacentes ao agente	
%	
act(strategy_find_out,forward) :- 			
	agent_goal(find_out),
	agent_courage,		
	good(_),						% Existe uma sala segura em algum lugar	
	location_ahead(L),				% procura esta sala movendo-se para frente
	medium(L),						% se a sala à frente já foi visitada
	no(is_wall(L)),
	is_short_goal(find_out_forward_good_medium),
	!.
	
act(strategy_find_out,turnright) :- 		
	agent_goal(find_out),
	agent_courage,
	good(_),						% Existe uma sala segura em algum lugar
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360, % Procura esta sala virando-se para a direita
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),				% se a sala à direita já foi visitada 
	no(is_wall(Planned_L)),
	is_short_goal(find_out_turnright_good_medium),
	!.
	
act(strategy_find_out,turnleft) :- 	
	agent_goal(find_out),
	agent_courage,		
	good(_),						% Existe uma sala segura em algum lugar
	agent_orientation(O),
	Planned_O is (O+90) mod 360,	% Procura esta sala virando-se para a esquerda
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),				% se a sala à esquerda já foi visitada
	no(is_wall(Planned_L)),
	is_short_goal(find_out_turnleft_good_medium),
	!.
	
act(strategy_find_out,turnleft) :-	% Não há salas visitadas ao redor do agente  
	agent_goal(find_out),			% Agente volta por onde ele veio
	agent_courage,
	good(_),						% enquanto existir sala segura em algum lugar
	is_short_goal(find_out_180_good_),!.	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: matar o Wumpus
% O agente ainda está motivado, mas não existem mais salas seguras
% ... então agente começa a procurar Wumpus para matá-lo	
%	
act(strategy_kill_wumpus,turnleft) :-	% O agente vira à esquerda se...
	wumpus_healthy,						% Wumpus está vivo
	agent_courage,						% Agente motivado
	agent_arrows(1),					% Agente tem flechas
	agent_location(L),
	agent_orientation(O),
	Planned_O is (O+90) mod 360,
	location_toward(L,Planned_O,Planned_L),
	is_wumpus(yes,Planned_L),			% Agente acha que existe Wumpus à sua esquerda
	is_short_goal(kill_wumpus).
	
act(strategy_kill_wumpus,turnright) :-	% O agente vira à esquerda se...
	wumpus_healthy,						% Wumpus está vivo
	agent_courage,						% Agente motivado
	agent_arrows(1),					% Agente tem flechas
	agent_location(L),
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360,
	location_toward(L,Planned_O,Planned_L),
	is_wumpus(yes,Planned_L),			% Agente acha que existe Wumpus à sua esquerda
	is_short_goal(kill_wumpus).
	
act(strategy_kill_wumpus,forward) :-	% Agente dá um passo a frente se...
	wumpus_healthy,						% Wumpus está vivo
	agent_courage,						% Agente motivado
	agent_arrows(1),					% Agente tem flechas
	location_ahead(L),					
	medium(L),							% A sala da frente é um lugar visitado
	no(is_wall(L)),						% A sala da frente não é parede
	is_short_goal(kill_wumpus),
	!.
	
act(strategy_kill_wumpus,turnright) :-	% Agente vira à direita sob as mesmas condições anteriores
	wumpus_healthy,
	agent_courage,
	agent_arrows(1),
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360,	
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),		
	no(is_wall(Planned_L)),
	is_short_goal(kill_wumpus),
	!.
	
act(strategy_kill_wumpus,turnleft) :-	% Agente vira à esquerda sob as mesmas condições anteriores
	wumpus_healthy,
	agent_courage,
	agent_arrows(1),
	agent_orientation(O),
	Planned_O is (O+90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),
	no(is_wall(Planned_L)),
	is_short_goal(kill_wumpus),
	!.
	
act(strategy_kill_wumpus,turnleft) :-	% Agente da meia-volta
	wumpus_healthy,
	agent_courage,
	agent_arrows(1),
	medium(_),
	is_short_goal(kill_wumpus),
	!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: procurar o ouro arriscadamente
% O agente ainda está motivado, já matou wumpus e não encontrou o ouro
% ... então agente começa a procurar o ouro novamente	
%
act(strategy_find_out_hurry,forward) :-	% I don't know any more good room
	no(wumpus_healthy),
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),	 	% Now I'm not interested anymore by
	agent_courage, 	
	location_ahead(L),		% looking for a risky room better 
	risky(L),			% than a deadly room, .
	no(is_wall(L)),			% Can't be a wall !!!
	is_short_goal(hurry),
	!.
	
act(strategy_find_out_hurry,turnright) :-
	no(wumpus_healthy),
	agent_courage,
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360,	
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	risky(Planned_L),
	no(is_wall(Planned_L)),		% Can't be a wall !!!
	is_short_goal(hurry).
	
act(strategy_find_out_hurry,turnleft) :-
	no(wumpus_healthy),
	agent_courage,		
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),		% so I test by following priority :
	agent_orientation(O),		% risky(forward), risky(turnleft),
	Planned_O is (O+90) mod 360,	% risky(turnright), deadly(forward)
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	risky(Planned_L),
	no(is_wall(Planned_L)),		% Can't be a wall !!!
	is_short_goal(hurry),
	!.
	
% Second the deadly room
act(strategy_find_out_hurry,forward) :-
	no(wumpus_healthy),
	agent_courage,			
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),		
	location_ahead(L),		
	deadly(L),
	no(is_wall(L)),			% Can't be a wall !!!
	is_short_goal(hurry),
	!.	
	

act(strategy_find_out_hurry,turn_right) :-
	no(wumpus_healthy),
	agent_courage,		
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	no(is_wall(Planned_L)),		% Can't be a wall !!!	
	deadly(Planned_L),
	is_short_goal(hurry),!.
	
act(strategy_find_out_hurry,turn_left) :-
	no(wumpus_healthy),
	agent_courage,			
	no(agent_goal(go_out)), 
	%no(agent_goal(find_out)),
	agent_orientation(O),
	Planned_O is (O+90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	deadly(Planned_L),
	no(is_wall(Planned_L)),		% Can't be a wall !!!	
	is_short_goal(hurry),
	!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estratégia: sair da caverna
% O agente não está motivado ou já encontrou o ouro
%
act(strategy_go_out,climb) :-	% Agente sai da caverna se...
	agent_location([1,1]),		% estiver na posição [1,1]
	is_short_goal(go_out___climb),
	!.	
	
act(strategy_go_out,forward) :-	% Agente dá um passo a frente se...
	location_ahead(L),
	medium(L),					% a sala a frente já foi visitada
	no(is_wall(L)),				% e não é uma parede
	is_short_goal(go_out_forward__medium),
	!.

act(strategy_go_out,turnleft) :-	% Agente vira à esquerda se...
	agent_orientation(O),
	Planned_O is (O+90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),				% a sala a esquerda já foi visitada
	no(is_wall(Planned_L)),			% e não é uma parede
	is_short_goal(go_out_turnleft__medium),
	!.
	
act(strategy_go_out,turnright) :-	% Agente vira à direita se...
	agent_orientation(O),
	Planned_O is abs(O-90) mod 360,
	agent_location(L),
	location_toward(L,Planned_O,Planned_L),
	medium(Planned_L),				% a sala a direita já foi visitada
	no(is_wall(Planned_L)),			% e não é uma parede
	is_short_goal(go_out_turnright__medium),
	!.
			
act(strategy_go_out,turnleft) :-	% Agente volta pelo lugar de onde veio  
	is_short_goal(go_out_180__).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executar as ações decididas
%
apply(rebound) :-
	agent_location(L),
	agent_orientation(O),		
	Back_O is (O+180) mod 360,
	location_toward(L,Back_O,L2),
	retractall(agent_location(_)),
	assert(agent_location(L2)).		% voltar à ultima posição
	
apply(die) :-						% agente morre
	agent_location(L1),				% se estiver na mesma posição do Wumpus
	wumpus_location(L1),			
	retractall(is_wumpus(yes,_)),	
	assert(is_wumpus(yes,_)),		
	agent_score(S),					% atualiza pontuação: -10000 pontos
	score_agent_dead(SAD),
	New_S is S - SAD,
	assert(agent_score(New_S)),
	retractall(agent_healthy),
	!.
		
apply(die) :-						% agente morre
	agent_location(L1),
	pit_location(L1),				% se estiver na mesma posição do Wumpus
	retractall(is_pit(_,L)),
	assert(is_pit(yes,L)),
	agent_score(S),					% atualiza pontuação: -10000 pontos
	score_agent_dead(SAD),
	New_S is S - SAD,
	assert(agent_score(New_S)),
	retractall(agent_healthy),
	!.

apply(shoot) :-						% Antes, verificar se o Wumpus morreu (mesma coluna)
	agent_location([X,Y]),
	location_ahead([X,NY]),		
	wumpus_location([X,WY]),		% Wumpus realmente está em frente ao agente
	dist(NY,WY,R1),
	dist(Y,WY,R2),
	inf_equal(R1,R2),
	
	retractall(wumpus_location(_)),
	retractall(wumpus_healthy),
	retractall(agent_arrows(_)),
	assert(agent_arrows(0)),
	
	is_wumpus(yes,WL),
	assert(is_wumpus(no,WL)),
	retractall(is_wumpus(yes,_)),
	assert(is_dead),
	
	agent_score(S),					% Atualiza pontuação: +50 pontos	
	score_wumpus_dead(SWD),
	New_S is S + SWD,
	retractall(agent_score(S)),
	assert(agent_score(New_S)),
	!.
	
apply(shoot) :-						% Idem ao de cima (mesma linha)
	agent_location([X,Y]),
	location_ahead([NX,Y]),	
	wumpus_location([WX,Y]),
	dist(NX,WX,R1),
	dist(X,WX,R2),
	inf_equal(R1,R2),
	
	retractall(wumpus_location(_)),
	retractall(wumpus_healthy),
	retractall(agent_arrows(_)),
	assert(agent_arrows(0)),
	
	is_wumpus(yes,WL),
	assert(is_wumpus(no,WL)),
	retractall(is_wumpus(yes,_)),
	assert(is_dead),
	
	agent_score(S),	
	score_wumpus_dead(SWD),
	New_S is S + SWD,
	retractall(agent_score(S)),
	assert(agent_score(New_S)),
	!.
	
apply(shoot) :-						% Agente errou o tiro! (mesma coluna)
	retractall(agent_arrows(_)),	
	assert(agent_arrows(0)),		% Agente gastou a flecha
	agent_location([X,_]),			% Atualiza a base de conhecimento sobre a posição do Wumpus
	location_ahead([X,_]),
	is_wumpus(yes,[X,WY]),
	retractall(is_wumpus(yes,[X,WY])),	
	assert(is_wumpus(no,[X,WY])),	% ...Wumpus não está na sala inferida
	!.
	
apply(shoot) :-						% Agente errou o tiro (mesma linha)
	retractall(agent_arrows(_)),	 
	assert(agent_arrows(0)),	
	agent_orientation(_),		
	agent_location([_,Y]),
	location_ahead([_,Y]),
	is_wumpus(yes,[WX,Y]),
	retractall(is_wumpus(yes,[WX,Y])),	
	assert(is_wumpus(no,[WX,Y])),
	!.			
			
apply(climb) :-					% Agente saiu da caverna... 
	agent_hold,					% Conseguiu pegar o ouro
	agent_score(S),	
	score_climb_with_gold(SC),
	New_S is S + SC,			% Atualiza pontuação: +1000 pontos
	retractall(agent_score(S)),
	assert(agent_score(New_S)),
	retractall(agent_in_cave),
	!.
	
apply(climb) :-					% Agente saiu da caverna sem pegar o ouro
	retractall(agent_in_cave),
	!.	
	
apply(grab) :-						% Agente pegou o ouro
	agent_score(S),					% Atualiza pontuação: +50 pontos
	score_grab(SG),
	New_S is S + SG,
	retractall(agent_score(S)),
	assert(agent_score(New_S)),
	retractall(gold_location(_)),	% não existe mais ouro nesta sala
	retractall(is_gold(_)),
	assert(agent_hold),				% ouro está com o agente 
	retractall(agent_goal(_)),
	assert(agent_goal(go_out)),		% muda estratégia: sair da caverna
	!.				
	
apply(forward) :-					% mover agente para frente
	agent_orientation(O),
	agent_location(L),
	location_toward(L,O,New_L),
	retractall(agent_location(_)),
	assert(agent_location(New_L)),
	!.
	
apply(turnleft) :-					% virar 90º à esquerda
	agent_orientation(O),
	New_O is (O + 90) mod 360,
	retractall(agent_orientation(_)),
	assert(agent_orientation(New_O)),
	!.
	
apply(turnright) :-					% virar 90º à direita
	agent_orientation(O),
	New_O is abs(O - 90) mod 360,
	retractall(agent_orientation(_)),
	assert(agent_orientation(New_O)),
	!.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algumas definições auxiliares
%
no(P) :- 
	P,
	!,
	fail. 
no(_).

location_toward([X,Y],0,[New_X,Y]) :- New_X is X+1.
location_toward([X,Y],90,[X,New_Y]) :- New_Y is Y+1.
location_toward([X,Y],180,[New_X,Y]) :- New_X is X-1.
location_toward([X,Y],270,[X,New_Y]) :- New_Y is Y-1.

adjacent(L1,L2) :- location_toward(L1,_,L2).

location_ahead(Ahead) :-
	agent_location(L),
	agent_orientation(O),
	location_toward(L,O,Ahead).
	
inf_equal(X,Y) :- X < Y,!.
inf_equal(X,Y) :- X = Y.

dist(X,Y,R) :- 
	inf_equal(X,Y),	
	R is Y - X,
	!.
dist(X,Y,R) :- R is X - Y.

wall([_,LE]) :- inf_equal(LE,0).		% there is wall
wall([LE,_]) :- inf_equal(LE,0).		% there is wall
wall([X,_]) :- land_extent(LE), inf_equal(LE,X).% there is wall
wall([_,Y]) :- land_extent(LE), inf_equal(LE,Y).% there is wall

action(forward).
action(turnleft).
action(turnright).
action(grab).
action(climb).
action(shoot).
action(die).

is_short_goal(X) :-
	retractall(short_goal(_)),
	assert(short_goal(X)).

is_nb_visited :-
	nb_visited(N),
	agent_location(L),
	no(is_visited(L)),
	retractall(nb_visited(_)),
	New_nb_visited is N + 1,
	assert(nb_visited(New_nb_visited)),
	!.
	
is_nb_visited.
	
agent_courage :-		% mede a motivação do agente
	time(T),			% time 	
	nb_visited(_),		% nº de salas visitadas
	land_extent(LE),	% tamanho máximo do tabuleiro
	E is LE * LE,  		% nº máximo de salas a visitar
	NPLUSE is E * 5,	% agente pode realizar até 250 passos até ficar desmotivado
% 	NPLUSE is E * 2 + N,	
	inf_equal(T,NPLUSE).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% O risco de cada posição é calculado de acordo com: good, medium, risky, deadly
%
good(L) :-				% uma parede é considerada como posição segura
	is_wumpus(no,L),
	is_pit(no,L),
	no(is_visited(L)).
	
medium(L) :- 			% posição já visitada
	is_visited(L).		% is_wumpus(no,L) and is_pit(no,L)			
					
risky(L) :- 
	no(deadly(L)).
		
deadly(L) :-
	is_wumpus(yes,L),
	is_pit(yes,L),
	no(is_visited(L)).