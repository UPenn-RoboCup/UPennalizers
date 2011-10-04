module(..., package.seeall);

require('util');

--[[-------
  Lua finite state machine implementation
  Usage:
  sm = fsm.new({state1, state2, state3, ...});
  sm:set_transition(state1, event, state2, action);
  sm:add_state(state);
  sm:add_event(event);

  sm:entry();
  sm:update();
  sm:exit();

  states are tables with member functions:
  state.entry(), event = state.update(), state.exit(event) 

  events are strings: "timeout", "done", etc.
  actions are optional functions to be called

  jordan:
  added
  statesNames - mapping state index to string name
  statesHash - mapping state string name to state index
  sm:set_state(state_string); -- sets the state by the string name
--]]-------

mt = getfenv();
mt.__index = mt;

function new(state1, ...)
  if (type(state1) ~= "table") then
    error("no initial state");
  end

  local o = {};
  o.states = {state1, ...};
  o.reverseStates = {};
  o.statesNames = {};
  o.statesHash = {};
  o.transitions = {};
  o.actions = {};
  for i = 1,#o.states do
    -- Reverse indexes of states
    o.reverseStates[o.states[i]] = i;

    o.statesNames[i] = o.states[i]._NAME;
    o.statesHash[o.statesNames[i]] = i;

    -- Transition and action tables
    o.transitions[o.states[i]] = {};
    o.actions[o.states[i]] = {};
  end
  o.events = {};
  o.initialState = o.states[1];
  o.currentState = o.initialState;
  o.previousState = nil;
  o.nextState = nil;
  o.nextAction = nil;

  setmetatable(o, mt);

  return o;
end

function set_transition(self, fromState, event, toState, action)
  assert(self.reverseStates[fromState], "Unknown from state");
  assert(type(event) == "string", "Unknown event");
  assert(self.reverseStates[toState], "Unknown to state");
  if (action) then
    assert(type(action) == "function", "Unknown action function");
  end

  if (not self.transitions[fromState]) then
    self.transitions[fromState] = {};
  end
  self.transitions[fromState][event] = toState;

  if (not self.actions[fromState]) then
    self.actions[fromState] = {};
  end
  self.actions[fromState][event] = action;
end

function add_state(self, newState)
  local n = #self.states;
  self.states[n+1] = newState;
  self.reverseStates[newState] = n+1;
  self.statesNames[n+1] = newState._NAME;
  self.statesHash[self.statesNames[n+1]] = n+1;
  self.transitions[newState] = {};
  self.actions[newState] = {};
end
function add_event(self, event)
  self.events[#self.events+1] = event;
end
function set_state(self, nextState)
  if self.statesHash[nextState] == nil then
    error('unkown state '..nextState);
  end
  self.nextState = self.states[self.statesHash[nextState]];
end

function get_current_state(self)
  return self.currentState;
end
function get_previous_state(self)
  return self.previousState;
end

function entry(self)
  local state = self.currentState;
  return state.entry();
end

function update(self)
  local ret;
  local state = self.currentState;

  -- if no nextState update current state:
  if (not self.nextState) then
    local ret = state.update();
    -- add ret from state to events:
    if (ret) then
      self.events[#self.events+1] = ret;
    end

    -- process events
    for i = 1,#self.events do
      local event = self.events[i];
      if (self.transitions[state][event]) then
        self.nextState = self.transitions[state][event];
        self.nextAction = self.actions[state][event];
        break;
      end
    end
    self.events = {};
  end

  -- check and enter next state
  if (self.nextState) then
    state.exit();
    if (self.nextAction) then
      ret = self.nextAction();
      self.nextAction = nil;
    end

    self.previousState = self.currentState;
    self.currentState = self.nextState;
    self.nextState = nil;
    self.currentState.entry();
    if (self.state_debug_handle) then
      self.state_debug_handle(self.currentState._NAME);
    end
  end

  self.nextState = nil;
  self.nextAction = nil;

  return ret;
end

function set_state_debug_handle(self, h)
  self.state_debug_handle = h;
end

function exit(self)
  local state = self.currentState;
  state.exit();
  self.currentState = self.initialState;
end
