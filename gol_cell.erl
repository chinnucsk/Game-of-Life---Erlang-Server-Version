-module(gol_cell).

-compile(export_all).

%% cell stuff

cell(Row, Col, State, Neighbours) ->
    {row, Row, col, Col, state, State, neighbours, Neighbours}.

row({row, Row, col, _, state, _, neighbours, _}) ->
    Row.

col({row, _, col, Col, state, _, neighbours, _}) ->
    Col.

state({row, _, col, _, state, State, neighbours, _}) ->
    State.

neighbours({row, _, col, _, state, _, neighbours, Neighbours}) ->
    Neighbours.

new_state(living, LivingNeighbours) when LivingNeighbours < 2 ->
    dead;
new_state(living, LivingNeighbours) when LivingNeighbours > 3 ->
    dead;
new_state(living, _)  ->
    living;
new_state(dead, 3) ->
    living;
new_state(_, _) ->
    dead.

update_state({row, Row, col, Col, state, State, neighbours, Neighbours}, LivingNeighbours) ->
    gol_cell:cell(Row, Col, gol_cell:new_state(State, LivingNeighbours), Neighbours).

init_loop(Row, Col, State) ->
    receive
        {set_neighbours, Neighbours} ->
            gol_cell:loop(cell(Row, Col, State, Neighbours), none)
    end.



loop(Cell, Game) ->
    receive
        {From, prepare} ->
            From ! {self(), prepare_done },
            gol_cell:wait_update(Cell, Game, 0, length(neighbours(Cell)));
        {From, get_state} ->
            From ! {row(Cell), col(Cell), state(Cell)},
            gol_cell:loop(Cell, Game);
        {_, exit} ->
            io:format("~p:~p got exit~n", [gol_cell:row(Cell), gol_cell:col(Cell)]);
        Any ->
            io:format("~p:~p got : ~p~n", [gol_cell:row(Cell), gol_cell:col(Cell), Any]),
            gol_cell:loop(Cell, Game)
    end.


wait_update(Cell, Game, LiveCounter, TotalCounter) ->
    if 
        TotalCounter == 0 ->
            Game ! {self(), cell_done};
        true  -> false
    end,
    receive
        {From, tick} ->
            [C ! {state, state(Cell)} || C <- neighbours(Cell)],
            gol_cell:wait_update(Cell, From, LiveCounter, TotalCounter);
        {state, living } ->
            gol_cell:wait_update(Cell, Game, LiveCounter + 1, TotalCounter - 1); 
        {state, dead} ->
            gol_cell:wait_update(Cell, Game, LiveCounter, TotalCounter - 1);
        {From, update} ->
            NewCell = gol_cell:update_state(Cell, LiveCounter),
            From ! {self(), update_done},
            gol_cell:loop(NewCell, From);
        Any  ->
            io:format("~p:~p update got : ~p~n", [gol_cell:row(Cell), gol_cell:col(Cell), Any])
    end.


%% loop(Cell, Game, LiveCounter, 0, _) ->
%%     NewCell = update_state(Cell, LiveCounter),
%%     Game ! {self(), done},    
%%     gol_cell:loop(NewCell, Game, LiveCounter, length(neighbours(Cell)), 0);

%% loop(Cell, Game, LiveCounter, TotalCounter, IsTicking) ->
%%     receive
%%         {From, tick} ->
%%             [C ! {state, state(Cell)} || C <- neighbours(Cell)],
%%             gol_cell:loop(Cell, From, 0, length(neighbours(Cell)), 1);
%%         {From, get_state} ->
%%             From ! {row(Cell), col(Cell), state(Cell)},
%%             gol_cell:loop(Cell, Game, LiveCounter, TotalCounter, IsTicking);
%%         {_, exit} ->
%%             io:format("~p:~p got exit~n", [gol_cell:row(Cell), gol_cell:col(Cell)]);
%%         {state, _ } when IsTicking == 0 ->
%%             io:format("~p:~p got tick at wrong time~n", [gol_cell:row(Cell), gol_cell:col(Cell)]),
%%             gol_cell:loop(Cell, Game, LiveCounter, TotalCounter, IsTicking);
%%         {state, living } ->
%%             gol_cell:loop(Cell, Game, LiveCounter + 1, TotalCounter - 1, IsTicking); 
%%         {state, dead} ->
%%             gol_cell:loop(Cell, Game, LiveCounter, TotalCounter - 1, IsTicking);

%%         Any ->
%%             io:format("~p:~p got : ~p~n", [gol_cell:row(Cell), gol_cell:col(Cell), Any]),
%%             gol_cell:loop(Cell, Game, LiveCounter, TotalCounter, IsTicking)
%%     end.


%% wait_update(Cell, Game, LiveCounter, 0) ->
%%     NewCell = update_state(Cell, LiveCounter),
%%     Game ! {self(), done},
%%     gol_cell:loop(NewCell, Game);

%% wait_update(Cell, Game, LiveCounter, TotalCounter) ->
%%     receive
%%         {state, living } ->
%%             gol_cell:wait_update(Cell, Game, LiveCounter + 1, TotalCounter - 1); 
%%         {state, dead} ->
%%             gol_cell:wait_update(Cell, Game, LiveCounter, TotalCounter - 1);
%%         Any  ->
%%             io:format("got: ~p~n", [Any]),
%%             io:format("~p:~p update got : ~p~n", [gol_cell:row(Cell), gol_cell:col(Cell), Any])
%%     end.
